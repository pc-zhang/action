//
//  TCLivePusherInfo.m
//  TCLVBIMDemo
//
//  Created by lynxzhang on 16/8/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCLiveListCell.h"
#import <UIImageView+WebCache.h>
#import "UIImage+Additions.h"
#import "TCLiveListModel.h"
#import "UIView+Additions.h"
#import <sys/types.h>
#import <sys/sysctl.h>

@interface TCLiveListCell()
{
    __weak IBOutlet UIImageView *_headImageView;
    __weak IBOutlet UIImageView *_bigPicView;
    __weak IBOutlet UIImageView *_flagView;
    __weak IBOutlet UIImageView *_timeSelectView;
    __weak IBOutlet UILabel     *_titleLabel;
    __weak IBOutlet UILabel     *_nameLabel;
    __weak IBOutlet UILabel     *_locationLabel;
    __weak IBOutlet UILabel     *_timeLable;
    __weak IBOutlet UILabel     *_reviewLabel;
    __weak IBOutlet UIView      *_userMsgView;
    __weak IBOutlet UIView      *_lineView;
    UIImage     *_defaultImage;
    CGRect      _titleRect;
}

@end

@implementation TCLiveListCell

- (void)awakeFromNib{
    [super awakeFromNib];

    if (_defaultImage == nil) {
        _defaultImage = [self scaleClipImage:[UIImage imageNamed:@"bg.jpg"] clipW: [UIScreen mainScreen].bounds.size.width * 2 clipH:274 * 2 ];
    }
    
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    _headImageView.layer.cornerRadius  = _headImageView.height * 0.5;
    _headImageView.layer.masksToBounds = YES;
    _headImageView.layer.borderWidth   = 1;
    _headImageView.layer.borderColor   = kClearColor.CGColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_headImageView sd_setImageWithURL:nil];
    [_bigPicView sd_setImageWithURL:nil];
}


- (void)setModel:(TCLiveInfo *)model {
    _model = model;
    
    NSStringCheck(_model.userinfo.headpic);
    [_headImageView sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:_model.userinfo.headpic]]
                      placeholderImage:[UIImage imageNamed:@"face"]];
    
    if (_reviewLabel){
        if (_model.reviewStatus == 0) {
            _reviewLabel.text = @"未审核";
        }
        else if(_model.reviewStatus == 1){
            _reviewLabel.text = @"已审核";
        }
        else if(_model.reviewStatus == 2){
            _reviewLabel.text = @"涉黄";
        }
    }
    
    NSStringCheck(_model.title);
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:_model.title];
    [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(0, title.length)];
    _titleRect = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 15) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    if (_titleLabel) _titleLabel.attributedText = title;
   
    
    NSMutableString* name = [[NSMutableString alloc] initWithString:@""];
 
    NSStringCheck(_model.userinfo.nickname);
    if (0 == _model.userinfo.nickname.length) {
        [name appendString:_model.userid];
    }
    else {
        [name appendString:_model.userinfo.nickname];
    }
    if (_nameLabel) _nameLabel.text = name;
    if (_locationLabel) _locationLabel.text = _model.userinfo.location;
    
    //self.locationImageView.hidden = NO;
    if (_locationLabel && _locationLabel.text.length == 0) {
        _locationLabel.text = @"不显示地理位置";
    }
    
    __weak typeof(_bigPicView) weakPicView =  _bigPicView;
    [_bigPicView sd_setImageWithURL:[NSURL URLWithString:[TCUtil transImageURL2HttpsURL:model.userinfo.frontcover]] placeholderImage:_defaultImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//        UIImage *newImage = [self scaleClipImage:image clipW:_bigPicView.width clipH:_bigPicView.height];
        if (image != nil) {
            weakPicView.image = image;
            model.userinfo.frontcoverImage = image;
        }
    }];
    
    if (_flagView) {
        _flagView.image = [UIImage imageNamed:@"playback"];
    }
    
    if (_timeLable) {
        [self setTimeLable:_model.timestamp];
    }
    
    [self setNeedsLayout];
}

-(TCLiveInfo *)model{
    _model.userinfo.frontcoverImage = _bigPicView.image;
    return _model;
}

-(UIImage *)scaleClipImage:(UIImage *)image clipW:(CGFloat)clipW clipH:(CGFloat)clipH{
    UIImage *newImage = nil;
    if (image != nil) {
        if (image.size.width >=  clipW && image.size.height >= clipH) {
            newImage = [self clipImage:image inRect:CGRectMake((image.size.width - clipW)/2, (image.size.height - clipH)/2, clipW,clipH)];
        }else{
            CGFloat widthRatio = clipW / image.size.width;
            CGFloat heightRatio = clipH / image.size.height;
            CGFloat imageNewHeight = 0;
            CGFloat imageNewWidth = 0;
            UIImage *scaleImage = nil;
            if (widthRatio < heightRatio) {
                imageNewHeight = clipH;
                imageNewWidth = imageNewHeight * image.size.width / image.size.height;
                scaleImage = [self scaleImage:image scaleToSize:CGSizeMake(imageNewWidth, imageNewHeight)];
            }else{
                imageNewWidth = clipW;
                imageNewHeight = imageNewWidth * image.size.height / image.size.width;
                scaleImage = [self scaleImage:image scaleToSize:CGSizeMake(imageNewWidth, imageNewHeight)];
            }
            newImage = [self clipImage:image inRect:CGRectMake((scaleImage.size.width - clipW)/2, (scaleImage.size.height - clipH)/2, clipW,clipH)];
        }
    }
    return newImage;
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

- (void)setTimeLable:(int)timestamp {
    NSString *timeStr = @"刚刚";
    if (timestamp == 0) {
        timeStr = @"";
    } else {
        int interval = [[NSDate date] timeIntervalSince1970] - timestamp;
        
        if (interval >= 60 && interval < 3600) {
            timeStr = [[NSString alloc] initWithFormat:@"%d分钟前", interval/60];
        } else if (interval >= 3600 && interval < 60*60*24) {
            timeStr = [[NSString alloc] initWithFormat:@"%d小时前", interval/3600];
        } else if (interval >= 60*60*24 && interval < 60*60*24*365) {
            timeStr = [[NSString alloc] initWithFormat:@"%d天前", interval/3600/24];
        } else if (interval >= 60*60*24*265) {
            timeStr = [[NSString alloc] initWithFormat:@"很久前"];
        }
    }
    _timeLable.text = timeStr;
}

@end
