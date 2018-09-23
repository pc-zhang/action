//
//  TCPlayViewCell.h
//  TXXiaoShiPinDemo
//
//  Created by xiang zhang on 2018/2/2.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCLiveListModel.h"

@protocol TCPlayDecorateDelegate <NSObject>
-(void)closeVC:(BOOL)isRefresh  popViewController:(BOOL)popViewController;
-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer;
-(void)clickPlayVod;
-(void)onSeek:(UISlider *)slider;
-(void)onSeekBegin:(UISlider *)slider;
-(void)onDrag:(UISlider *)slider;
-(void)clickLog:(UIButton *)button;
-(void)clickShare:(UIButton *)button;
-(void)clickChorus:(UIButton *)button;
@end

@interface TCPlayViewCell : UITableViewCell<TCPlayDecorateDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *centerLabel;
@property (weak, nonatomic) IBOutlet UILabel *playDuration;
@property (weak, nonatomic) IBOutlet  UILabel            *playLabel;
@property (weak, nonatomic) IBOutlet  UIButton           *playBtn;
@property (weak, nonatomic) IBOutlet  UIButton           *btnChat;
@property (weak, nonatomic) IBOutlet  UIButton           *btnChorus;
@property (weak, nonatomic) IBOutlet  UIButton           *btnLog;
@property (weak, nonatomic) IBOutlet  UIButton           *btnShare;
@property (weak, nonatomic) IBOutlet  UIView             *cover;
@property (weak, nonatomic) IBOutlet  UITextView         *statusView;
@property (weak, nonatomic) IBOutlet  UITextView         *logViewEvt;
@property (weak, nonatomic) IBOutlet UIImageView* videoCoverView;
@property (weak, nonatomic) IBOutlet UIView* videoParentView;
@property (weak, nonatomic) IBOutlet UILabel* reviewLabel;
@property (weak, nonatomic) IBOutlet UISlider *playProgress;


@property(weak,nonatomic)   id<TCPlayDecorateDelegate>delegate;
-(void)setLiveInfo:(TCLiveInfo *)liveInfo;
@end


@interface TCShowLiveTopView : UIView
@property (strong, nonatomic) NSString *hostNickName;
@property (strong, nonatomic) NSString *hostFaceUrl;

- (instancetype)initWithFrame:(CGRect)frame hostNickName:(NSString *)hostNickName hostFaceUrl:(NSString *)hostFaceUrl;

- (void)cancelImageLoading;
@end
