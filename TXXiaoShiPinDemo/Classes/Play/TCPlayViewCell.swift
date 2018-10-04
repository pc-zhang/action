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


final class TCPlayViewCell: UITableViewCell, UITextFieldDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var playerView: PlayerView!
    
    let player = AVPlayer()
    var playUrl: String?
    var last_rgb: [UInt]? = nil
    var last_split_time: CMTime? = nil
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
    var audioMix: AVMutableAudioMix? = nil
    
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
                
                
                if let audioAssetTrack = newAsset.tracks(withMediaType: .audio).first {
                    
                    let compositionAudioTrack = self.composition!.tracks(withMediaType: .audio).first!
                    
                    compositionAudioTrack.removeTimeRange(compositionAudioTrack.timeRange)
                    try! compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration), of: audioAssetTrack, at: CMTime.zero)
                    
                }
                
                
                // update timeline
                self.updatePlayer()
                self.backgroundTimelineView.reloadData()
                
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
                            DispatchQueue.main.async {
                                self.downloadProcess = 0.5 + CGFloat(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds / self.composition!.duration.seconds)
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
                                
                                
                                let error = vImageBuffer_InitWithCVPixelBuffer(&buffer, &cgFormat, pixelBuffer, nil, nil, vImage_Flags(kvImageNoFlags))
                                assert(kvImageNoError == error)
                                
                                let alpha = [UInt](repeating: 0, count: 256)
                                let red = [UInt](repeating: 0, count: 256)
                                let green = [UInt](repeating: 0, count: 256)
                                let blue = [UInt](repeating: 0, count: 256)
                                
                                let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha) as UnsafeMutablePointer<vImagePixelCount>?
                                let redPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: red) as UnsafeMutablePointer<vImagePixelCount>?
                                let greenPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: green) as UnsafeMutablePointer<vImagePixelCount>?
                                let bluePtr = UnsafeMutablePointer<vImagePixelCount>(mutating: blue) as UnsafeMutablePointer<vImagePixelCount>?
                                
                                let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]
                                
                                
                                let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: rgba)
                                let err2 = vImageHistogramCalculation_ARGB8888(&buffer, histogram, UInt32(kvImageNoFlags))
                                assert(kvImageNoError == err2)
                                free(buffer.data)
                                
                                
                                let rgb = red + green + blue
                                if let last_rgb = self.last_rgb {
                                    let AB = zip(rgb, last_rgb).map(*).reduce(0, { (result, item) -> UInt in
                                        result + item
                                    })
                                    let AA = zip(rgb, rgb).map(*).reduce(0, { (result, item) -> UInt in
                                        result + item
                                    })
                                    let BB = zip(last_rgb, last_rgb).map(*).reduce(0, { (result, item) -> UInt in
                                        result + item
                                    })
                                    let cos = Double(AB) / sqrt(Double(AA)) / sqrt(Double(BB))
                                    if cos < 0.999 {
                                        if let last_split_time = self.last_split_time, CMTimeSubtract(CMSampleBufferGetPresentationTimeStamp(sampleBuffer), self.last_split_time!).seconds > 1 {
                                            DispatchQueue.main.async {
                                                var timeRangeInAsset: CMTimeRange? = nil
                                                
                                                let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
                                                
                                                for s in compositionVideoTrack.segments {
                                                    timeRangeInAsset = s.timeMapping.target // assumes non-scaled edit
                                                    
                                                    if !s.isEmpty && timeRangeInAsset!.containsTime(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) {
                                                        
                                                        try! compositionVideoTrack.insertTimeRange(timeRangeInAsset!, of: compositionVideoTrack, at: timeRangeInAsset!.end)
                                                        
                                                        try! compositionVideoTrack.removeTimeRange(CMTimeRange(start:CMSampleBufferGetPresentationTimeStamp(sampleBuffer), duration:timeRangeInAsset!.duration - CMTime(value: 1, timescale: 600)))
                                                        
                                                        self.backgroundTimelineView.reloadData()
                                                        
                                                        break
                                                    }
                                                }
                                                
                                            }
                                        }
                                        self.last_split_time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                                    }
                                }
                                self.last_rgb = rgb
                                
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    func updatePlayer() {
        if composition == nil {
            return
        }
        
        videoComposition = AVMutableVideoComposition()
        videoComposition!.renderSize = CGSize(width: 540, height: 960)
        videoComposition!.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let firstVideoTrack = composition!.tracks(withMediaType: .video).first!
        
        let secondVideoTrack = composition!.tracks(withMediaType: .video)[1]
        
        for segment in firstVideoTrack.segments {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = segment.timeMapping.target
            
            if segment.isEmpty {
                let transformer2 = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
                transformer2.setTransform(CGAffineTransform.identity.scaledBy(x: videoComposition!.renderSize.width/secondVideoTrack.naturalSize.width, y: videoComposition!.renderSize.height/secondVideoTrack.naturalSize.height), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer2]
            } else {
                let transformer1 = AVMutableVideoCompositionLayerInstruction(assetTrack: firstVideoTrack)
                transformer1.setTransform(CGAffineTransform.identity.scaledBy(x: videoComposition!.renderSize.width/firstVideoTrack.naturalSize.width, y: videoComposition!.renderSize.height/firstVideoTrack.naturalSize.height), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer1]
            }
            
            videoComposition!.instructions.append(instruction)
        }
        
        if secondVideoTrack.timeRange.end > firstVideoTrack.timeRange.end {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: firstVideoTrack.timeRange.end, duration: secondVideoTrack.timeRange.end)
            
            let transformer2 = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
            transformer2.setTransform(CGAffineTransform.identity.scaledBy(x: videoComposition!.renderSize.width/secondVideoTrack.naturalSize.width, y: videoComposition!.renderSize.height/secondVideoTrack.naturalSize.height), at: instruction.timeRange.start)
            
            instruction.layerInstructions = [transformer2]
            
            videoComposition!.instructions.append(instruction)
        }
        
        
        playerItem = AVPlayerItem(asset: composition!)
        playerItem!.videoComposition = videoComposition
        playerItem!.audioMix = audioMix
        player.replaceCurrentItem(with: playerItem)
        
        currentTime = Double((backgroundTimelineView.contentOffset.x + backgroundTimelineView.frame.width/2) / scaledDurationToWidth)
        
        
        if firstVideoTrack.segments.count != 0 {
            backgroundTimelineView.isHidden = false
        } else {
            backgroundTimelineView.isHidden = true
        }
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaType.video).first!
        let segment = compositionVideoTrack.segments[indexPath.item]
        playerView.frame = CGRect(x: 0, y: 0, width: bounds.width/3, height: bounds.height/3)
    }

    
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

}
