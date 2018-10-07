//
//  TCVodPlayViewController.swift
//  TXXiaoShiPinDemo
//
//  Created by zpc on 2018/9/24.
//  Copyright © 2018年 tencent. All rights reserved.
//

import UIKit

let kTCLivePlayError: String = "kTCLivePlayError"

class TCVodPlayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, RosyWriterCapturePipelineDelegate {
    private var _addedObservers: Bool = false
    private var _recording: Bool = false
    private var _backgroundRecordingID: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    private var _allowedToUseGPU: Bool = false
    
    private var _labelTimer: Timer?
    private var _previewView: OpenGLPixelBufferView?
    private var _capturePipeline: RosyWriterCapturePipeline!
    
    @IBOutlet private var recordButton: UIBarButtonItem!
    @IBOutlet private var framerateLabel: UILabel!
    @IBOutlet private var dimensionsLabel: UILabel!
    
    deinit {
        if _addedObservers {
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: UIApplication.shared)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        
    }
    
    //MARK: - View lifecycle
    
    @objc func applicationDidEnterBackground() {
        // Avoid using the GPU in the background
        _allowedToUseGPU = false
        _capturePipeline?.renderingEnabled = false
        
        _capturePipeline?.stopRecording() // a no-op if we aren't recording
        
        // We reset the OpenGLPixelBufferView to ensure all resources have been cleared when going to the background.
        _previewView?.reset()
    }
    
    @objc func applicationWillEnterForeground() {
        _allowedToUseGPU = true
        _capturePipeline?.renderingEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(!self.lives.isEmpty) {
            self.lives.removeAll()
        }
        
        tableView.rowHeight = tableView.height
        tableView.contentSize.width = tableView.width
        
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            self.isLoading = true
            self.lives = []
            self.liveListMgr?.queryVideoList(.up)
        })
        
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: {
            self.isLoading = true
            self.liveListMgr?.queryVideoList(.down)
        })
        
        // 先加载缓存的数据，然后再开始网络请求，以防用户打开是看到空数据
        //        liveListMgr.loadVodsFromArchive()
        //        doFetchList()
        
        DispatchQueue.main.async {
            self.tableView.mj_header.beginRefreshing()
        }
        
        tableView.mj_header.endRefreshing {
            self.isLoading = false
        }
        tableView.mj_footer.endRefreshing {
            self.isLoading = false
        }
    
        _capturePipeline = RosyWriterCapturePipeline(delegate: self, callbackQueue: DispatchQueue.main)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.deviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: UIDevice.current)
        
        // Keep track of changes to the device orientation so we can update the capture pipeline
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        _addedObservers = true
        
        // the willEnterForeground and didEnterBackground notifications are subsequently used to update _allowedToUseGPU
        _allowedToUseGPU = (UIApplication.shared.applicationState != .background)
        _capturePipeline.renderingEnabled = _allowedToUseGPU
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _capturePipeline.startRunning()
        
        _labelTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateLabels), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        _labelTimer?.invalidate()
        _labelTimer = nil
        
        _capturePipeline.stopRunning()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var _currentIdx = 0
    
    let avaliableFilters = CoreImageFilters.avaliableFilters()
    
    //MARK: - UI
    @IBAction func swipeChangeFilter(_ swipeGesture: UISwipeGestureRecognizer) {
        switch swipeGesture.direction {
        case .left:
            _currentIdx = (_currentIdx + 1) % avaliableFilters.count
        case .right:
            _currentIdx = _currentIdx - 1
            if _currentIdx < 0 {
                _currentIdx += avaliableFilters.count
            }
        default:
            assert(false)
        }
        
        if _currentIdx != 33, _currentIdx != 108, _currentIdx != 112 {
            _capturePipeline.changeFilter(_currentIdx)
            self.dimensionsLabel.text = "\(_currentIdx):\(avaliableFilters[_currentIdx])"
        }
        
    }
    
    @IBAction func toggleRecording(_: Any) {
        if _recording {
            _capturePipeline.stopRecording()
        } else {
            // Disable the idle timer while recording
            UIApplication.shared.isIdleTimerDisabled = true
            
            // Make sure we have time to finish saving the movie if the app is backgrounded during recording
            if UIDevice.current.isMultitaskingSupported {
                _backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
            }
            
            self.recordButton.isEnabled = false; // re-enabled once recording has finished starting
            self.recordButton.title = "Stop"
            
            _capturePipeline.startRecording()
            
            _recording = true
        }
    }
    
    private func recordingStopped() {
        _recording = false
        self.recordButton.isEnabled = true
        self.recordButton.title = "Record"
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        UIApplication.shared.endBackgroundTask(_backgroundRecordingID)
        _backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    }
    
    private func setupPreviewView() {
        // Set up GL view
        _previewView = OpenGLPixelBufferView(frame: CGRect.zero)
        _previewView!.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
        
        let currentInterfaceOrientation = UIApplication.shared.statusBarOrientation
        _previewView!.transform = _capturePipeline.transformFromVideoBufferOrientationToOrientation(AVCaptureVideoOrientation(rawValue: currentInterfaceOrientation.rawValue)!, withAutoMirroring: true) // Front camera preview should be mirrored
        
        self.view.insertSubview(_previewView!, at: 0)
        var bounds = CGRect.zero
        bounds.size = self.view.convert(self.view.bounds, to: _previewView).size
        _previewView!.bounds = bounds
        _previewView!.center = CGPoint(x: self.view.bounds.size.width/2.0, y: self.view.bounds.size.height/2.0)
    }
    
    @objc func deviceOrientationDidChange() {
        let deviceOrientation = UIDevice.current.orientation
        
        // Update recording orientation if device changes to portrait or landscape orientation (but not face up/down)
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            _capturePipeline.recordingOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
        }
    }
    
    @objc func updateLabels() {
        let frameRateString = "\(Int(roundf(_capturePipeline.videoFrameRate))) FPS"
        self.framerateLabel.text = frameRateString
        
        let dimensionsString = "\(_capturePipeline.videoDimensions.width) x \(_capturePipeline.videoDimensions.height)"
        //        self.dimensionsLabel.text = dimensionsString
    }
    
    private func showError(_ error: Error) {
        let message = (error as NSError).localizedFailureReason
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: error.localizedDescription, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: error.localizedDescription,
                                        message: message,
                                        delegate: nil,
                                        cancelButtonTitle: "OK")
            alertView.show()
        }
    }
    
    //MARK: - RosyWriterCapturePipelineDelegate
    
    func capturePipeline(_ capturePipeline: RosyWriterCapturePipeline, didStopRunningWithError error: Error) {
        self.showError(error)
        
        self.recordButton.isEnabled = false
    }
    
    // Preview
    func capturePipeline(_ capturePipeline: RosyWriterCapturePipeline, previewPixelBufferReadyForDisplay previewPixelBuffer: CVPixelBuffer) {
        if !_allowedToUseGPU {
            return
        }
        if _previewView == nil {
            self.setupPreviewView()
        }
        
        _previewView!.displayPixelBuffer(previewPixelBuffer)
    }
    
    func capturePipelineDidRunOutOfPreviewBuffers(_ capturePipeline: RosyWriterCapturePipeline) {
        if _allowedToUseGPU {
            _previewView?.flushPixelBufferCache()
        }
    }
    
    // Recording
    func capturePipelineRecordingDidStart(_ capturePipeline: RosyWriterCapturePipeline) {
        self.recordButton.isEnabled = true
    }
    
    func capturePipelineRecordingWillStop(_ capturePipeline: RosyWriterCapturePipeline) {
        // Disable record button until we are ready to start another recording
        self.recordButton.isEnabled = false
        self.recordButton.title = "Record"
    }
    
    func capturePipelineRecordingDidStop(_ capturePipeline: RosyWriterCapturePipeline) {
        self.recordingStopped()
    }
    
    func capturePipeline(_ capturePipeline: RosyWriterCapturePipeline, recordingDidFailWithError error: Error) {
        self.recordingStopped()
        self.showError(error)
    }
    
    
    var liveListMgr: TCLiveListMgr?
    var isLoading: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.lives = []
        liveListMgr = TCLiveListMgr.shared()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(newDataAvailable),
            name: NSNotification.Name(rawValue: kTCLiveListNewDataAvailable),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(listDataUpdated),
            name: NSNotification.Name(rawValue: kTCLiveListUpdated),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(svrError),
            name: NSNotification.Name(rawValue: kTCLiveListSvrError),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playError),
            name: NSNotification.Name(rawValue: kTCLivePlayError),
            object: nil)
    }
    
    
    // MARK: Model
    
    var lives: [TCLiveInfo] = []
    
    struct Model {
        var id = UUID()
        
        // Add additional properties for your own model here.
    }
    
    /// Example data identifiers.
    private let models = (1...1000).map { _ in
        return Model()
    }
    
    /// An `AsyncFetcher` that is used to asynchronously fetch `DisplayData` objects.
    private let asyncFetcher = AsyncFetcher()
    
    // MARK: SubViews
    
    @IBOutlet weak var tableView: UITableView!
    
    /// - Tag: Prefetching
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Begin asynchronously fetching data for the requested index paths.
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            asyncFetcher.fetchAsync(model.id)
        }
    }
    
    /// - Tag: CancelPrefetching
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // Cancel any in-flight requests for data for the specified index paths.
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            asyncFetcher.cancelFetch(model.id)
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return models.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let playViewCell = cell as! TCPlayViewCell
        playViewCell.backgroundTimelineView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let playViewCell = cell as! TCPlayViewCell
        playViewCell.player.pause()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TCPlayViewCell.reuseIdentifier, for: indexPath) as? TCPlayViewCell else {
            fatalError("Expected `\(TCPlayViewCell.self)` type for reuseIdentifier \(TCPlayViewCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        
        if indexPath.row < self.lives.count {
            cell.setLiveInfo(liveInfo: self.lives[indexPath.row])
        }
        
        return cell
    }
    
    
    // MARK: Net fetch
    /**
     * 拉取直播列表。TCLiveListMgr在启动是，会将所有数据下载下来。在未全部下载完前，通过loadLives借口，
     * 能取到部分数据。通过finish接口，判断是否已取到最后的数据
     *
     */
    func doFetchList() {
        let range = NSMakeRange(self.lives.count, 20)

        var finish: ObjCBool = false
        var result = liveListMgr?.readVods(range, finish: &finish)
        
        if result != nil {
            result = mergeResult(result: result! as! [TCLiveInfo])
            self.lives.append(contentsOf: result! as! [TCLiveInfo])
        } else {
            if finish.boolValue {
                let hud = HUDHelper.sharedInstance()?.tipMessage("没有啦")
                hud?.isUserInteractionEnabled = false
            }
        }
        tableView.mj_header.isHidden = true
        tableView.mj_footer.isHidden = true
        tableView.reloadData()
        tableView.mj_header.endRefreshing()
        tableView.mj_footer.endRefreshing()
    }
    
    /**
     *  将取到的数据于已存在的数据进行合并。
     *
     *  @param result 新拉取到的数据
     *
     *  @return 新数据去除已存在记录后，剩余的数据
     */
    func mergeResult(result: [TCLiveInfo]) -> [TCLiveInfo] {
        // 每个直播的播放地址不同，通过其进行去重处理
        let existArray = self.lives.map { (obj) -> String in
            obj.playurl
        }
        
        let newArray = result.filter { (obj) -> Bool in
            !existArray.contains(obj.playurl)
        }
        
        return newArray
    }
    
    /**
     *  TCLiveListMgr有新数据过来
     *
     *  @param noti
     */
    @objc func newDataAvailable(noti: NSNotification) {
        self.doFetchList()
    }
    
    /**
     *  TCLiveListMgr数据有更新
     *
     *  @param noti
     */
    @objc func listDataUpdated(noti: NSNotification) {
    //    [self setup];
    }
    
    
    /**
     *  TCLiveListMgr内部出错
     *
     *  @param noti
     */
    @objc func svrError(noti: NSNotification) {
        let e = noti.object
        if ((e as? NSError) != nil) {
            HUDHelper.alert(e.debugDescription)
        }
        
        // 如果还在加载，停止加载动画
        if self.isLoading {
            tableView.mj_header.endRefreshing()
            tableView.mj_footer.endRefreshing()
            self.isLoading = false
        }
    }
    
    /**
     *  TCPlayViewController出错，加入房间失败
     *
     */
    @objc func playError(noti: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(0.5), execute: {
            //        [self.tableView.mj_header beginRefreshing];
            //加房间失败后，刷新列表，不需要刷新动画
            self.lives = []
            self.isLoading = true
            self.liveListMgr?.queryVideoList(.up)
        })
    }
    
}


