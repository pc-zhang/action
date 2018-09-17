//
//  DocumentViewController.swift
//  OneCut
//
//  Created by zpc on 2018/7/3.
//  Copyright © 2018年 Apple Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MobileCoreServices
//import NVActivityIndicatorView

private var MainViewControllerKVOContext = 0

class TCVideoEditViewController2: TCVideoEditViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    BottomTabBarDelegate
//    ,NVActivityIndicatorViewable
{
    var bottomBar: BottomTabBar?         //底部栏

    // MARK: BottomTabBarDelegate
   
    func onMusicBtnClicked() {
//        bottomBar.hidden = YES;
//        [self onSelectMusic];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        [self resetConfirmBtn];
    }
    
    func onTimeBtnClicked() {
//        bottomBar.hidden = YES;
//        _deleteBtn.hidden = YES;
//        [self resetConfirmBtn];
//        [self resetVideoProgress];
//        [self onShowEffectView];
//        [self removeAllTextFieldFromSuperView];
//        [self removeAllPasterViewFromSuperView];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        _effectSelectType = EffectSelectType_Time;
//        [_videoCutView setColorType:ColorType_Time];
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            NSMutableArray <EffectInfo *> *effectArray = [NSMutableArray array];
//            [effectArray addObject:({
//                EffectInfo * v= [EffectInfo new];
//                v.name = @"无";
//                v.animateIcons = [NSMutableArray array];
//                for (int i = 0; i < 20; i ++) {
//                [v.animateIcons addObject:[UIImage imageNamed:[NSString stringWithFormat:@"jump_%d",i]]];
//                }
//                v;
//                })];
//            [effectArray addObject:({
//                EffectInfo * v= [EffectInfo new];
//                v.name = @"时光倒流";
//                v.animateIcons = [NSMutableArray array];
//                v.selectIcon = [UIImage imageNamed:@"timeBack_select"];
//                for (int i = 19; i >= 0; i --) {
//                [v.animateIcons addObject:[UIImage imageNamed:[NSString stringWithFormat:@"jump_%d",i]]];
//                }
//                v;
//                })];
//            [effectArray addObject:({
//                EffectInfo * v= [EffectInfo new];
//                v.name = @"反复";
//                v.animateIcons = [NSMutableArray array];
//                v.selectIcon = [UIImage imageNamed:@"repeat_select"];
//                NSMutableArray *repeatIcons = [NSMutableArray array];
//                for (int i = 0; i < 20; i ++) {
//                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"jump_%d",i]];
//                if (i >= 5 && i <= 15) {
//                [repeatIcons addObject:image];
//                }
//                if (i == 15) {
//                [v.animateIcons addObjectsFromArray:repeatIcons];
//                [v.animateIcons addObjectsFromArray:repeatIcons];
//                }
//                [v.animateIcons addObject:image];
//                }
//                v;
//                })];
//            [effectArray addObject:({
//                EffectInfo * v= [EffectInfo new];
//                v.name = @"慢动作";
//                v.animateIcons = [NSMutableArray array];
//                v.selectIcon = [UIImage imageNamed:@"slow_select"];
//                v.isSlow = YES;
//                for (int i = 0; i < 20; i ++) {
//                [v.animateIcons addObject:[UIImage imageNamed:[NSString stringWithFormat:@"jump_%d",i]]];
//                }
//                v;
//                })];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_effectSelectView setEffectList:effectArray];
//                });
//            });
    }
    
    func onFilterBtnClicked() {
//        bottomBar.hidden = YES;
//        _deleteBtn.hidden = YES;
//        [self resetConfirmBtn];
//        [self resetVideoProgress];
//        [self onShowEffectView];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        NSMutableArray <EffectInfo *> *effectArray = [NSMutableArray array];
//        [effectArray addObject:({
//            EffectInfo * v= [EffectInfo new];
//            v.name = @"原图";
//            v.icon = [UIImage imageNamed:@"orginal"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"美白";
//            v.icon = [UIImage imageNamed:@"fwhite"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"浪漫";
//            v.icon = [UIImage imageNamed:@"langman"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"清新";
//            v.icon = [UIImage imageNamed:@"qingxin"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"唯美";
//            v.icon = [UIImage imageNamed:@"weimei"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"粉嫩";
//            v.icon = [UIImage imageNamed:@"fennen"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"怀旧";
//            v.icon = [UIImage imageNamed:@"huaijiu"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"蓝调";
//            v.icon = [UIImage imageNamed:@"landiao"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"清凉";
//            v.icon = [UIImage imageNamed:@"qingliang"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [effectArray addObject:({
//            EffectInfo *v = [EffectInfo new];
//            v.name = @"日系";
//            v.icon = [UIImage imageNamed:@"rixi"];
//            v.selectIcon = [UIImage imageNamed:@"orginal_select"];
//            v;
//            })];
//        [_effectSelectView setEffectList:effectArray];
//        _effectSelectType = EffectSelectType_Filter;
//        [_videoCutView setColorType:ColorType_Filter];
//        [_videoCutView setCenterPanHidden:YES];
//        [self removeAllTextFieldFromSuperView];
//        [self removeAllPasterViewFromSuperView];
    }
    
    func onEffectBtnClicked() {
//        bottomBar.hidden = YES;
//        _deleteBtn.hidden = NO;
//        [self resetConfirmBtn];
//        [self resetVideoProgress];
//        [self onShowEffectView];
//        [self removeAllTextFieldFromSuperView];
//        [self removeAllPasterViewFromSuperView];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        _effectSelectType = EffectSelectType_Effect;
//        [_videoCutView setColorType:ColorType_Effect];
//        [_videoCutView setCenterPanHidden:YES];
//        __block NSArray <EffectInfo *> *effectArray = nil;
//        dispatch_barrier_sync(_imageLoadingQueue, ^{
//            effectArray = _effectList;
//            });
//        [_effectSelectView setEffectList:effectArray momentary:YES];
    }
    
    func onTextBtnClicked() {
//        bottomBar.hidden = YES;
//        _deleteBtn.hidden = NO;
//        [self resetConfirmBtn];
//        [self resetVideoProgress];
//        [self onShowEffectView];
//        [self removeAllPasterViewFromSuperView];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        [_effectSelectView setEffectList:_textEffectArray];
//        [_videoCutView setColorType:ColorType_Text];
//        [_videoCutView setCenterPanHidden:YES];
//        _effectSelectType = EffectSelectType_Text;
    }
    
    func onPasterBtnClicked() {
//        bottomBar.hidden = YES;
//        _deleteBtn.hidden = NO;
//        [self resetConfirmBtn];
//        [self resetVideoProgress];
//        [self onShowEffectView];
//        [self removeAllTextFieldFromSuperView];
//        [self setLeftPanFrame:0 rightPanFrame:0];
//        [_effectSelectView setEffectList:_pasterEffectArray];
//        [_videoCutView setColorType:ColorType_Paster];
//        [_videoCutView setCenterPanHidden:YES];
//        _effectSelectType = EffectSelectType_Paster;
    }
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Properties
    
    fileprivate let labelFont = UIFont(name: "Menlo", size: 12)!
    fileprivate let maxImageSize = CGSize(width: 120, height: 120)
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelineV.addSubview(videoCutView)
        timelineV.addSubview(flagView)
        timelineV.addSubview(deleteBtn)
        videoPreview.frame = playerView.bounds
        playerView.addSubview(videoPreview)
        playerView.addSubview(timeLabel)
        playerView.addSubview(playBtn)
        
        let kScaleX = UIScreen.main.bounds.size.width / 375
        let kScaleY = UIScreen.main.bounds.size.height / 667
        let offset: CGFloat = 0
        bottomBar = BottomTabBar(frame:CGRect(x:0, y:self.view.height - 62 * kScaleY - offset, width:self.view.width, height:40 * kScaleY))
        bottomBar?.delegate = self;
        self.view.addSubview(bottomBar!)
        
        backgroundTimelineView.isHidden = true
        timelineView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // add composition
        if composition==nil {
            composition = AVMutableComposition()
            // Add two video tracks and two audio tracks.
            _ = composition!.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            _ = composition!.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            _ = composition!.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        self.push(op:.nothing)
        
        playerView.playerLayer.player = player
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                //                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
        
        /*
         Update the UI when these player properties change.
         
         Use the context parameter to distinguish KVO for our particular observers
         and not those destined for a subclass that also happens to be observing
         these properties.
         */
        addObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.currentItem.duration), options: [.new, .initial], context: &MainViewControllerKVOContext)
        addObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.rate), options: [.new, .initial], context: &MainViewControllerKVOContext)
        addObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.currentItem.status), options: [.new, .initial], context: &MainViewControllerKVOContext)
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(20, 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        player.pause()
        
        removeObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.currentItem.duration), context: &MainViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.rate), context: &MainViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(TCVideoEditViewController2.player.currentItem.status), context: &MainViewControllerKVOContext)
    }

    
    var newStatus: AVPlayerItemStatus? = nil
    var newDuration: CMTime? = nil
    
    var emptyView = UIView(frame: CGRect.zero)
    var seekTimer: Timer? = nil
    var visibleTimeRange: CGFloat = 15
    var scaledDurationToWidth: CGFloat {
        return timelineView.frame.width / visibleTimeRange
    }

    struct opsAndComps {
        var comp: AVMutableComposition
        var op: OpType
    }
    var stack: [opsAndComps] = []
    var undoPos: Int = -1 {
        didSet {
            let undoButtonImageName = undoPos <= 0 ? "undo_ban" : "undo"
            
            let undoButtonImage = UIImage(named: undoButtonImageName)
            
            undoButton.setImage(undoButtonImage, for: UIControlState())
            
            let redoButtonImageName = undoPos == stack.count - 1 ? "redo_ban" : "redo"
            
            let redoButtonImage = UIImage(named: redoButtonImageName)
            
            redoButton.setImage(redoButtonImage, for: UIControlState())
        }
    }
    
    enum OpType {
        case add(Int, Int)
        case remove(Int, Int)
        case update(Int, Int)
        case split(Int, Int)
        case copy(Int, Int)
        case nothing
    }
    
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    
    @objc let player = AVPlayer()
    
    var zoomCurrentTime: Double = 0
    
    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, 600)
            //todo: more tolerance
            player.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var rate: Float {
        get {
            return player.rate
        }
        
        set {
            player.rate = newValue
        }
    }
    
    var composition: AVMutableComposition? = nil
    var videoComposition: AVMutableVideoComposition? = nil
    var audioMix: AVMutableAudioMix? = nil
    
    private var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }
    
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?
    
    private var playerItem: AVPlayerItem? = nil
    var document: UIDocument?
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var splitButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var timelineV: UIView!
    
    @IBOutlet weak var timelineView: UICollectionView! {
        didSet {
            timelineView.delegate = self
            timelineView.dataSource = self
            timelineView.contentOffset = CGPoint(x:-timelineView.frame.width / 2, y:0)
            timelineView.contentInset = UIEdgeInsets(top: 0, left: timelineView.frame.width/2, bottom: 0, right: timelineView.frame.width/2)
            timelineView.addSubview(emptyView)
            //            timelineView.pinchGestureRecognizer?.addTarget(self, action: #selector(TCVideoEditViewController2.pinch))
            timelineView.panGestureRecognizer.addTarget(self, action: #selector(TCVideoEditViewController2.pan))
        }
    }
    
    @IBOutlet weak var backgroundTimelineView: UICollectionView! {
        didSet {
            backgroundTimelineView.delegate = self
            backgroundTimelineView.dataSource = self
            backgroundTimelineView.contentOffset = CGPoint(x:-backgroundTimelineView.frame.width / 2, y:0)
            backgroundTimelineView.contentInset = UIEdgeInsets(top: 0, left: backgroundTimelineView.frame.width/2, bottom: 0, right: backgroundTimelineView.frame.width/2)
            backgroundTimelineView.addSubview(emptyView)
            //            timelineView.pinchGestureRecognizer?.addTarget(self, action: #selector(TCVideoEditViewController2.pinch))
            backgroundTimelineView.panGestureRecognizer.addTarget(self, action: #selector(TCVideoEditViewController2.pan))
        }
    }
    
    @IBOutlet weak var firstTrackAddButton: UIButton! {
        didSet {
            firstTrackAddButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        }
    }
    
    @IBOutlet weak var secondTrackAddButton: UIButton! {
        didSet {
            firstTrackAddButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        }
    }
    
    
    // MARK: - IBActions
    
    var global_rate: Float = 1
    
    @IBAction func speed(_ sender: Any) {
        if global_rate == 1 {
            global_rate = 0.5
        } else {
            global_rate = 1
        }
        
        if player.rate != 0 {
            player.rate = global_rate
        }
    }
    
    
    @IBAction func weixinEffect(_ sender: UIButton) {
        videoComposition = AVMutableVideoComposition()
        guard let videoComposition = self.videoComposition else {
            return
        }
        videoComposition.renderSize = CGSize(width: 540, height: 960)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.customVideoCompositorClass = APLCustomVideoCompositor.self
        
        // Add two video tracks and two audio tracks.
        let firstVideoTrack = composition?.tracks(withMediaType: AVMediaTypeVideo).first!
        
        let secondVideoTrack = composition?.tracks(withMediaType: AVMediaTypeVideo)[1]
        
        let audioTrack = composition?.tracks(withMediaType: AVMediaTypeAudio).first!

        let videoInstruction =
            APLCustomVideoCompositionInstruction(theSourceTrackIDs:
        [NSNumber(value:firstVideoTrack!.trackID),
        NSNumber(value:secondVideoTrack!.trackID)],
                             forTimeRange: CMTimeRange(start: kCMTimeZero, duration: composition!.duration))
        // First track -> Foreground track while compositing.
        videoInstruction.foregroundTrackID = firstVideoTrack!.trackID
        // Second track -> Background track while compositing.
        videoInstruction.backgroundTrackID =
        secondVideoTrack!.trackID
        
        videoComposition.instructions = [videoInstruction]
        
        
        playerItem = AVPlayerItem(asset: composition!)
        playerItem!.videoComposition = videoComposition
        playerItem!.audioMix = audioMix
        player.replaceCurrentItem(with: playerItem)
        
        currentTime = Double((timelineView.contentOffset.x + timelineView.frame.width/2) / scaledDurationToWidth)
        
    }
    
    
    @IBAction func export(_ sender: Any)
    {
        // Create the export session with the composition and set the preset to the highest quality.
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition!)
        let exporter = AVAssetExportSession(asset: composition!, presetName: AVAssetExportPreset960x540)!
        // Set the desired output URL for the file created by the export process.
        exporter.outputURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(String(Int(Date.timeIntervalSinceReferenceDate))).appendingPathExtension("mov")
        // Set the output file type to be a QuickTime movie.
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = self.videoComposition
        // Asynchronously export the composition to a video file and save this file to the camera roll once export completes.
        
        let size = CGSize(width: 100, height: 100)
        
//        startAnimating(size, message: "正在导出...", type: NVActivityIndicatorType(rawValue: NVActivityIndicatorType.lineScalePulseOut.rawValue)!)
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if (exporter.status == .completed) {
                    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exporter.outputURL!.path)){
                        UISaveVideoAtPathToSavedPhotosAlbum(exporter.outputURL!.path, self, #selector(self.video), nil)
                    }
//                    NVActivityIndicatorPresenter.sharedInstance.setMessage("导出成功")
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
//                        self.stopAnimating()
                    }
                } else {
//                    NVActivityIndicatorPresenter.sharedInstance.setMessage("导出失败")
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
//                        self.stopAnimating()
                    }
                }
            }
        }
    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error:NSError, contextInfo contextInfo:Any) -> Void {
    }
    
    
    func addClip(_ movieURL: URL, trackAdded: Int) {
        let newAsset = AVURLAsset(url: movieURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: TCVideoEditViewController2.assetKeysRequiredToPlay) {
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
                for key in TCVideoEditViewController2.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                
                let videoAssetTrack = newAsset.tracks(withMediaType: AVMediaTypeVideo).first!
                
                let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo)[trackAdded]
                
                compositionVideoTrack.preferredTransform = videoAssetTrack.preferredTransform

                
                try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, newAsset.duration), of: videoAssetTrack, at: kCMTimeZero)
                

                if let audioAssetTrack = newAsset.tracks(withMediaType: AVMediaTypeAudio).first {
                
                    let compositionAudioTrack = self.composition!.tracks(withMediaType: AVMediaTypeAudio).first!
                    
                    compositionAudioTrack.removeTimeRange(compositionAudioTrack.timeRange)
                    try! compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, newAsset.duration), of: audioAssetTrack, at: kCMTimeZero)

                }
                
                self.push(op:.add(0, trackAdded))
                
                // update timeline
                self.updatePlayer()
                
                return
            }
        }
    }
    
    func whichTrack(_ timeline: UICollectionView) -> Int {
        if timeline == timelineView {
            return 0
        } else if timeline == backgroundTimelineView {
            return 1
        } else {
            assert(2==100)
            return 0
        }
    }
    
    func whichTimeline(_ timelineIndex: Int) -> UICollectionView {
        if timelineIndex == 0 {
            return timelineView
        } else if timelineIndex == 1 {
            return backgroundTimelineView
        } else {
            assert(1==100)
            return timelineView
        }
    }
    
    func redoOp(op: OpType) {
        
        switch op {
        case let .copy(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            break
            
        case let .split(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            break
            
        case let .add(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            break
            
        case let .remove(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            break
            
        case let .update(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            break
            
        default:
            _ = 1
        }
        
    }
    
    func undoOp(op: OpType) {
        switch op {
        case let .copy(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            
        case let .split(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            
        case let .add(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            
            break
            
        case let .remove(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            
        case let .update(index, timelineIndex):
            whichTimeline(timelineIndex).reloadData()
            
        default:
            _ = 1
        }
    }
    
    @IBAction func undo(_ sender: Any) {
        if undoPos <= 0 {
            return
        }
        
        undoPos -= 1 
        self.composition = stack[undoPos].comp.mutableCopy() as! AVMutableComposition
        
        undoOp(op: stack[undoPos+1].op)
        
        updatePlayer()
    }
    
    @IBAction func redo(_ sender: Any) {
        if undoPos == stack.count - 1 {
            return
        }
        
        undoPos += 1
        self.composition = stack[undoPos].comp.mutableCopy() as! AVMutableComposition
        
        redoOp(op: stack[undoPos].op)
        
        updatePlayer()
    }
    
    @IBAction func splitClip(_ sender: Any) {
        var timeRangeInAsset: CMTimeRange? = nil
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo).first!
        
        for s in compositionVideoTrack.segments {
            timeRangeInAsset = s.timeMapping.target // assumes non-scaled edit
            
            if !s.isEmpty && timeRangeInAsset!.containsTime(player.currentTime()) {
                let index = compositionVideoTrack.segments.index(of: s)
                
                try! compositionVideoTrack.insertTimeRange(timeRangeInAsset!, of: compositionVideoTrack, at: timeRangeInAsset!.end)
                
                try! compositionVideoTrack.removeTimeRange(CMTimeRange(start:player.currentTime(), duration:timeRangeInAsset!.duration - CMTime(value: 1, timescale: 600)))
                
                
                push(op:.split(index!, 0))
                
                break
            }
        }
        
        updatePlayer()
    }
    
    @IBAction func copyClip(_ sender: Any) {
        var timeRangeInAsset: CMTimeRange? = nil
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo).first
        
        for s in compositionVideoTrack!.segments {
            timeRangeInAsset = s.timeMapping.target; // assumes non-scaled edit
            
            if !s.isEmpty && timeRangeInAsset!.containsTime(player.currentTime()) {
                let index = compositionVideoTrack!.segments.index(of: s)
                
                try! self.composition!.insertTimeRange(timeRangeInAsset!, of: composition!, at: timeRangeInAsset!.end)
                
                push(op:.copy(index!, 0))
                
                break
            }
        }
        
        updatePlayer()
    }
    
    @IBAction func removeClip(_ sender: Any) {
        var timeRangeInAsset: CMTimeRange? = nil
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo).first!
        
        for s in compositionVideoTrack.segments {
            timeRangeInAsset = s.timeMapping.target; // assumes non-scaled edit
            
            if !s.isEmpty && timeRangeInAsset!.containsTime(player.currentTime()) {
                let index = compositionVideoTrack.segments.index(of: s)
                
                let count = compositionVideoTrack.segments.count

                try! compositionVideoTrack.removeTimeRange(timeRangeInAsset!)
                
                try! compositionVideoTrack.insertEmptyTimeRange(timeRangeInAsset!)
                
                if compositionVideoTrack.segments.count == count {
                    push(op:.update(index!, 0))
                } else {
                    push(op:.remove(index!, 0))
                }
                
                break
            }
        }
        
        updatePlayer()
    }
    
    @IBAction func playPauseButtonWasPressed(_ sender: UIButton) {
        if player.rate == 0 {
            // Not playing forward, so play.
            if currentTime == duration {
                // At end, so got back to begining.
                currentTime = 0.0
            }
            
            player.rate = global_rate
            
            //todo: animate
            if #available(iOS 10.0, *) {
                seekTimer?.invalidate()
                seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                    self.timelineView.contentOffset.x = CGFloat(self.currentTime/Double(self.visibleTimeRange)*Double(self.timelineView.frame.width)) - self.timelineView.frame.size.width/2
                    self.backgroundTimelineView.contentOffset.x = CGFloat(self.currentTime/Double(self.visibleTimeRange)*Double(self.timelineView.frame.width)) - self.timelineView.frame.size.width/2
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
    
    func push(op: OpType) {
        var newComposition = self.composition!.mutableCopy() as! AVMutableComposition
        
        while undoPos < stack.count - 1 {
            stack.removeLast()
        }
        
        stack.append(opsAndComps(comp: newComposition, op: op))
        undoPos = stack.count - 1
        
        redoOp(op: op)
    }
    
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    var trackAdded = 0
    
    @IBAction func AddVideo(_ sender: UIButton) {
        if sender == firstTrackAddButton {
            self.trackAdded = 0
        } else {
            self.trackAdded = 1
        }
        let picker = UIImagePickerController()
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    
    func updatePlayer() {
        if composition == nil {
            return
        }
        
        videoComposition = AVMutableVideoComposition()
        videoComposition!.renderSize = CGSize(width: 540, height: 960)
        videoComposition!.frameDuration = CMTimeMake(1, 30)
        
        let firstVideoTrack = composition!.tracks(withMediaType: AVMediaTypeVideo).first!
        
        let secondVideoTrack = composition!.tracks(withMediaType: AVMediaTypeVideo)[1]
        
        var firstTransformedSize = firstVideoTrack.naturalSize.applying(firstVideoTrack.preferredTransform)
        firstTransformedSize.width = abs(firstTransformedSize.width)
        firstTransformedSize.height = abs(firstTransformedSize.height)
        
        var secondTransformedSize = secondVideoTrack.naturalSize.applying(secondVideoTrack.preferredTransform)
        secondTransformedSize.width = abs(secondTransformedSize.width)
        secondTransformedSize.height = abs(secondTransformedSize.height)
        
        for segment in firstVideoTrack.segments {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = segment.timeMapping.target
            
            if segment.isEmpty {
                let transformer2 = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
                transformer2.setTransform(secondVideoTrack.preferredTransform.scaledBy(x: videoComposition!.renderSize.width/secondTransformedSize.width, y: videoComposition!.renderSize.height/secondTransformedSize.height), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer2]
            } else {
                let transformer1 = AVMutableVideoCompositionLayerInstruction(assetTrack: firstVideoTrack)
                transformer1.setTransform(firstVideoTrack.preferredTransform.scaledBy(x: videoComposition!.renderSize.width/firstTransformedSize.width, y: videoComposition!.renderSize.height/firstTransformedSize.height), at: instruction.timeRange.start)
                instruction.layerInstructions = [transformer1]
            }
            
            videoComposition!.instructions.append(instruction)
        }
        
        if secondVideoTrack.timeRange.end > firstVideoTrack.timeRange.end {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(firstVideoTrack.timeRange.end, secondVideoTrack.timeRange.end)
            
            let transformer2 = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
            transformer2.setTransform(secondVideoTrack.preferredTransform.scaledBy(x: videoComposition!.renderSize.width/secondTransformedSize.width, y: videoComposition!.renderSize.height/secondTransformedSize.height), at: instruction.timeRange.start)
            
            instruction.layerInstructions = [transformer2]
            
            videoComposition!.instructions.append(instruction)
        }

        
        playerItem = AVPlayerItem(asset: composition!)
        playerItem!.videoComposition = videoComposition
        playerItem!.audioMix = audioMix
        player.replaceCurrentItem(with: playerItem)
        
        currentTime = Double((timelineView.contentOffset.x + timelineView.frame.width/2) / scaledDurationToWidth)
        
        if firstVideoTrack.segments.count != 0 {
            firstTrackAddButton.isHidden = true
            timelineView.isHidden = false
        } else {
            firstTrackAddButton.isHidden = false
            timelineView.isHidden = true
        }
        
        if secondVideoTrack.segments.count != 0 {
            secondTrackAddButton.isHidden = true
            backgroundTimelineView.isHidden = false
        } else {
            secondTrackAddButton.isHidden = false
            backgroundTimelineView.isHidden = true
        }
        
    }
    
    
    // MARK: - KVO Observation
    
    //   Update our UI when player or `player.currentItem` changes.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &MainViewControllerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(TCVideoEditViewController2.player.currentItem.duration) {
            // Update timeSlider and enable/disable controls when duration > 0.0

            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            }
            else {
                newDuration = kCMTimeZero
            }

        }
        else if keyPath == #keyPath(TCVideoEditViewController2.player.rate) {
            // Update `playPauseButton` image.

            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue

            let buttonImageName = newRate == 0 ? "PlayButton":"PauseButton"

            let buttonImage = UIImage(named: buttonImageName)

            playPauseButton.setImage(buttonImage, for: UIControlState())
        }
        else if keyPath == #keyPath(TCVideoEditViewController2.player.currentItem.status) {
            // Display an error if status becomes `.Failed`.

            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */

            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            }
            else {
                newStatus = .unknown
            }

            if newStatus == .failed {
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
            }
            
        }
        
        let hasValidDuration = newDuration != nil ? newDuration!.isNumeric && newDuration!.value != 0 : true
        let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
        
        playPauseButton.isEnabled = hasValidDuration
        startTimeLabel.text = createTimeString(time: currentTime)
        playPauseButton.isEnabled = newStatus == .readyToPlay && hasValidDuration

    }
    
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     [#keyPath(TCVideoEditViewController2.player.currentItem.duration)],
            "rate":         [#keyPath(TCVideoEditViewController2.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    // MARK: - Error Handling
    
    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        NSLog("Error occured with message: \(message), error: \(error).")
        
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")
        
        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertControllerStyle.alert)
        
        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")
        
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        
        alert.addAction(alertAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Convenience
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    // MARK: Delegate
    
    //    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    //        return emptyView
    //    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        zoomCurrentTime = currentTime
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if player.rate == 0 {
            let _timelineView = scrollView as! UICollectionView
            currentTime = Double((_timelineView.contentOffset.x + _timelineView.frame.width/2) / (_timelineView.frame.width / visibleTimeRange))
            if let timelineView = self.timelineView, let backgroundTimelineView = self.backgroundTimelineView {
                timelineView.contentOffset.x = _timelineView.contentOffset.x
                backgroundTimelineView.contentOffset.x = _timelineView.contentOffset.x
            }
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            addClip(videoURL, trackAdded: trackAdded)
        }
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func pinch(_ recognizer: UIPinchGestureRecognizer) {
        visibleTimeRange = visibleTimeRange * timelineView.zoomScale
        timelineView.collectionViewLayout.invalidateLayout()
        timelineView.contentOffset.x = CGFloat(self.currentTime/CMTimeGetSeconds(self.composition!.duration)*Double(self.timelineView.frame.width)) - self.timelineView.frame.size.width/2
    }
    
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        player.pause()
        seekTimer?.invalidate()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let index = whichTrack(collectionView)
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo)[index]
        
        return CGSize(width: CGFloat(CMTimeGetSeconds((compositionVideoTrack.segments[indexPath.row].timeMapping.target.duration))) * scaledDurationToWidth, height: timelineView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let index = whichTrack(collectionView)
        
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo)[index]
        
        assert(self.composition!.tracks(withMediaType: AVMediaTypeVideo).count == 2)
        
        return compositionVideoTrack.segments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let segmentView = collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)
        segmentView.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0)
        for view in segmentView.subviews {
            view.removeFromSuperview()
        }
        
        let index = whichTrack(collectionView)
        let compositionVideoTrack = self.composition!.tracks(withMediaType: AVMediaTypeVideo)[index]
        
        if compositionVideoTrack.segments[indexPath.row].isEmpty {
            return segmentView
        }
        
        let _composition = composition!.mutableCopy() as! AVMutableComposition
        let _timelineIndex = whichTrack(collectionView)
        assert(_timelineIndex == 0 || _timelineIndex == 1)
        let _track = _composition.tracks(withMediaType: AVMediaTypeVideo)[1-_timelineIndex]
        _composition.removeTrack(_track)
        let imageGenerator = AVAssetImageGenerator.init(asset: _composition)
        imageGenerator.maximumSize = CGSize(width: self.timelineView.bounds.height * 2, height: self.timelineView.bounds.height * 2)
        imageGenerator.appliesPreferredTrackTransform = true
        
        if true {
            var times = [NSValue]()
            
            let timerange = (compositionVideoTrack.segments[indexPath.item].timeMapping.target)
            
            // Generate an image at time zero.
            let incrementTime = CMTime(seconds: Double(timelineView.frame.height /  scaledDurationToWidth), preferredTimescale: 600)
            
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
                        let nextView = UIImageView.init(frame: CGRect(x: nextX, y: 0.0, width: self.timelineView.bounds.height, height: self.timelineView.bounds.height))
                        nextView.contentMode = .scaleAspectFill
                        nextView.clipsToBounds = true
                        nextView.image = UIImage.init(cgImage: image!)
                        
                        segmentView.addSubview(nextView)
                    }
                }
            }
        }
        
        return segmentView
    }
    
}

