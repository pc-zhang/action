/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `UICollectionViewCell` used to represent data in the collection view.
*/

import UIKit
import Foundation
import AVFoundation
import MobileCoreServices
import Accelerate
import Photos

final class TCPlayViewCell: UITableViewCell, UITextFieldDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var playerView: PlayerView!
    
    var histograms = [(time: CMTime, histogram: [[vImagePixelCount]])]()
    
    let player = AVPlayer()
    var playUrl: String?
    var downloadProcess: CGFloat = 0 {
        didSet {
            if downloadProcess != 0 {
                self.downloadProgressLayer?.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
                self.downloadProgressLayer?.path = CGPath(rect: bounds, transform: nil)
                self.downloadProgressLayer?.borderWidth = 0
                self.downloadProgressLayer?.lineWidth = 10
                self.downloadProgressLayer?.strokeColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
                self.downloadProgressLayer?.strokeStart = 0
                self.downloadProgressLayer?.strokeEnd = downloadProcess
            } else {
                self.downloadProgressLayer?.path = nil
            }
        }
    }
    
    var seekTimer: Timer? = nil
    var recordTimer: Timer? = nil
    var visibleTimeRange: CGFloat = 15
    var scaledDurationToWidth: CGFloat {
        return backgroundTimelineView.frame.width / visibleTimeRange
    }
    
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: 600)
            //todo: more tolerance
            player.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var composition: AVMutableComposition? = nil
    var videoComposition: AVMutableVideoComposition? = nil
    
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    
    private var playerItem: AVPlayerItem? = nil
    
    // MARK: - IBOutlets
    
    
    @IBOutlet weak var backgroundTimelineView: UICollectionView! {
        didSet {
            backgroundTimelineView.contentOffset = CGPoint(x:-backgroundTimelineView.frame.width / 2, y:0)
            backgroundTimelineView.contentInset = UIEdgeInsets(top: 0, left: backgroundTimelineView.frame.width/2, bottom: 0, right: backgroundTimelineView.frame.width/2)
            backgroundTimelineView.panGestureRecognizer.addTarget(self, action: #selector(TCPlayViewCell.pan))
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        downloadProcess = 0
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
            self.player.seek(to: CMTime.zero)
            self.player.play()
        }
        
        if composition==nil {
            composition = AVMutableComposition()
            // Add two video tracks and two audio tracks.
            _ = composition!.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            _ = composition!.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            _ = composition!.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
    }
    
    
    var downloadProgressLayer: CAShapeLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.playerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TCPlayViewCell.tapPlayer(_:))))
        downloadProgressLayer = CAShapeLayer()
        downloadProgressLayer!.frame = layer.bounds
        downloadProgressLayer!.position = CGPoint(x:bounds.width/2, y:bounds.height/2)
        self.layer.addSublayer(downloadProgressLayer!)
        
        playerView.playerLayer.player = player
    }
    
    
    @IBOutlet weak var chorus: UIButton!
    
    @IBAction func clickChorus(_ button: UIButton) {
        
        chorus.isHidden = true
        
        TCUtil.report(xiaoshipin_videochorus, userName: nil, code: 0, msg: "合唱事件")
        
        TCUtil.downloadVideo(playUrl, process: { (process) in
            self.onloadVideoProcess(process: process)
        }) { (videoPath) in
            self.onloadVideoComplete(videoPath!)
        }
    }
    
    
    func onloadVideoProcess(process:CGFloat) {
        self.downloadProcess = sqrt(process)/2
    }
    
    func onloadVideoComplete(_ videoPath:String) {
        addClip(try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(videoPath))
    }
    
    
    // MARK: Properties

    
    func setLiveInfo(liveInfo: TCLiveInfo) {
        // play
        playUrl = liveInfo.playurl
        player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: playUrl!)!))
        playerView.player = player
        player.play()
    }

    static let reuseIdentifier = "TCPlayViewCell"

    /// The `UUID` for the data this cell is presenting.
    var representedId: UUID?

    // MARK: UICollectionViewCell
    
    func addClip(_ movieURL: URL) {
        let newAsset = AVURLAsset(url: movieURL, options: nil)
        
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: TCPlayViewCell.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in TCPlayViewCell.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                
                let videoAssetTrack = newAsset.tracks(withMediaType: .video).first!
                
                let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
                
                compositionVideoTrack.preferredTransform = videoAssetTrack.preferredTransform
                
                try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration), of: videoAssetTrack, at: CMTime.zero)
                
                if let audioAssetTrack = newAsset.tracks(withMediaType: .audio).first, let compositionAudioTrack = self.composition!.tracks(withMediaType: .audio).first {
                    try! compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration), of: audioAssetTrack, at: CMTime.zero)
                    
                }
                
                self.backgroundTimelineView.isHidden = false

                // update timeline
                let currentTime = self.player.currentTime()
                self.updatePlayer()
                self.currentTime = currentTime.seconds
                
                DispatchQueue.global(qos: .background).async {
                    var videoTrackOutput : AVAssetReaderTrackOutput?
                    var avAssetReader = try?AVAssetReader(asset: self.composition!)
                    
                    if let videoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first {
                        videoTrackOutput = AVAssetReaderTrackOutput.init(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
                        avAssetReader?.add(videoTrackOutput!)
                    }
                    
                    avAssetReader?.startReading()
                    
                    while avAssetReader?.status == .reading {
                        //视频
                        if let sampleBuffer = videoTrackOutput?.copyNextSampleBuffer() {
                            let sampleBufferTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            DispatchQueue.main.async {
                                self.downloadProcess = 0.5 + CGFloat(sampleBufferTime.seconds / self.composition!.duration.seconds)
                            }
                            
                            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                            {
                                
                                var buffer = vImage_Buffer()
                                buffer.data = CVPixelBufferGetBaseAddress(pixelBuffer)
                                buffer.rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
                                buffer.width = vImagePixelCount(CVPixelBufferGetWidth(pixelBuffer))
                                buffer.height = vImagePixelCount(CVPixelBufferGetHeight(pixelBuffer))
                                
                                let bitmapInfo = CGBitmapInfo(rawValue: CGImageByteOrderInfo.orderMask.rawValue | CGImageAlphaInfo.last.rawValue)
                                
                                var cgFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                                                    bitsPerPixel: 32,
                                                                    colorSpace: nil,
                                                                    bitmapInfo: bitmapInfo,
                                                                    version: 0,
                                                                    decode: nil,
                                                                    renderingIntent: .defaultIntent)
                                
                                
                                var error = vImageBuffer_InitWithCVPixelBuffer(&buffer, &cgFormat, pixelBuffer, nil, nil, vImage_Flags(kvImageNoFlags))
                                assert(kvImageNoError == error)
                                defer {
                                    free(buffer.data)
                                }
                                
                                let histogramBins = (0...3).map { _ in
                                    return [vImagePixelCount](repeating: 0, count: 256)
                                }
                                var mutableHistogram: [UnsafeMutablePointer<vImagePixelCount>?] = histogramBins.map {
                                    return UnsafeMutablePointer<vImagePixelCount>(mutating: $0)
                                }
                                error = vImageHistogramCalculation_ARGB8888(&buffer,
                                                                            &mutableHistogram,
                                                                            vImage_Flags(kvImageNoFlags))
                                assert(kvImageNoError == error)
                                
                                
                                if let last_split_time = self.histograms.last?.time, let last_histogramBins = self.histograms.last?.histogram {

                                    if self.costheta(histogramBins, last_histogramBins) < 0.9995, CMTimeSubtract(sampleBufferTime, last_split_time).seconds > 1 {
                                        
                                        self.histograms.append((time: sampleBufferTime, histogram: histogramBins))

                                        DispatchQueue.main.async {
                                            let firstVideoTrack = self.composition!.tracks(withMediaType: .video).first!
                                            
                                            if let segment = firstVideoTrack.segment(forTrackTime: sampleBufferTime), segment.timeMapping.target.containsTime(sampleBufferTime) {
                                                try! firstVideoTrack.insertTimeRange(segment.timeMapping.target, of: firstVideoTrack, at: segment.timeMapping.target.end)
                                                firstVideoTrack.removeTimeRange(CMTimeRange(start:sampleBufferTime, duration:segment.timeMapping.target.duration + CMTime(value: 1, timescale: 600)))
                                            }
                                            
                                            self.backgroundTimelineView.reloadData()
                                            
                                        }
                                        
                                    }
                                } else {
                                    self.histograms.append((time: sampleBufferTime, histogram: histogramBins))
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    func costheta(_ histogram1: [[vImagePixelCount]], _ histogram2: [[vImagePixelCount]]) -> Double {
        let rgba1 = histogram1[0] + histogram1[1] + histogram1[2] + histogram1[3]
        let rgba2 = histogram2[0] + histogram2[1] + histogram2[2] + histogram2[3]
        let AB = zip(rgba1, rgba2).map(*).reduce(0, { (result, item) -> UInt in
            result + item
        })
        let AA = zip(rgba1, rgba1).map(*).reduce(0, { (result, item) -> UInt in
            result + item
        })
        let BB = zip(rgba2, rgba2).map(*).reduce(0, { (result, item) -> UInt in
            result + item
        })
        return Double(AB) / sqrt(Double(AA)) / sqrt(Double(BB))
    }
    
    
    func updatePlayer() {
        if self.composition == nil {
            return
        }
        
        let firstVideoTrack = self.composition!.tracks(withMediaType: .video)[0]
        let secondVideoTrack = self.composition!.tracks(withMediaType: .video)[1]
        
        self.videoComposition = AVMutableVideoComposition()
        self.videoComposition!.renderSize = firstVideoTrack.naturalSize
        self.videoComposition!.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        for segment in firstVideoTrack.segments {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = segment.timeMapping.target
            
            if let segment2 = secondVideoTrack.segment(forTrackTime: segment.timeMapping.target.start),!segment2.isEmpty, segment2.timeMapping.target ==  segment.timeMapping.target {
                let transformer2 = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
                transformer2.setTransform(secondVideoTrack.getTransform(renderSize: self.videoComposition!.renderSize), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer2]
            } else {
                let transformer1 = AVMutableVideoCompositionLayerInstruction(assetTrack: firstVideoTrack)
                transformer1.setTransform(firstVideoTrack.getTransform(renderSize: self.videoComposition!.renderSize), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer1]
            }
            
            if let lastInstruction = self.videoComposition!.instructions.last {
                assert(lastInstruction.timeRange.end == instruction.timeRange.start)
            }
            self.videoComposition!.instructions.append(instruction)
        }
        
        if let lastInstruction = self.videoComposition!.instructions.last {
            assert(lastInstruction.timeRange.end == firstVideoTrack.timeRange.end)
        }
        
        if let audioTrack = self.composition!.tracks(withMediaType: .audio).first {
            audioTrack.removeTimeRange(CMTimeRange(start: firstVideoTrack.timeRange.end, end: audioTrack.timeRange.end))
        }
        
        let playerItem = AVPlayerItem(asset: self.composition!)
        playerItem.videoComposition = self.videoComposition
        
        self.player.replaceCurrentItem(with: playerItem)
        
        self.backgroundTimelineView.reloadData()
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if player.rate == 0 {
            let _timelineView = scrollView as! UICollectionView
            currentTime = Double((_timelineView.contentOffset.x + _timelineView.frame.width/2) / (_timelineView.frame.width / visibleTimeRange))
        }
    }
    
    
    @IBAction func pan(_ recognizer: UIPanGestureRecognizer) {
        player.pause()
        seekTimer?.invalidate()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
        
        return CGSize(width: CGFloat(CMTimeGetSeconds((compositionVideoTrack.segments[indexPath.row].timeMapping.target.duration))) * scaledDurationToWidth, height: backgroundTimelineView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
        
        assert(self.composition!.tracks(withMediaType: AVMediaType.video).count == 2)
        
        return compositionVideoTrack.segments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let segmentView = collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)
        segmentView.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0)
        for view in segmentView.subviews {
            view.removeFromSuperview()
        }
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
        
        let imageGenerator = AVAssetImageGenerator.init(asset: composition!)
        imageGenerator.maximumSize = CGSize(width: self.backgroundTimelineView.bounds.height * 2, height: self.backgroundTimelineView.bounds.height * 2)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.videoComposition = videoComposition
        
        if true {
            var times = [NSValue]()
            
            let timerange = (compositionVideoTrack.segments[indexPath.item].timeMapping.target)
            
            // Generate an image at time zero.
            let incrementTime = CMTime(seconds: Double(backgroundTimelineView.frame.height /  scaledDurationToWidth), preferredTimescale: 600)
            
            var iterTime = timerange.start
            
            while iterTime <= timerange.end {
                times.append(iterTime as NSValue)
                iterTime = CMTimeAdd(iterTime, incrementTime);
            }
            
            // Set a videoComposition on the ImageGenerator if the underlying movie has more than 1 video track.
            imageGenerator.generateCGImagesAsynchronously(forTimes: times as [NSValue]) { (requestedTime, image, actualTime, result, error) in
                if (image != nil) {
                    DispatchQueue.main.async {
                        let nextX = CGFloat(CMTimeGetSeconds(requestedTime - timerange.start)) * self.scaledDurationToWidth
                        let nextView = UIImageView.init(frame: CGRect(x: nextX, y: 0.0, width: self.backgroundTimelineView.bounds.height, height: self.backgroundTimelineView.bounds.height))
                        nextView.contentMode = .scaleAspectFill
                        nextView.clipsToBounds = true
                        nextView.image = UIImage.init(cgImage: image!)
                        segmentView.addSubview(nextView)
                        
                        if nextX == 0 {
                            let whiteline = UIView(frame: CGRect(x:0,y:0,width:1,height:segmentView.bounds.height))
                            whiteline.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                            segmentView.addSubview(whiteline)
                        }
                    }
                }
            }
        }
        
        return segmentView
    }
    
    var isRecording = false
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
        let segment = compositionVideoTrack.segments[indexPath.item]
        self.backgroundTimelineView.contentOffset.x = CGFloat(segment.timeMapping.target.start.seconds/Double(self.visibleTimeRange)*Double(self.backgroundTimelineView.frame.width)) - self.backgroundTimelineView.frame.size.width/2
        
        DispatchQueue.main.async {
            self.recordTimeRange = segment.timeMapping.target
            self.isRecording = true
            self.setNeedsLayout()
        }
    }

    var recordTimeRange = CMTimeRange.zero
    
    @IBAction func tapPlayer(_ sender: Any) {
        if player.rate == 0 {
            // Not playing forward, so play.
            if currentTime == duration {
                // At end, so got back to begining.
                currentTime = 0.0
            }
            
            player.play()
            
            //todo: animate
            if #available(iOS 10.0, *) {
                seekTimer?.invalidate()
                seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                    self.backgroundTimelineView.contentOffset.x = CGFloat(self.currentTime/Double(self.visibleTimeRange)*Double(self.backgroundTimelineView.frame.width)) - self.backgroundTimelineView.frame.size.width/2
                })
            } else {
                // Fallback on earlier versions
            }
        }
        else {
            // Playing, so pause.
            player.pause()
            seekTimer?.invalidate()
        }
    }
    
    
    @IBOutlet private weak var recordButton: UIButton!
    
//    @IBAction private func toggleMovieRecording(_ recordButton: UIButton) {
//
//        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
//
//        sessionQueue.async {
//            if !movieFileOutput.isRecording {
//                if UIDevice.current.isMultitaskingSupported {
//                    /*
//                     Setup background task.
//                     This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
//                     callback is not received until AVCam returns to the foreground unless you request background execution time.
//                     This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
//                     To conclude this background execution, endBackgroundTask(_:) is called in
//                     `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
//                     */
//                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
//                }
//
//                // Update the orientation on the movie file output video connection before starting recording.
//                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
//                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
//
//                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
//
//                if availableVideoCodecTypes.contains(.hevc) {
//                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
//                }
//
//                // Start recording to a temporary file.
//                let outputFileName = NSUUID().uuidString
//                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
//                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
//                DispatchQueue.main.async {
//                    self.tapPlayer(0)
//                    Timer.scheduledTimer(withTimeInterval: self.recordTimeRange.duration.seconds+0.5, repeats: false, block: { (timer) in
//                        movieFileOutput.stopRecording()
//                        self.tapPlayer(0)
//                    })
//                }
//            } else {
//                movieFileOutput.stopRecording()
//            }
//        }
//    }
    
    override func layoutSubviews() {
        if isRecording == true {
            playerView.frame = CGRect(x: 0, y: 0, width: bounds.width/3, height: bounds.height/3)
        } else {
            playerView.frame = bounds
        }
    }
    

//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        /*
//         Note that currentBackgroundRecordingID is used to end the background task
//         associated with this recording. This allows a new recording to be started,
//         associated with a new UIBackgroundTaskIdentifier, once the movie file output's
//         `isRecording` property is back to false — which happens sometime after this method
//         returns.
//
//         Note: Since we use a unique file path for each recording, a new recording will
//         not overwrite a recording currently being saved.
//         */
//
//        var success = true
//
//        if error != nil {
//            print("Movie file finishing error: \(String(describing: error))")
//            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
//        }
//
//        if success {
//            let path = outputFileURL.path
//            if FileManager.default.fileExists(atPath: path) {
//                let newAsset = AVURLAsset(url: outputFileURL, options: nil)
//
//                /*
//                 Using AVAsset now runs the risk of blocking the current thread (the
//                 main UI thread) whilst I/O happens to populate the properties. It's
//                 prudent to defer our work until the properties we need have been loaded.
//                 */
//                newAsset.loadValuesAsynchronously(forKeys: TCPlayViewCell.assetKeysRequiredToPlay) {
//                    /*
//                     The asset invokes its completion handler on an arbitrary queue.
//                     To avoid multiple threads using our internal state at the same time
//                     we'll elect to use the main thread at all times, let's dispatch
//                     our handler to the main queue.
//                     */
//                    DispatchQueue.main.async {
//
//                        /*
//                         Test whether the values of each of the keys we need have been
//                         successfully loaded.
//                         */
//                        for key in TCPlayViewCell.assetKeysRequiredToPlay {
//                            var error: NSError?
//
//                            if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
//                                let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
//
//                                let message = String.localizedStringWithFormat(stringFormat, key)
//
//
//                                return
//                            }
//                        }
//
//                        // We can't play this asset.
//                        if !newAsset.isPlayable || newAsset.hasProtectedContent {
//                            let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
//
//
//                            return
//                        }
//
//                        /*
//                         We can play this asset. Create a new `AVPlayerItem` and make
//                         it our player's current item.
//                         */
//
//                        let videoAssetTrack = newAsset.tracks(withMediaType: .video).first!
//
//                        let secondVideoTrack = self.composition!.tracks(withMediaType: .video)[1]
//
//                        secondVideoTrack.preferredTransform = videoAssetTrack.preferredTransform
//
//                        if let recordedSegment = secondVideoTrack.segment(forTrackTime: self.recordTimeRange.start), recordedSegment.timeMapping.target == self.recordTimeRange {
//                            secondVideoTrack.removeTimeRange(self.recordTimeRange)
//                        }
//
//                        try! secondVideoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.recordTimeRange.duration), of: videoAssetTrack, at: self.recordTimeRange.start)
//
//                        self.updatePlayer()
//                    }
//                }
//            }
//
//            if let currentBackgroundRecordingID = backgroundRecordingID {
//                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
//
//                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
//                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
//                }
//            }
//        }
//
//    }

}


extension AVAssetTrack {
    func getTransform(cropRect: CGRect) -> CGAffineTransform {
        let renderSize = cropRect.size
        let renderScale = renderSize.width / cropRect.width
        let offset = CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y)
        let rotation = atan2(self.preferredTransform.b, self.preferredTransform.a)
        
        var rotationOffset = CGPoint(x: 0, y: 0)
        
        if self.preferredTransform.b == -1.0 {
            rotationOffset.y = self.naturalSize.width
        } else if self.preferredTransform.c == -1.0 {
            rotationOffset.x = self.naturalSize.height
        } else if self.preferredTransform.a == -1.0 {
            rotationOffset.x = self.naturalSize.width
            rotationOffset.y = self.naturalSize.height
        }
        
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: renderScale, y: renderScale)
        transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
        transform = transform.rotated(by: rotation)
        return transform
    }
    
    func getTransform(renderSize: CGSize) -> CGAffineTransform {
        let offset = CGPoint.zero
        let rotation = atan2(self.preferredTransform.b, self.preferredTransform.a)
        var rotationOffset = CGPoint.zero
        var renderScale: CGFloat = 1

        if self.preferredTransform.b == -1.0 {
            rotationOffset.y = self.naturalSize.width
            renderScale = renderSize.width / self.naturalSize.height
        } else if self.preferredTransform.c == -1.0 {
            rotationOffset.x = self.naturalSize.height
            renderScale = renderSize.width / self.naturalSize.height
        } else if self.preferredTransform.a == -1.0 {
            rotationOffset.x = self.naturalSize.width
            rotationOffset.y = self.naturalSize.height
            renderScale = renderSize.width / self.naturalSize.width
        } else {
            renderScale = renderSize.width / self.naturalSize.width
        }
        
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: renderScale, y: renderScale)
        transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
        transform = transform.rotated(by: rotation)
        return transform
    }
}
