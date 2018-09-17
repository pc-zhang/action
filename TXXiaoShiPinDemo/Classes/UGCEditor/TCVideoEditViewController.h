//
//  TCVideoEditViewController.h
//  TCLVBIMDemo
//
//  Created by xiang zhang on 2017/4/10.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoCutView.h"
#import "VideoPreview.h"

@interface TCVideoEditViewController : UIViewController

@property (strong,nonatomic) NSString *videoPath;

@property (strong,nonatomic) AVAsset  *videoAsset;

@property (strong,nonatomic) VideoCutView* videoCutView;       //裁剪
@property (strong,nonatomic) UIImageView* flagView;
@property (strong,nonatomic) VideoPreview* videoPreview;   //视频预览
@property (strong,nonatomic) UILabel* timeLabel;
@property (strong,nonatomic) UIButton* deleteBtn;
@property (strong,nonatomic,readonly) UIButton* playBtn;


//从剪切过来
@property (assign,nonatomic) BOOL     isFromCut;

//从合唱过来
@property (assign,nonatomic) BOOL     isFromChorus;
@end
