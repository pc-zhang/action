//
//  BeautySettingPanel.h
//  RTMPiOSDemo
//
//  Created by rushanting on 2017/5/5.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDKHeader.h"

typedef NS_ENUM(NSInteger,DemoFilterType) {
    FilterType_None 		= 0,
    FilterType_white        ,   //美白滤镜
    FilterType_langman 		,   //浪漫滤镜
    FilterType_qingxin 		,   //清新滤镜
    FilterType_weimei 		,   //唯美滤镜
    FilterType_fennen 		,   //粉嫩滤镜
    FilterType_huaijiu 		,   //怀旧滤镜
    FilterType_landiao 		,   //蓝调滤镜
    FilterType_qingliang    ,   //清凉滤镜
    FilterType_rixi 		,   //日系滤镜
};

@protocol BeautySettingPanelDelegate <NSObject>
- (void)onSetBeautyStyle:(TXVideoBeautyStyle)beautyStyle beautyLevel:(float)beautyLevel whitenessLevel:(float)whitenessLevel ruddinessLevel:(float)ruddinessLevel;
- (void)onSetMixLevel:(float)mixLevel;
- (void)onSetEyeScaleLevel:(float)eyeScaleLevel;
- (void)onSetFaceScaleLevel:(float)faceScaleLevel;
- (void)onSetFaceBeautyLevel:(float)beautyLevel;
- (void)onSetFaceVLevel:(float)vLevel;
- (void)onSetChinLevel:(float)chinLevel;
- (void)onSetFaceShortLevel:(float)shortLevel;
- (void)onSetNoseSlimLevel:(float)slimLevel;
- (void)onSetFilter:(UIImage*)filterImage;
- (void)onSetGreenScreenFile:(NSURL *)file;
- (void)onSelectMotionTmpl:(NSString *)tmplName inDir:(NSString *)tmplDir;

@end

@protocol BeautyLoadPituDelegate <NSObject>
- (void)onLoadPituStart;
- (void)onLoadPituProgress:(CGFloat)progress;
- (void)onLoadPituFinished;
- (void)onLoadPituFailed;
@end

@interface BeautySettingPanel : UIView

@property (nonatomic, weak) id<BeautySettingPanelDelegate> delegate;
@property (nonatomic, weak) id<BeautyLoadPituDelegate> pituDelegate;

- (void)resetValues;
+ (NSUInteger)getHeight;
- (void)changeFunction:(NSInteger)i;

@end
