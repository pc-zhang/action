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

final class TCPlayViewCell: UITableViewCell, UITextFieldDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AVCaptureFileOutputRecordingDelegate {
    
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
    
    deinit {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
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
        
        previewView.session = session
        playerView.playerLayer.player = player
        
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Why not do all of this on the main queue?
         Because AVCaptureSession.startRunning() is a blocking call which can
         take a long time. We dispatch session setup to the sessionQueue so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    
//                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
//                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        sessionQueue.async {
            let movieFileOutput = AVCaptureMovieFileOutput()
            
            if self.session.canAddOutput(movieFileOutput) {
                self.session.beginConfiguration()
                self.session.addOutput(movieFileOutput)
                self.session.sessionPreset = .high
                if let connection = movieFileOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                self.session.commitConfiguration()
                
                self.movieFileOutput = movieFileOutput
                
                DispatchQueue.main.async {
                    self.recordButton.isEnabled = true
                }
            }
        }
        
        DispatchQueue.main.async {
            self.changeCamera(UIButton())
        }
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
                                        if let last_split_time = self.last_split_time, CMTimeSubtract(sampleBufferTime, self.last_split_time!).seconds > 1 {
                                            DispatchQueue.main.async {
                                                let firstVideoTrack = self.composition!.tracks(withMediaType: .video).first!
                                                
                                                if let segment = firstVideoTrack.segment(forTrackTime: sampleBufferTime), segment.timeMapping.target.containsTime(sampleBufferTime) {
                                                    try! firstVideoTrack.insertTimeRange(segment.timeMapping.target, of: firstVideoTrack, at: segment.timeMapping.target.end)
                                                    firstVideoTrack.removeTimeRange(CMTimeRange(start:sampleBufferTime, duration:segment.timeMapping.target.duration + CMTime(value: 1, timescale: 600)))
                                                }
                                                
                                                
                                                self.backgroundTimelineView.reloadData()
                                                
                                            }
                                        }
                                        self.last_split_time = sampleBufferTime
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
    
//    override var shouldAutorotate: Bool {
//        // Disable autorotation of the interface when recording is in progress.
//        if let movieFileOutput = movieFileOutput {
//            return !movieFileOutput.isRecording
//        }
//        return true
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .all
//    }
//
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
//            let deviceOrientation = UIDevice.current.orientation
//            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
//                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
//                    return
//            }
//
//            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
//        }
//    }
    
    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    private var setupResult: SessionSetupResult = .success
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    // Call this on the session queue.
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSession.Preset.Photo.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add audio input.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    @IBAction private func resumeInterruptedSession(_ resumeButton: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running, e.g., if a phone or FaceTime call is still
             using audio or video. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
//                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                
            }
        }
    }
    
    
    // MARK: Device Configuration
    
    @IBOutlet private weak var cameraButton: UIButton!
    
    @IBOutlet private weak var cameraUnavailableLabel: UILabel!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                               mediaType: .video, position: .unspecified)
    
    @IBAction private func changeCamera(_ cameraButton: UIButton) {
        cameraButton.isEnabled = false
        recordButton.isEnabled = false
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    if let connection = self.movieFileOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    /*
                     Set Live Photo capture and depth data delivery if it is supported. When changing cameras, the
                     `livePhotoCaptureEnabled and depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput gets set to NO when
                     a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput if it is supported.
                     */
                    
                    self.session.commitConfiguration()
                } catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.cameraButton.isEnabled = true
                self.recordButton.isEnabled = self.movieFileOutput != nil
            }
        }
    }
    
    @IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    
    // MARK: Recording Movies
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    @IBOutlet private weak var recordButton: UIButton!
    
    @IBAction private func toggleMovieRecording(_ recordButton: UIButton) {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        
        /*
         Disable the Camera button until recording finishes, and disable
         the Record button until recording starts or finishes.
         
         See the AVCaptureFileOutputRecordingDelegate methods.
         */
//        cameraButton.isEnabled = false
//        recordButton.isEnabled = false
        
        /*
         Retrieve the video preview layer's video orientation on the main queue
         before entering the session queue. We do this to ensure UI elements are
         accessed on the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    /*
                     Setup background task.
                     This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                     callback is not received until AVCam returns to the foreground unless you request background execution time.
                     This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                     To conclude this background execution, endBackgroundTask(_:) is called in
                     `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
                     */
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                // Start recording to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
                DispatchQueue.main.async {
                    self.tapPlayer(0)
                    Timer.scheduledTimer(withTimeInterval: self.recordTimeRange.duration.seconds+0.5, repeats: false, block: { (timer) in
                        movieFileOutput.stopRecording()
                        self.tapPlayer(0)
                    })
                }
            } else {
                movieFileOutput.stopRecording()
            }
        }
    }
    
    override func layoutSubviews() {
        if isRecording == true {
            playerView.frame = CGRect(x: 0, y: 0, width: bounds.width/3, height: bounds.height/3)
        } else {
            playerView.frame = bounds
        }
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop the recording.
        DispatchQueue.main.async {
//            self.recordButton.isEnabled = true
//            self.recordButton.setTitle(NSLocalizedString("Stop", comment: "Recording button stop title"), for: [])
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        /*
         Note that currentBackgroundRecordingID is used to end the background task
         associated with this recording. This allows a new recording to be started,
         associated with a new UIBackgroundTaskIdentifier, once the movie file output's
         `isRecording` property is back to false — which happens sometime after this method
         returns.
         
         Note: Since we use a unique file path for each recording, a new recording will
         not overwrite a recording currently being saved.
         */
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                let newAsset = AVURLAsset(url: outputFileURL, options: nil)
                
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
                        
                        let secondVideoTrack = self.composition!.tracks(withMediaType: .video)[1]
                        
                        secondVideoTrack.preferredTransform = videoAssetTrack.preferredTransform
                        
                        try! secondVideoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.recordTimeRange.duration), of: videoAssetTrack, at: self.recordTimeRange.start)
                                
                        self.updatePlayer()
                    }
                }
            }
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
    }
    
    // MARK: KVO and Notifications
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
                self.recordButton.isEnabled = isSessionRunning && self.movieFileOutput != nil
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    
                }
            }
        }
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            var showResumeButton = false
            
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.alpha = 0
                cameraUnavailableLabel.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1
                }
            }
            
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
    }

}



extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions: [AVCaptureDevice.Position] = []
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
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
