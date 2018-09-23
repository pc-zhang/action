//
//  TCVodPlayViewController.h
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/9/15.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "SDKHeader.h"
#import "TCPlayViewCell.h"
#import "TCLiveListModel.h"

typedef void(^videoIsReadyBlock)(void);
extern NSString *const kTCLivePlayError;

@interface TCVodPlayViewController : UIViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate, TXVodPlayListener,TCPlayDecorateDelegate>

@property (nonatomic, assign) BOOL  log_switch;
@property  TCLiveInfo           *liveInfo;
@property (nonatomic, copy)   videoIsReadyBlock   videoIsReady;

-(id)initWithPlayInfoS:(NSArray<TCLiveInfo *>*) liveInfos  liveInfo:(TCLiveInfo *)liveInfo videoIsReady:(videoIsReadyBlock)videoIsReady;

- (void)stopRtmp;

- (void)onAppDidEnterBackGround:(UIApplication*)app;

- (void)onAppWillEnterForeground:(UIApplication*)app;

@end
