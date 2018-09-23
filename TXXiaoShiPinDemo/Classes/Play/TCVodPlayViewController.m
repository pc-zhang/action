//
//  TCVodPlayViewController.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/9/15.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCVodPlayViewController.h"
#import "TCVideoRecordViewController.h"
#import <mach/mach.h>
#import <UIImageView+WebCache.h>
#import "TCBaseAppDelegate.h"
#import "TCConstants.h"
#import <Accelerate/Accelerate.h>
#import <UShareUI/UMSocialUIManager.h>
#import <UMSocialCore/UMSocialCore.h>
#import "TCLoginModel.h"
#import "NSString+Common.h"
#import "TCPlayViewCell.h"
#import "TCUserInfoModel.h"
#import "SDKHeader.h"
#import <UShareUI/UMSocialUIManager.h>
#import <UMSocialCore/UMSocialCore.h>
#import <UIImageView+WebCache.h>
#import "TCBaseAppDelegate.h"
#import "TCConstants.h"
#import <Accelerate/Accelerate.h>
#import <UShareUI/UMSocialUIManager.h>
#import <UMSocialCore/UMSocialCore.h>
#import "TCLoginModel.h"
#import "NSString+Common.h"
#import "TCVideoPublishController.h"
#import "TCUserInfoModel.h"
#import "TCLiveListModel.h"
#import <MJRefresh/MJRefresh.h>
#import <AFNetworking.h>
#import "HUDHelper.h"
#import <MJExtension/MJExtension.h>
#import <BlocksKit/BlocksKit.h>
#import "UIColor+MLPFlatColors.h"


NSString *const kTCLivePlayError = @"kTCLivePlayError";


#define RTMP_URL    @"请输入或扫二维码获取播放地址"
#define CACHE_PLAYER  3
#define PLAY_CLICK @"PLAY_CLICK"       //当前播放器启动播放
#define PLAY_PREPARE @"PLAY_PREPARE"   //当前播放器收到 PLAY_PREPARE 事件
#define PLAY_REVIEW  @"PLAY_REVIEW"    //当前视频的审核状态，只有审核通过才能播放

typedef NS_ENUM(NSInteger,DragDirection){
    DragDirection_Down,
    DragDirection_Up,
};

@interface TCVodPlayViewController ()

@property TCLiveListMgr *liveListMgr;
@property(nonatomic, strong) NSMutableArray *lives;
@property BOOL isLoading;

@end

@implementation TCVodPlayViewController
{
    TXLivePlayConfig*    _config;
    
    long long            _trackingTouchTS;
    BOOL                 _startSeek;
    BOOL                 _videoPause;
    BOOL                 _videoFinished;
    BOOL                 _appIsInterrupt;
    float                _sliderValue;
    BOOL                 _isInVC;
    NSString             *_logMsg;
    NSString             *_rtmpUrl;
    
    BOOL                 _isErrorAlert; //是否已经弹出了错误提示框，用于保证在同时收到多个错误通知时，只弹一个错误提示框
    BOOL                 _statusBarHidden;
    BOOL                 _navigationBarHidden;
    BOOL                 _beginDragging;
    
    __weak IBOutlet UITableView *_tableView;
    NSMutableArray*      _playerList;
    NSInteger            _liveInfoIndex;
   
    TCPlayViewCell *     _currentCell;
    TXVodPlayer *        _currentPlayer;
    DragDirection        _dragDirection;
    MBProgressHUD*       _hub;
}

- (void)setup
{
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
    if(self.lives) [self.lives removeAllObjects];
    
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        self.isLoading = YES;
        self.lives = [NSMutableArray array];
        [_liveListMgr queryVideoList:GetType_Up];
    }];
    
    _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        self.isLoading = YES;
        [_liveListMgr queryVideoList:GetType_Down];
    }];
    
    // 先加载缓存的数据，然后再开始网络请求，以防用户打开是看到空数据
    [self.liveListMgr loadVodsFromArchive];
    [self doFetchList];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_tableView.mj_header beginRefreshing];
    });
    
    [(MJRefreshHeader *)_tableView.mj_header endRefreshingWithCompletionBlock:^{
        self.isLoading = NO;
    }];
    [(MJRefreshHeader *)_tableView.mj_footer endRefreshingWithCompletionBlock:^{
        self.isLoading = NO;
    }];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.lives = [NSMutableArray array];
        _liveListMgr = [TCLiveListMgr sharedMgr];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataAvailable:) name:kTCLiveListNewDataAvailable object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listDataUpdated:) name:kTCLiveListUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(svrError:) name:kTCLiveListSvrError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playError:) name:kTCLivePlayError object:nil];
    }
    return self;
}



- (void)addNotify{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    _tableView.rowHeight = [UIScreen mainScreen].bounds.size.height;
    
    [self setup];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _isInVC = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    [self.navigationController setNavigationBarHidden:YES];
    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    
    if (_videoPause && _currentPlayer) {
        //这里如果是从录制界面，或则其他播放界面过来的，要重新startPlay，因为AudioSession有可能被修改了，导致当前视频播放有异常
        NSMutableDictionary *param = [self getPlayerParam:_currentPlayer];
        [_currentPlayer startPlay:param[@"playUrl"]];
        [_currentCell.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        _videoPause = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:_navigationBarHidden];
    [[UIApplication sharedApplication]setStatusBarHidden:_statusBarHidden];
    if (!_videoPause && _currentPlayer) {
        [self clickPlayVod];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//在低系统（如7.1.2）可能收不到这个回调，请在onAppDidEnterBackGround和onAppWillEnterForeground里面处理打断逻辑
- (void) onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_appIsInterrupt == NO) {
            if (!_videoPause) {
                [_currentPlayer pause];
            }
            _appIsInterrupt = YES;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            if (_appIsInterrupt == YES) {
                if (!_videoPause) {
                    [_currentPlayer resume];
                }
                _appIsInterrupt = NO;
            }
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if (_appIsInterrupt == NO) {
        if (!_videoPause) {
            [_currentPlayer pause];
        }
        _appIsInterrupt = YES;
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    if (_appIsInterrupt == YES) {
        if (!_videoPause) {
            [_currentPlayer resume];
        }
        _appIsInterrupt = NO;
    }
}

- (void)initPlayer{
    int playerCount = 0;
    int liveIndex   = (int)_liveInfoIndex;
    int liveIndexOffset = - CACHE_PLAYER / 2;
    if (_liveInfoIndex <= CACHE_PLAYER / 2) {
        liveIndex = 0;
        liveIndexOffset = 0;
    }
    if (_liveInfoIndex >= self.lives.count - CACHE_PLAYER / 2 - 1) {
        liveIndex = (int)self.lives.count - CACHE_PLAYER;
        liveIndexOffset = 0;
    }
    while (playerCount < CACHE_PLAYER) {
        TXVodPlayer *player = [[TXVodPlayer alloc] init];
        player.isAutoPlay = NO;
        TCLiveInfo *info = self.lives[liveIndex + liveIndexOffset];
        NSString *playUrl = [self checkHttps:info.playurl];
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setObject:player forKey:@"player"];
        [param setObject:playUrl forKey:@"playUrl"];
        [param setObject:@(NO) forKey:PLAY_CLICK];
        [param setObject:@(NO) forKey:PLAY_PREPARE];
        [param setObject:@(info.reviewStatus) forKey:PLAY_REVIEW];
        [_playerList addObject:param];
        playerCount ++;
        liveIndexOffset ++;
    }
}

- (void)resetPlayer{
    int liveIndexOffset = - CACHE_PLAYER / 2;
    for(NSMutableDictionary *playerParam in _playerList){
        //先停掉所有的播放器
        TXVodPlayer *player = playerParam[@"player"];
        if ([playerParam[PLAY_REVIEW] intValue] == ReviewStatus_Normal) {
            [player stopPlay];
            [player removeVideoWidget];
        }
        
        //播放器重新对应 -> playeUrl
        if (_liveInfoIndex + liveIndexOffset >= 0 && _liveInfoIndex + liveIndexOffset < self.lives.count) {
            TCLiveInfo *info = self.lives[_liveInfoIndex + liveIndexOffset];
            NSString *playUrl = [self checkHttps:info.playurl];
            [playerParam setObject:playUrl forKey:@"playUrl"];
            [playerParam setObject:@(NO) forKey:PLAY_CLICK];
            [playerParam setObject:@(NO) forKey:PLAY_PREPARE];
            [playerParam setObject:@(info.reviewStatus) forKey:PLAY_REVIEW];
        }
        liveIndexOffset ++;
    }
}

- (void)loadNextPlayer{
    //找到下一个player预加载
    int index = (int)[_playerList indexOfObject:[self getPlayerParam:_currentPlayer]];
    switch (_dragDirection) {
        case DragDirection_Down:
        {
            //向下拖动，预加载下一个播放器
            if (index < _playerList.count - 1) {
                NSMutableDictionary *param = _playerList[index + 1];
                if (![param[PLAY_CLICK] boolValue]) {
                    [self startPlay:param];
                }
            }
        }
            break;
        case DragDirection_Up:
        {
            //向上拖动，预加载上一个播放器
            if (index > 0) {
                NSMutableDictionary *param = _playerList[index - 1];
                if (![param[PLAY_CLICK] boolValue]) {
                    [self startPlay:param];
                }
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)resumePlayer{
    //先暂停上一个播放器
    if (_currentPlayer) {
        [_currentPlayer seek:0];
        [_currentPlayer pause];
    }
    [_currentCell.playBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    
    //开启下一个播放器
    BOOL findPlayer = NO;
    for (int i = 0; i < _playerList.count; i ++) {
        NSMutableDictionary *playParam = _playerList[i];
        NSString *playUrl = [playParam objectForKey:@"playUrl"];
        if ([playUrl isEqualToString:[self playUrl]]) {
            findPlayer = YES;
            _currentPlayer = (TXVodPlayer *)[playParam objectForKey:@"player"];
            [_currentPlayer setupVideoWidget:_currentCell.videoParentView insertIndex:0];
//            [_currentPlayer setRenderRotation:HOME_ORIENTATION_DOWN];
            
            //判断播放器是否启动播放,如果没有，先启动播放
            if (![playParam[PLAY_CLICK] boolValue]) {
                [self startPlay:playParam];
            }
            
            //判断播放器是否收到 PLAY_PREPARE 事件，如果收到，直接resume播放，如果没收到，在播放回调里面resume播放
            if ([playParam[PLAY_PREPARE] boolValue]) {
                [_currentPlayer resume];
                [_currentCell.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            }
            
            //边界检查，防止越界
            if (_liveInfoIndex < CACHE_PLAYER / 2 || _liveInfoIndex > self.lives.count - CACHE_PLAYER / 2 - 1) {
                break;
            }
            //缓存播放器切换
            if (i > CACHE_PLAYER / 2) {
                int needMove = i - CACHE_PLAYER / 2;
                for (int j = 0; j < needMove; j ++) {
                    NSMutableDictionary *oldParam = _playerList[j];
                    TXVodPlayer *player = [oldParam objectForKey:@"player"];
                    if ([oldParam[PLAY_REVIEW] intValue] == ReviewStatus_Normal) {
                        [player stopPlay];
                        [player removeVideoWidget];
                    }
                    
                    TCLiveInfo *liveInfo = self.lives[_liveInfoIndex + 1 + j];
                    NSString *playUrl = [self checkHttps:liveInfo.playurl];
                    NSMutableDictionary *newParam = [NSMutableDictionary dictionary];
                    [newParam setObject:player forKey:@"player"];
                    [newParam setObject:playUrl forKey:@"playUrl"];
                    [newParam setObject:@(NO) forKey:PLAY_CLICK];
                    [newParam setObject:@(NO) forKey:PLAY_PREPARE];
                    [newParam setObject:@(liveInfo.reviewStatus) forKey:PLAY_REVIEW];
                    [_playerList removeObject:oldParam];
                    [_playerList addObject:newParam];
                }
            }
            if (i < CACHE_PLAYER / 2){
                int needMove = CACHE_PLAYER / 2 - i;
                for (int j = 0; j < needMove; j ++) {
                    NSMutableDictionary *oldParam = _playerList[CACHE_PLAYER - 1 - j];
                    TXVodPlayer *player = [oldParam objectForKey:@"player"];
                    if ([oldParam[PLAY_REVIEW] intValue] == ReviewStatus_Normal) {
                        [player stopPlay];
                        [player removeVideoWidget];
                    }
                    
                    TCLiveInfo *liveInfo = self.lives[_liveInfoIndex - 1 - j];
                    NSString *playUrl = [self checkHttps:liveInfo.playurl];
                    NSMutableDictionary *newParam = [NSMutableDictionary dictionary];
                    [newParam setObject:player forKey:@"player"];
                    [newParam setObject:playUrl forKey:@"playUrl"];
                    [newParam setObject:@(NO) forKey:PLAY_CLICK];
                    [newParam setObject:@(NO) forKey:PLAY_PREPARE];
                    [newParam setObject:@(liveInfo.reviewStatus) forKey:PLAY_REVIEW];
                    [_playerList removeObject:oldParam];
                    [_playerList insertObject:newParam atIndex:0];
                }
            }
            //这里注意break，防止逻辑错误
            break;
        }
    }
    if (!findPlayer) {
        //重新对应 player <-> playUrl
        [self resetPlayer];
        
        //启动当前播放器
        NSMutableDictionary *playerParam = _playerList[CACHE_PLAYER / 2];
        _currentPlayer = playerParam[@"player"];
        [_currentPlayer setupVideoWidget:_currentCell.videoParentView insertIndex:0];
        [_currentPlayer setRenderRotation:HOME_ORIENTATION_DOWN];
        [self startPlay:playerParam];
    }
    
    //预加载下一个播放器
    [self loadNextPlayer];
}

-(BOOL)startPlay:(NSMutableDictionary *)playerParam{
    NSString *playUrl = playerParam[@"playUrl"];
    if (![self checkPlayUrl:playUrl]) {
        return NO;
    }
    
    TXVodPlayer *voidPlayer = (TXVodPlayer *)playerParam[@"player"];
    if(voidPlayer != nil)
    {
        TXVodPlayConfig *cfg = voidPlayer.config;
        if (cfg == nil) {
            cfg = [TXVodPlayConfig new];
        }
        cfg.cacheFolderPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/txcache"];
        cfg.maxCacheItems = 5;
        voidPlayer.config = cfg;
        
        voidPlayer.vodDelegate = self;
        voidPlayer.isAutoPlay = NO;
        voidPlayer.enableHWAcceleration = YES;
        [voidPlayer setRenderRotation:HOME_ORIENTATION_DOWN];
        [voidPlayer setRenderMode:RENDER_MODE_FILL_EDGE];
        voidPlayer.loop = YES;
        
        //经过审核的视频才启动播放
        if ([playerParam[PLAY_REVIEW] intValue] == ReviewStatus_Normal) {
            [playerParam setObject:@(YES) forKey:PLAY_CLICK];
            int result = [voidPlayer startPlay:playUrl];
            if( result != 0)
            {
                [self toastTip:[NSString stringWithFormat:@"%@%d", kErrorMsgRtmpPlayFailed, result]];
                [self closeVCWithRefresh:YES popViewController:YES];
                return NO;
            }
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        }
    }
    _startSeek = NO;
    
    NSString* ver = [TXLiveBase getSDKVersionStr];
    _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@",ver];
    [_currentCell.logViewEvt setText:_logMsg];
    return YES;
}

-(BOOL)startVodPlay{
    [self clearLog];
    NSString* ver = [TXLiveBase getSDKVersionStr];
    _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@",ver];
    [_currentCell.logViewEvt setText:_logMsg];
    
    _currentPlayer.vodDelegate = self;
    NSMutableDictionary *playerParam = [self getPlayerParam:_currentPlayer];
    [playerParam setObject:@(NO) forKey:PLAY_PREPARE];
    [self resumePlayer];
    return YES;
}

- (void)stopRtmp{
    for (NSMutableDictionary *param in _playerList) {
        TXVodPlayer *player = param[@"player"];
        player.vodDelegate = nil;
        [player stopPlay];
        [player removeVideoWidget];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (NSString *)playUrl{
    TCLiveInfo *liveInfo = self.lives[_liveInfoIndex];
    NSString *playUrl = [self checkHttps:liveInfo.playurl];
    return playUrl;
}

- (NSMutableDictionary *)getPlayerParam:(TXVodPlayer *)player{
    for (NSMutableDictionary *param in _playerList) {
        if ([[param objectForKey:@"player"] isEqual:player]) {
            return param;
        }
    }
    return nil;
}

#pragma mark - UI EVENT
-(void)closeVC:(BOOL)isRefresh  popViewController:(BOOL)popViewController{
    [self closeVCWithRefresh:isRefresh popViewController:popViewController];
//    [UMSocialUIManager dismissShareMenuView];
}

- (void)closeVCWithRefresh:(BOOL)refresh popViewController: (BOOL)popViewController {
    [self stopRtmp];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (refresh) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTCLivePlayError object:self];
        });
    }
    if (popViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)clickPlayVod{
    if (!_videoFinished) {
        if (_videoPause) {
            [_currentPlayer resume];
            [_currentCell.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        } else {
            [_currentPlayer pause];
            [_currentCell.playBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }
        _videoPause = !_videoPause;
    }
    else {
        [_currentPlayer resume];
        [_currentCell.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    //todo
}

- (void)clickLog:(UIButton*)btn {
    if (_log_switch == YES)
    {
        _currentCell.statusView.hidden = YES;
        _currentCell.logViewEvt.hidden = YES;
        [btn setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _currentCell.cover.hidden = YES;
        _log_switch = NO;
    }
    else
    {
        _currentCell.statusView.hidden = NO;
        _currentCell.logViewEvt.hidden = NO;
        [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _currentCell.cover.alpha = 0.5;
        _currentCell.cover.hidden = NO;
        _log_switch = YES;
    }
}

- (void)clickChorus:(UIButton *)button {
    if([TCLoginParam shareInstance].isExpired){
        [[AppDelegate sharedAppDelegate] enterLoginUI];
        return;
    }
    [TCUtil report:xiaoshipin_videochorus userName:nil code:0 msg:@"合唱事件"];
    if (_currentPlayer.isPlaying) {
        [self clickPlayVod];
    }
    _hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hub.mode = MBProgressHUDModeText;
    _hub.label.text = @"正在加载视频...";
    
    __weak __typeof(self) weakSelf = self;
    NSMutableDictionary *playerParam = [self getPlayerParam:_currentPlayer];
    [TCUtil downloadVideo:playerParam[@"playUrl"] process:^(CGFloat process) {
        [weakSelf onloadVideoProcess:process];
    } complete:^(NSString *videoPath) {
        [weakSelf onloadVideoComplete:videoPath];
    }];
}

-(void)onloadVideoProcess:(CGFloat)process {
    _hub.label.text = [NSString stringWithFormat:@"正在加载视频%d%%",(int)(process * 100)];
}

-(void)onloadVideoComplete:(NSString *)videoPath {
    if (videoPath) {
        TCVideoRecordViewController *vc = [[TCVideoRecordViewController alloc] init];
        vc.videoPath = videoPath;
        [self.navigationController pushViewController:vc animated:YES];
        [_hub hideAnimated:YES];
    }else{
        _hub.label.text = @"视频加载失败";
        [_hub hideAnimated:YES afterDelay:1.0];
    }
}

#pragma mark UISlider - play seek
-(void)onSeek:(UISlider *)slider{
    [_currentPlayer seek:_sliderValue];
    _trackingTouchTS = [[NSDate date]timeIntervalSince1970]*1000;
    _startSeek = NO;
}

-(void)onSeekBegin:(UISlider *)slider{
    _startSeek = YES;
}

-(void)onDrag:(UISlider *)slider {
    float progress = slider.value;
    int intProgress = progress + 0.5;
    _currentCell.playLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)intProgress / 3600,(int)(intProgress / 60), (int)(intProgress % 60)];
    _sliderValue = slider.value;
}

#pragma mark TXVodPlayListener
-(void) onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    dispatch_async(dispatch_get_main_queue(), ^{
        //player 收到准备好事件，记录下状态，下次可以直接resume
        if (EvtID == PLAY_EVT_VOD_PLAY_PREPARED) {
            NSMutableDictionary *playerParam = [self getPlayerParam:player];
            [playerParam setObject:@(YES) forKey:PLAY_PREPARE];
            if ([_currentPlayer isEqual:player]){
                [player resume];
        }
        }
        
//        //暂时不需要旋转逻辑
//        if (EvtID == PLAY_EVT_CHANGE_RESOLUTION) {
//            if (player.width > player.height) {
//                [player setRenderRotation:HOME_ORIENTATION_RIGHT];
//            }
//        }
        
        //只处理当前播放器的Event事件
        if (![_currentPlayer isEqual:player]) return;
        [self report:EvtID];
        
        if (EvtID == PLAY_EVT_VOD_PLAY_PREPARED) {
            //收到PREPARED事件的时候 resume播放器
            [_currentPlayer resume];
            [_currentCell.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            
        } else if (EvtID == PLAY_EVT_PLAY_BEGIN) {
            _videoFinished = NO;
            
        } else if (EvtID == PLAY_EVT_RCV_FIRST_I_FRAME) {
            if (!_isInVC) {
                self.videoIsReady();
            }
        } else if (EvtID == PLAY_EVT_PLAY_PROGRESS && !_videoFinished) {
            if (_startSeek) return ;
            // 避免滑动进度条松开的瞬间可能出现滑动条瞬间跳到上一个位置
            long long curTs = [[NSDate date]timeIntervalSince1970]*1000;
            if (llabs(curTs - _trackingTouchTS) < 500) {
                return;
            }
            _trackingTouchTS = curTs;
            
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            int intProgress = progress + 0.5;
            _currentCell.playLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)(intProgress / 3600), (int)(intProgress / 60), (int)(intProgress % 60)];
            [_currentCell.playProgress setValue:progress];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            int intDuration = duration + 0.5;
            if (duration > 0 && _currentCell.playProgress.maximumValue != duration) {
                [_currentCell.playProgress setMaximumValue:duration];
                _currentCell.playDuration.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)(intDuration / 3600), (int)(intDuration / 60 % 60), (int)(intDuration % 60)];
            }
            return ;
        } else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END) {
            //            [self stopRtmp];
            [_currentPlayer pause];
            _videoPause  = NO;
            _videoFinished = YES;
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [_currentCell.playProgress setValue:0];
            _currentCell.playLabel.text = @"00:00:00";
            
            [_currentCell.playBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            
        } else if (EvtID == PLAY_EVT_PLAY_LOADING){
            
        }
        
    });
}

-(void)report:(int)EvtID
{
    if (EvtID == PLAY_EVT_RCV_FIRST_I_FRAME) {
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"视频播放成功"];
        }
    else if(EvtID == PLAY_ERR_NET_DISCONNECT){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"网络断连,且经多次重连抢救无效,可以放弃治疗,更多重试请自行重启播放"];
    }
    else if(EvtID == PLAY_ERR_GET_RTMP_ACC_URL_FAIL){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"获取加速拉流地址失败"];
    }
    else if(EvtID == PLAY_ERR_FILE_NOT_FOUND){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"播放文件不存在"];
    }
    else if(EvtID == PLAY_ERR_HEVC_DECODE_FAIL){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"H265解码失败"];
    }
    else if(EvtID == PLAY_ERR_HLS_KEY){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"HLS解码key获取失败"];
    }
    else if(EvtID == PLAY_ERR_GET_PLAYINFO_FAIL){
        [TCUtil report:xiaoshipin_vodplay userName:nil code:EvtID msg:@"获取点播文件信息失败"];
    }
}

-(void) onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary*)param
{

}

-(void) appendLog:(NSString*) evt time:(NSDate*) date mills:(int)mil
{
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log];
    [_currentCell.logViewEvt setText:_logMsg];
}


- (void)clickShare:(UIButton *)button {
    [self shareLive];
}

#pragma mark UITableViewDelegate
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return self.view.height;
//}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return self.lives.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCPlayViewCell *cell = (TCPlayViewCell *)[_tableView dequeueReusableCellWithIdentifier:@"TCPlayViewCell" forIndexPath:indexPath];
    
    cell.delegate = self;
    [cell setLiveInfo:self.lives[indexPath.row]];
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _beginDragging = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGPoint rect = scrollView.contentOffset;
    NSInteger index = rect.y / self.view.height;
    if (_beginDragging && _liveInfoIndex != index) {
        if (index > _liveInfoIndex) {
            _dragDirection = DragDirection_Down;
        }else{
            _dragDirection = DragDirection_Up;
        }
        _liveInfoIndex = index;
        _currentCell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_liveInfoIndex inSection:0]];
        [self resumePlayer];
        _beginDragging = NO;
    }
}

#pragma mark Utils
- (void)clearLog {
    _logMsg = @"";
    [_currentCell.statusView setText:@""];
    [_currentCell.logViewEvt setText:@""];
}

-(NSString *)checkHttps:(NSString *)playUrl{
    NSStringCheck(playUrl);
    if ([playUrl hasPrefix:@"http:"]) {
        playUrl = [playUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    }
    return playUrl;
}

-(BOOL)checkPlayUrl:(NSString*)playUrl {
    if ([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) {
        if ([playUrl rangeOfString:@".flv"].length > 0) {
            
        } else if ([playUrl rangeOfString:@".m3u8"].length > 0){
            
        } else if ([playUrl rangeOfString:@".mp4"].length > 0){
            
        } else {
            [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
            return NO;
        }
        
    } else {
        [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
        return NO;
    }
    
    
    return YES;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


//创建高斯模糊效果图片
-(UIImage *)gsImage:(UIImage *)image withGsNumber:(CGFloat)blur
{
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    CGImageRef img = image.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    //从CGImage中获取数据
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    //设置从CGImage获取对象的属性
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate( outBuffer.data, outBuffer.width, outBuffer.height, 8, outBuffer.rowBytes, colorSpace, kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    CFRelease(inBitmapData);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    return returnImage;
}

/**
 *缩放图片
 */
-(UIImage*)scaleImage:(UIImage *)image scaleToSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

/**
 *裁剪图片
 */
-(UIImage *)clipImage:(UIImage *)image inRect:(CGRect)rect{
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    return newImage;
}
/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}


- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

- (void)shareLive {
    __weak typeof(self) weakSelf = self;
    //显示分享面板
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        [weakSelf shareDataWithPlatform:platformType];
    }];
}

- (void)shareDataWithPlatform:(UMSocialPlatformType)platformType
{
    // 创建UMSocialMessageObject实例进行分享
    // 分享数据对象
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
    
    NSString *title = self.liveInfo.title;
    
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&type=%d&fileid=%@&ts=%@&sdkappid=%@&acctype=%@",
                     kLivePlayShareAddr,
                     TC_PROTECT_STR([self.liveInfo.userid stringByUrlEncoding]),
                     1,
                     TC_PROTECT_STR([self.liveInfo.fileid stringByUrlEncoding]),
                     [NSString stringWithFormat:@"%d", self.liveInfo.timestamp],
                     [[TCUserInfoModel sharedInstance] getUserProfile].appid,
                     [[TCUserInfoModel sharedInstance] getUserProfile].accountType];
    NSString *text = [NSString stringWithFormat:@"%@ 正在直播", self.liveInfo.userinfo.nickname ? self.liveInfo.userinfo.nickname : self.liveInfo.userid];
    
    
    /* 以下分享类型，开发者可根据需求调用 */
    // 1、纯文本分享
    messageObject.text = @"开播啦，小伙伴火速围观～～～";
    
    
    
    // 2、 图片或图文分享
    // 图片分享参数可设置URL、NSData类型
    // 注意：由于iOS系统限制(iOS9+)，非HTTPS的URL图片可能会分享失败
    UMShareImageObject *shareObject = [UMShareImageObject shareObjectWithTitle:title descr:text thumImage:self.liveInfo.userinfo.frontcover];
    [shareObject setShareImage:self.liveInfo.userinfo.frontcoverImage];
    
    UMShareWebpageObject *share2Object = [UMShareWebpageObject shareObjectWithTitle:title descr:text thumImage:self.liveInfo.userinfo.frontcoverImage];
    share2Object.webpageUrl = url;
    
    //新浪微博有个bug，放在shareObject里面设置url，分享到网页版的微博不显示URL链接，这里在text后面也加上链接
    if (platformType == UMSocialPlatformType_Sina) {
        messageObject.text = [NSString stringWithFormat:@"%@  %@",messageObject.text,share2Object.webpageUrl];
    }else{
        messageObject.shareObject = share2Object;
    }
    [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
        
        
        NSString *message = nil;
        if (!error) {
            message = [NSString stringWithFormat:@"分享成功"];
        } else {
            if (error.code == UMSocialPlatformErrorType_Cancel) {
                message = [NSString stringWithFormat:@"分享取消"];
            } else if (error.code == UMSocialPlatformErrorType_NotInstall) {
                message = [NSString stringWithFormat:@"应用未安装"];
            } else {
                message = [NSString stringWithFormat:@"分享失败，失败原因(Code＝%d)\n",(int)error.code];
            }
            
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }];
}


#pragma mark - Net fetch
/**
 * 拉取直播列表。TCLiveListMgr在启动是，会将所有数据下载下来。在未全部下载完前，通过loadLives借口，
 * 能取到部分数据。通过finish接口，判断是否已取到最后的数据
 *
 */
- (void)doFetchList {
    NSRange range = NSMakeRange(self.lives.count, 20);
    BOOL finish;
    NSArray *result = [_liveListMgr readVods:range finish:&finish];
    if (result.count) {
        result = [self mergeResult:result];
        [self.lives addObjectsFromArray:result];
    } else {
        if (finish) {
            MBProgressHUD *hud = [[HUDHelper sharedInstance] tipMessage:@"没有啦"];
            hud.userInteractionEnabled = NO;
        }
    }
    _tableView.mj_footer.hidden = finish;
    [_tableView reloadData];
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
    
//    if (self.lives.count == 0) {
//        _nullDataView.hidden = NO;
//    }else{
//        _nullDataView.hidden = YES;
//    }
}

/**
 *  将取到的数据于已存在的数据进行合并。
 *
 *  @param result 新拉取到的数据
 *
 *  @return 新数据去除已存在记录后，剩余的数据
 */
- (NSArray *)mergeResult:(NSArray *)result {
    
    // 每个直播的播放地址不同，通过其进行去重处理
    NSArray *existArray = [self.lives bk_map:^id(TCLiveInfo *obj) {
        return obj.playurl;
    }];
    NSArray *newArray = [result bk_reject:^BOOL(TCLiveInfo *obj) {
        return [existArray containsObject:obj.playurl];
    }];
    
    return newArray;
}

/**
 *  TCLiveListMgr有新数据过来
 *
 *  @param noti
 */
- (void)newDataAvailable:(NSNotification *)noti {
    [self doFetchList];
    //    return;
    // 此处一定要用cell的数据，live中的对象可能已经清空了
    TCLiveInfo *info = (TCLiveInfo*)[self.lives objectAtIndex:0];
    
    // MARK: 打开播放界面
    if (self.lives && self.lives.count > 0 && info) {
        _videoIsReady = ^(){};
        _liveInfo     = info;
        if (true) {
            _videoPause    = NO;
            _videoFinished = YES;
            _isInVC        = NO;
            _log_switch    = NO;
            _liveInfoIndex = 0;
            _playerList    = [NSMutableArray array];
            _isErrorAlert = NO;
            _dragDirection = DragDirection_Down;
            [self initPlayer];
            [self addNotify];
        }
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_liveInfoIndex inSection:0];
    //    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    _currentCell = [_tableView cellForRowAtIndexPath:indexPath];
    
    [self startVodPlay];
}

/**
 *  TCLiveListMgr数据有更新
 *
 *  @param noti
 */
- (void)listDataUpdated:(NSNotification *)noti {
//    [self setup];
}


/**
 *  TCLiveListMgr内部出错
 *
 *  @param noti
 */
- (void)svrError:(NSNotification *)noti {
    NSError *e = noti.object;
    if ([e isKindOfClass:[NSError class]]) {
        if ([e localizedFailureReason]) {
            [HUDHelper alert:[e localizedFailureReason]];
        }
        else if ([e localizedDescription]) {
            [HUDHelper alert:[e localizedDescription]];
        }
    }
    
    // 如果还在加载，停止加载动画
    if (self.isLoading) {
        [_tableView.mj_header endRefreshing];
        [_tableView.mj_footer endRefreshing];
        self.isLoading = NO;
    }
}

/**
 *  TCPlayViewController出错，加入房间失败
 *
 */
- (void)playError:(NSNotification *)noti {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //        [self.tableView.mj_header beginRefreshing];
        //加房间失败后，刷新列表，不需要刷新动画
        self.lives = [NSMutableArray array];
        self.isLoading = YES;
        [_liveListMgr queryVideoList:GetType_Up];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

