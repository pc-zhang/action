//
//  TCPlayDecorateView.m
//  TCLVBIMDemo
//
//  Created by zhangxiang on 16/8/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIImageView+WebCache.h>
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "UIActionSheet+BlocksKit.h"
#import "TCUserInfoModel.h"
#import "TCLoginModel.h"
#import "TCConstants.h"
#import "TCLiveListModel.h"
#import "HUDHelper.h"
#import <UShareUI/UMSocialUIManager.h>
#import <UMSocialCore/UMSocialCore.h>

#import "TCPlayViewCell.h"
#import "UIImageView+WebCache.h"

#define FULL_SCREEN_PLAY_VIDEO_VIEW     10000
#define BOTTOM_BTN_ICON_WIDTH  35

@implementation TCPlayViewCell
{
    TCLiveInfo         *_liveInfo;
    CGPoint            _touchBeginLocation;
    BOOL               _bulletBtnIsOn;
    BOOL               _viewsHidden;
    NSMutableArray     *_heartAnimationPoints;
    
    TCShowLiveTopView  *_topView;
    
    UIActionSheet      *_actionSheet1;
    UIActionSheet      *_actionSheet2;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.contentView.frame = [UIScreen mainScreen].bounds;

    [self initWithFrame:self.contentView.bounds];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_topView cancelImageLoading];
}

-(void)setLiveInfo:(TCLiveInfo *)liveInfo
{
    [_videoParentView removeAllSubViews];
    ReviewStatus reviewStatus = liveInfo.reviewStatus;
    switch (reviewStatus) {
        case ReviewStatus_Normal:
        {
            if (liveInfo.userinfo.frontcoverImage) {
                [_videoCoverView setImage:liveInfo.userinfo.frontcoverImage];
            }else{
                [_videoCoverView sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:liveInfo.userinfo.frontcover]] placeholderImage:[UIImage imageNamed:@"bg.jpg"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    liveInfo.userinfo.frontcoverImage = image;
                }];
            }
            _reviewLabel.text = @"";
            _btnChorus.hidden = NO;
        }
            break;
        case ReviewStatus_NotReivew:
        {
            [_videoCoverView setImage:[UIImage imageNamed:@"bg.jpg"]];
            _reviewLabel.text = @"视频未审核";
            _btnChorus.hidden = YES;
        }
            break;
        case ReviewStatus_Porn:
        {
            [_videoCoverView setImage:[UIImage imageNamed:@"bg.jpg"]];
            _reviewLabel.text = @"视频涉黄";
            _btnChorus.hidden = YES;
        }
            break;
        default:
            break;
    }

    _liveInfo   = liveInfo;
    _topView.hostFaceUrl = liveInfo.userinfo.headpic;
    _topView.hostNickName = liveInfo.userinfo.nickname;
    [_playProgress setValue:0];
}

-(void)setPlayLabelText:(NSString *)text
{
    [_playLabel setText:text];
}

-(void)setPlayProgress:(CGFloat)progress
{
    [_playProgress setValue:progress];
}

-(void)setPlayBtnImage:(UIImage *)image
{
    [_playBtn setImage:image forState:UIControlStateNormal];
}


-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogout:) name:logoutNotification object:nil];
        UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickScreen:)];
        [self addGestureRecognizer:tap];
        [self initUI: NO];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initUI:(BOOL)linkmic {
    
    //topview,展示主播头像，在线人数及点赞
    _topView = [[TCShowLiveTopView alloc] initWithFrame:CGRectMake(5, 25, 35, 35)
                                           hostNickName:_liveInfo.userinfo.nickname == nil ? _liveInfo.userid : _liveInfo.userinfo.nickname
                                            hostFaceUrl:_liveInfo.userinfo.headpic];
    _topView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_topView];
    
    //举报
    UIButton *reportBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [reportBtn setFrame:CGRectMake(_topView.right + 15, _topView.top + 5, 150, 30)];
    [reportBtn setTitle:@"举报/不感兴趣/拉黑" forState:UIControlStateNormal];
    reportBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [reportBtn  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [reportBtn setBackgroundColor:[UIColor blackColor]];
    [reportBtn addTarget:self action:@selector(onReportClick) forControlEvents:UIControlEventTouchUpInside];
    [reportBtn setAlpha:0.7];
    reportBtn.layer.cornerRadius = 15;
    reportBtn.layer.masksToBounds = YES;
    reportBtn.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self addSubview:reportBtn];
    
    //合唱
    _btnChorus.layer.cornerRadius = _btnChorus.width / 2.0;
    
    [_btnShare setImage:[UIImage imageNamed:@"share_pressed"] forState:UIControlStateHighlighted];

    [_playProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];

    
    _actionSheet1 = [[UIActionSheet alloc] init];
    _actionSheet2 = [[UIActionSheet alloc] init];
}

-(void)onReportClick{
    __weak __typeof(self) ws = self;
    [_actionSheet1 bk_addButtonWithTitle:@"举报" handler:^{
        [ws reportUser];
    }];
    [_actionSheet1 bk_addButtonWithTitle:@"减少类似作品" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"以后会减少类似作品"];
    }];
    [_actionSheet1 bk_addButtonWithTitle:@"加入黑名单" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"已加入黑名单"];
    }];
    [_actionSheet1 bk_setCancelButtonWithTitle:@"取消" handler:nil];
    [_actionSheet1 showInView:self];
}

- (void)reportUser{
    [_actionSheet1 setHidden:YES];
    __weak __typeof(self) ws = self;
    _actionSheet2.title = @"请选择分类，分类越准，处理越快。";
    [_actionSheet2 bk_addButtonWithTitle:@"违法违规" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"色情低俗" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"标题党、封面党、骗点击" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"未成年人不适当行为" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"制售假冒伪劣商品" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"滥用作品" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_addButtonWithTitle:@"泄漏我的隐私" handler:^{
        [ws confirmReportUser];
        [[HUDHelper sharedInstance] tipMessage:@"举报成功，我们将在24小时内进行处理"];
    }];
    [_actionSheet2 bk_setCancelButtonWithTitle:@"取消" handler:^{
        [_actionSheet1 showInView:self];
    }];
    [_actionSheet2 showInView:self];
}

- (void)confirmReportUser{
    TCUserInfoData  *userInfoData = [[TCUserInfoModel sharedInstance] getUserProfile];
    NSDictionary* params = @{@"userid" : TC_PROTECT_STR(_liveInfo.userid), @"hostuserid" : TC_PROTECT_STR(userInfoData.identifier)};
    __weak __typeof(self) weakSelf = self;
    [TCUtil asyncSendHttpRequest:@"report_user" token:nil params:params handler:^(int resultCode, NSString *message, NSDictionary *resultDict) {
        [weakSelf performSelector:@selector(onLogout:) withObject:nil afterDelay:1];
    }];
}

- (IBAction)clickChorus:(UIButton *)button {
    if (self.delegate) [self.delegate clickChorus:button];
}

- (IBAction)clickLog:(UIButton *)button {
    if (self.delegate) [self.delegate clickLog:button];
}

- (IBAction)clickShare:(UIButton *)button {
    if (self.delegate) [self.delegate clickShare:button];
}


// 监听登出消息
- (void)onLogout:(NSNotification*)notice {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.delegate closeVC:YES popViewController:YES];
}

#pragma mark TCPlayDecorateDelegate
-(void)closeVC{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeVC:popViewController:)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.delegate closeVC:NO popViewController:YES];
    }
}

- (IBAction)closeVC2:(id)sender {
    [self closeVC];
}

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickScreen:)]) {
        [self.delegate clickScreen:gestureRecognizer];
    }
}

- (IBAction)clickPlayVod:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickPlayVod)]) {
        [self.delegate clickPlayVod];
    }
}

- (IBAction)onSeek:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSeek:)]) {
        [self.delegate onSeek:slider];
    }
}


- (IBAction)onSeekBegin:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSeekBegin:)]) {
        [self.delegate onSeekBegin:slider];
    }
}

- (IBAction)onDrag:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDrag:)]) {
        [self.delegate onDrag:slider];
    }
}


#pragma mark - 滑动隐藏界面UI
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    _touchBeginLocation = [touch locationInView:self];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self];
    [self endMove:location.x - _touchBeginLocation.x];
}


-(void)endMove:(CGFloat)moveX{
    [UIView animateWithDuration:0.2 animations:^{
        if(moveX > 10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:_closeButton]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= 0 && rect.origin.x < SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                }
            }
        }else if(moveX < -10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:_closeButton]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, -self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                    
                }
            }
        }
    }];
}

-(void)resetViewAlpha:(UIView *)view{
    CGRect rect = view.frame;
    if (rect.origin.x  >= SCREEN_WIDTH || rect.origin.x < 0) {
        view.alpha = 0;
        _viewsHidden = YES;
    }else{
        view.alpha = 1;
        _viewsHidden = NO;
    }
    if (view == _cover)
        _cover.alpha = 0.5;
}

@end


#import <UIImageView+WebCache.h>
#import "UIImage+Additions.h"
#import "UIView+CustomAutoLayout.h"

@implementation TCShowLiveTopView
{
    UIImageView          *_hostImage;        // 主播头像
    
    NSInteger            _startTime;
    
    NSString             *_hostNickName;     // 主播昵称
    NSString             *_hostFaceUrl;      // 头像地址
}

- (instancetype)initWithFrame:(CGRect)frame hostNickName:(NSString *)hostNickName hostFaceUrl:(NSString *)hostFaceUrl {
    if (self = [super initWithFrame: frame]) {
        _hostNickName = hostNickName;
        _hostFaceUrl = hostFaceUrl;
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        [self initUI];
    }
    return self;
}

- (void)setHostFaceUrl:(NSString *)hostFaceUrl
{
    _hostFaceUrl = hostFaceUrl;
    [_hostImage sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:_hostFaceUrl]] placeholderImage:[UIImage imageNamed:@"default_user"]];
}

- (void)cancelImageLoading
{
    [_hostImage sd_setImageWithURL:nil];
}

- (void)initUI {
    CGRect imageFrame = self.bounds;
    imageFrame.origin.x = 1;
    imageFrame.size.height -= 2;
    imageFrame.size.width = imageFrame.size.height;
    _hostImage = [[UIImageView alloc] initWithFrame:imageFrame];
    _hostImage.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _hostImage.layer.cornerRadius = (imageFrame.size.height - 2) / 2;
    _hostImage.layer.masksToBounds = YES;
    _hostImage.contentMode = UIViewContentModeScaleAspectFill;
    [_hostImage sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:_hostFaceUrl]] placeholderImage:[UIImage imageNamed:@"default_user"]];
    [self addSubview:_hostImage];
    
    // relayout
    //    [_hostImage sizeWith:CGSizeMake(33, 33)];
    //    [_hostImage layoutParentVerticalCenter];
    //    [_hostImage alignParentLeftWithMargin:1];
}

@end
