//
//  TCVodPlayViewController.swift
//  TXXiaoShiPinDemo
//
//  Created by zpc on 2018/9/24.
//  Copyright © 2018年 tencent. All rights reserved.
//

import UIKit

let kTCLivePlayError: String = "kTCLivePlayError"

class TCVodPlayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
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

    // MARK: UIViewController overrides
    
    /// - Tag: SetDataSources
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
    }
    
    
    // MARK: UICollectionViewDataSourcePrefetching
    
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


