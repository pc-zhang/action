/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `UICollectionViewCell` used to represent data in the collection view.
*/

import UIKit

struct Constants {
    static let FULL_SCREEN_PLAY_VIDEO_VIEW = 10000
    static let BOTTOM_BTN_ICON_WIDTH = 35
}

public protocol TCPlayDecorateDelegate : NSObjectProtocol {
    
//    func closeVC(_ isRefresh: ObjCBool, popViewController: ObjCBool)
//    func clickScreen(_ gestureRecognizer: UITapGestureRecognizer)
//    func clickPlayVod()
//    func onSeek(_ slider: UISlider)
//    func onSeekBegin(_ slider: UISlider)
//    func onDrag(_ slider: UISlider)
//    func clickLog(_ button: UIButton)
//    func clickShare(_ button: UIButton)
//    func clickChorus(_ button: UIButton)
    func onloadVideoComplete(_ videoPath:String)
}


class TCShowLiveTopView : UIView {
    var hostNickName: String
    var hostFaceUrl: String
    
    init(frame: CGRect, hostNickName:String, hostFaceUrl:String) {
        self.hostNickName = hostNickName
        self.hostFaceUrl = hostFaceUrl
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelImageLoading() {
    
    }
}


final class TCPlayViewCell: UITableViewCell, TCPlayDecorateDelegate, UITextFieldDelegate, UIAlertViewDelegate {
    
    var playUrl: String?
    var hud: MBProgressHUD?
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var _liveInfo: TCLiveInfo?
    var _touchBeginLocation: CGPoint?
    var _bulletBtnIsOn: Bool?
    var _viewsHidden: Bool?
    var _heartAnimationPoints: NSMutableArray?
    var _topView: TCShowLiveTopView?
    var _actionSheet1: UIActionSheet?
    var _actionSheet2: UIActionSheet?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func closeVC(_ isRefresh: ObjCBool, popViewController: ObjCBool) {
        
    }
    
    func clickScreen(_ gestureRecognizer: UITapGestureRecognizer) {
        
    }
    
    func clickPlayVod() {
        
    }
    
    func onSeek(_ slider: UISlider) {
        
    }
    
    func onSeekBegin(_ slider: UISlider) {
        
    }
    
    func onDrag(_ slider: UISlider) {
        
    }
    
    func clickLog(_ button: UIButton) {
        
    }
    
    func clickShare(_ button: UIButton) {
        
    }
    
    @IBAction func clickChorus(_ button: UIButton) {
//        if TCLoginParam.shareInstance()!.isExpired() {
//            AppDelegate.shared().enterLoginUI()
//            return
//        }
        
        TCUtil.report(xiaoshipin_videochorus, userName: nil, code: 0, msg: "合唱事件")
        
        
        hud = MBProgressHUD.showAdded(to: self.contentView, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.label.text = "正在加载视频..."
        
        TCUtil.downloadVideo(playUrl, process: { (process) in
            self.onloadVideoProcess(process: process)
        }) { (videoPath) in
            self.onloadVideoComplete(videoPath!)
        }
    }
    
    
    func onloadVideoProcess(process:CGFloat) {
        hud?.label.text = String(format: "正在加载视频%d%%", (Int)(process * 100))
    }
    
    func onloadVideoComplete(_ videoPath:String) {
        player?.pause()
        hud?.hide(animated: true)
        self.delegate?.onloadVideoComplete(videoPath)
    }
    
    // MARK: Properties
    var delegate:TCPlayDecorateDelegate?

    @IBOutlet weak var centerLabel: UILabel!
    @IBOutlet weak var playDuration: UILabel!
    @IBOutlet weak var playLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    @IBOutlet weak var btnChorus: UIButton!
    @IBOutlet weak var btnLog: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var cover: UIView!
    @IBOutlet weak var statusView: UITextView!
    @IBOutlet weak var logViewEvt: UITextView!
    @IBOutlet weak var videoCoverView: UIImageView!
    @IBOutlet weak var videoParentView: UIView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var playProgress: UISlider!
    @IBOutlet weak var closeButton: UIButton!
    
    func setLiveInfo(liveInfo: TCLiveInfo) {
//        videoCoverView.image = UIImage(named: "bg.jpg")
        // play
        playUrl = liveInfo.playurl
        player = AVPlayer(url: URL(string: playUrl!)!)
        player?.play()
    }

    static let reuseIdentifier = "TCPlayViewCell"

    /// The `UUID` for the data this cell is presenting.
    var representedId: UUID?

    // MARK: UICollectionViewCell

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.borderWidth = 0
        layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
    }

    // MARK: Convenience

    /**
     Configures the cell for display based on the model.
     
     - Parameters:
         - data: An optional `DisplayData` object to display.
     
     - Tag: Cell_Config
    */
    func configure(with data: DisplayData?) {
        backgroundColor = data?.color
    }
}

//
//- (void)awakeFromNib {
//    [super awakeFromNib];
//    // Initialization code
//
//    self.contentView.frame = [UIScreen mainScreen].bounds;
//
//    [self initWithFrame:self.contentView.bounds];
//    }
//
//    - (void)prepareForReuse
//        {
//            [super prepareForReuse];
//            [_topView cancelImageLoading];
//}
//
//-(void)setLiveInfo:(TCLiveInfo *)liveInfo
//{
//    [_videoParentView removeAllSubViews];
//    ReviewStatus reviewStatus = liveInfo.reviewStatus;
//    switch (reviewStatus) {
//    case ReviewStatus_Normal:
//    {
//        if (liveInfo.userinfo.frontcoverImage) {
//            [_videoCoverView setImage:liveInfo.userinfo.frontcoverImage];
//        }else{
//            [_videoCoverView sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:liveInfo.userinfo.frontcover]] placeholderImage:[UIImage imageNamed:@"bg.jpg"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                liveInfo.userinfo.frontcoverImage = image;
//                }];
//        }
//        _reviewLabel.text = @"";
//        _btnChorus.hidden = NO;
//    }
//    break;
//    case ReviewStatus_NotReivew:
//    {
//        [_videoCoverView setImage:[UIImage imageNamed:@"bg.jpg"]];
//        _reviewLabel.text = @"视频未审核";
//        _btnChorus.hidden = YES;
//    }
//    break;
//    case ReviewStatus_Porn:
//    {
//        [_videoCoverView setImage:[UIImage imageNamed:@"bg.jpg"]];
//        _reviewLabel.text = @"视频涉黄";
//        _btnChorus.hidden = YES;
//    }
//    break;
//    default:
//        break;
//    }
//
//    _liveInfo   = liveInfo;
//    _topView.hostFaceUrl = liveInfo.userinfo.headpic;
//    _topView.hostNickName = liveInfo.userinfo.nickname;
//    [_playProgress setValue:0];
//}
//
//-(void)setPlayLabelText:(NSString *)text
//{
//    [_playLabel setText:text];
//}
//
//-(void)setPlayProgress:(CGFloat)progress
//{
//    [_playProgress setValue:progress];
//}
//
//-(void)setPlayBtnImage:(UIImage *)image
//{
//    [_playBtn setImage:image forState:UIControlStateNormal];
//}
//
//
//-(instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogout:) name:logoutNotification object:nil];
//        UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickScreen:)];
//        [self addGestureRecognizer:tap];
//        [self initUI: NO];
//    }
//    return self;
//    }
//
//
//    - (void)dealloc {
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//        }
//
//        - (void)initUI:(BOOL)linkmic {
//
//            //topview,展示主播头像，在线人数及点赞
//            _topView = [[TCShowLiveTopView alloc] initWithFrame:CGRectMake(5, 25, 35, 35)
//                hostNickName:_liveInfo.userinfo.nickname == nil ? _liveInfo.userid : _liveInfo.userinfo.nickname
//                hostFaceUrl:_liveInfo.userinfo.headpic];
//            _topView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//            [self addSubview:_topView];
//
//            //举报
//            UIButton *reportBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//            [reportBtn setFrame:CGRectMake(_topView.right + 15, _topView.top + 5, 150, 30)];
//            [reportBtn setTitle:@"举报/不感兴趣/拉黑" forState:UIControlStateNormal];
//            reportBtn.titleLabel.font = [UIFont systemFontOfSize:13];
//            [reportBtn  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [reportBtn setBackgroundColor:[UIColor blackColor]];
//            [reportBtn addTarget:self action:@selector(onReportClick) forControlEvents:UIControlEventTouchUpInside];
//            [reportBtn setAlpha:0.7];
//            reportBtn.layer.cornerRadius = 15;
//            reportBtn.layer.masksToBounds = YES;
//            reportBtn.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//
//            [self addSubview:reportBtn];
//
//            //合唱
//            _btnChorus.layer.cornerRadius = _btnChorus.width / 2.0;
//
//            [_btnShare setImage:[UIImage imageNamed:@"share_pressed"] forState:UIControlStateHighlighted];
//
//            [_playProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
//
//
//            _actionSheet1 = [[UIActionSheet alloc] init];
//            _actionSheet2 = [[UIActionSheet alloc] init];
//}
//
//-(void)onReportClick{
//    __weak __typeof(self) ws = self;
//    [_actionSheet1 bk_addButtonWithTitle:@"举报" handler:^{
//        [ws reportUser];
//        }];
//    [_actionSheet1 bk_addButtonWithTitle:@"减少类似作品" handler:^{
//        [ws confirmReportUser];
//        [[HUDHelper sharedInstance] tipMessage:@"以后会减少类似作品"];
//        }];
//    [_actionSheet1 bk_addButtonWithTitle:@"加入黑名单" handler:^{
//        [ws confirmReportUser];
//        [[HUDHelper sharedInstance] tipMessage:@"已加入黑名单"];
//        }];
//    [_actionSheet1 bk_setCancelButtonWithTitle:@"取消" handler:nil];
//    [_actionSheet1 showInView:self];
//    }
//
//    - (void)reportUser{
//        [_actionSheet1 setHidden:YES];
//        __weak __typeof(self) ws = self;
//        _actionSheet2.title = @"请选择分类，分类越准，处理越快。";
//        [_actionSheet2 bk_addButtonWithTitle:@"违法违规" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"色情低俗" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"标题党、封面党、骗点击" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"未成年人不适当行为" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"制售假冒伪劣商品" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"滥用作品" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_addButtonWithTitle:@"泄漏我的隐私" handler:^{
//            [ws confirmReportUser];
//            [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
//            }];
//        [_actionSheet2 bk_setCancelButtonWithTitle:@"取消" handler:^{
//            [_actionSheet1 showInView:self];
//            }];
//        [_actionSheet2 showInView:self];
//        }
//
//        - (void)confirmReportUser{
//            TCUserInfoData  *userInfoData = [[TCUserInfoModel sharedInstance] getUserProfile];
//            NSDictionary* params = @{@"userid" : TC_PROTECT_STR(_liveInfo.userid), @"hostuserid" : TC_PROTECT_STR(userInfoData.identifier)};
//            __weak __typeof(self) weakSelf = self;
//            [TCUtil asyncSendHttpRequest:@"report_user" token:nil params:params handler:^(int resultCode, NSString *message, NSDictionary *resultDict) {
//                [weakSelf performSelector:@selector(onLogout:) withObject:nil afterDelay:1];
//                }];
//            }
//
//            - (IBAction)clickChorus:(UIButton *)button {
//                if (self.delegate) [self.delegate clickChorus:button];
//                }
//
//                - (IBAction)clickLog:(UIButton *)button {
//                    if (self.delegate) [self.delegate clickLog:button];
//                    }
//
//                    - (IBAction)clickShare:(UIButton *)button {
//                        if (self.delegate) [self.delegate clickShare:button];
//                        }
//
//
//                        // 监听登出消息
//                        - (void)onLogout:(NSNotification*)notice {
//                            [[NSNotificationCenter defaultCenter] removeObserver:self];
//                            [self.delegate closeVC:YES popViewController:YES];
//}
//
//#pragma mark TCPlayDecorateDelegate
//-(void)closeVC{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(closeVC:popViewController:)]) {
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//        [self.delegate closeVC:NO popViewController:YES];
//    }
//    }
//
//    - (IBAction)closeVC2:(id)sender {
//        [self closeVC];
//}
//
//-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(clickScreen:)]) {
//        [self.delegate clickScreen:gestureRecognizer];
//    }
//    }
//
//    - (IBAction)clickPlayVod:(id)sender {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(clickPlayVod)]) {
//            [self.delegate clickPlayVod];
//        }
//        }
//
//        - (IBAction)onSeek:(UISlider *)slider {
//            if (self.delegate && [self.delegate respondsToSelector:@selector(onSeek:)]) {
//                [self.delegate onSeek:slider];
//            }
//            }
//
//
//            - (IBAction)onSeekBegin:(UISlider *)slider {
//                if (self.delegate && [self.delegate respondsToSelector:@selector(onSeekBegin:)]) {
//                    [self.delegate onSeekBegin:slider];
//                }
//                }
//
//                - (IBAction)onDrag:(UISlider *)slider {
//                    if (self.delegate && [self.delegate respondsToSelector:@selector(onDrag:)]) {
//                        [self.delegate onDrag:slider];
//                    }
//}
//
//
//#pragma mark - 滑动隐藏界面UI
//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [[event allTouches] anyObject];
//    _touchBeginLocation = [touch locationInView:self];
//}
//
//-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint location = [touch locationInView:self];
//    [self endMove:location.x - _touchBeginLocation.x];
//}
//
//
//-(void)endMove:(CGFloat)moveX{
//    [UIView animateWithDuration:0.2 animations:^{
//        if(moveX > 10){
//        for (UIView *view in self.subviews) {
//        if (![view isEqual:_closeButton]) {
//        CGRect rect = view.frame;
//        if (rect.origin.x >= 0 && rect.origin.x < SCREEN_WIDTH) {
//        rect = CGRectOffset(rect, self.width, 0);
//        view.frame = rect;
//        [self resetViewAlpha:view];
//        }
//        }
//        }
//        }else if(moveX < -10){
//        for (UIView *view in self.subviews) {
//        if (![view isEqual:_closeButton]) {
//        CGRect rect = view.frame;
//        if (rect.origin.x >= SCREEN_WIDTH) {
//        rect = CGRectOffset(rect, -self.width, 0);
//        view.frame = rect;
//        [self resetViewAlpha:view];
//        }
//
//        }
//        }
//        }
//        }];
//}
//
//-(void)resetViewAlpha:(UIView *)view{
//    CGRect rect = view.frame;
//    if (rect.origin.x  >= SCREEN_WIDTH || rect.origin.x < 0) {
//        view.alpha = 0;
//        _viewsHidden = YES;
//    }else{
//        view.alpha = 1;
//        _viewsHidden = NO;
//    }
//    if (view == _cover)
//    _cover.alpha = 0.5;
//}
//
//@end
//
//
//#import <UIImageView+WebCache.h>
//#import "UIImage+Additions.h"
//#import "UIView+CustomAutoLayout.h"
//
//@implementation TCShowLiveTopView
//{
//    UIImageView          *_hostImage;        // 主播头像
//
//    NSInteger            _startTime;
//
//    NSString             *_hostNickName;     // 主播昵称
//    NSString             *_hostFaceUrl;      // 头像地址
//    }
//
//    - (instancetype)initWithFrame:(CGRect)frame hostNickName:(NSString *)hostNickName hostFaceUrl:(NSString *)hostFaceUrl {
//        if (self = [super initWithFrame: frame]) {
//            _hostNickName = hostNickName;
//            _hostFaceUrl = hostFaceUrl;
//
//            self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
//            self.layer.cornerRadius = frame.size.height / 2;
//            self.layer.masksToBounds = YES;
//            [self initUI];
//        }
//        return self;
//        }
//
//        - (void)setHostFaceUrl:(NSString *)hostFaceUrl
//{
//    _hostFaceUrl = hostFaceUrl;
//    [_hostImage sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:_hostFaceUrl]] placeholderImage:[UIImage imageNamed:@"default_user"]];
//    }
//
//    - (void)cancelImageLoading
//        {
//            [_hostImage sd_setImageWithURL:nil];
//        }
//
//        - (void)initUI {
//            CGRect imageFrame = self.bounds;
//            imageFrame.origin.x = 1;
//            imageFrame.size.height -= 2;
//            imageFrame.size.width = imageFrame.size.height;
//            _hostImage = [[UIImageView alloc] initWithFrame:imageFrame];
//            _hostImage.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//            _hostImage.layer.cornerRadius = (imageFrame.size.height - 2) / 2;
//            _hostImage.layer.masksToBounds = YES;
//            _hostImage.contentMode = UIViewContentModeScaleAspectFill;
//            [_hostImage sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:_hostFaceUrl]] placeholderImage:[UIImage imageNamed:@"default_user"]];
//            [self addSubview:_hostImage];
//
//            // relayout
//            //    [_hostImage sizeWith:CGSizeMake(33, 33)];
//            //    [_hostImage layoutParentVerticalCenter];
//            //    [_hostImage alignParentLeftWithMargin:1];
//}
