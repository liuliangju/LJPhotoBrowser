//
//  LJTapDetectingImageView.h
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/8/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "FLAnimatedImageView.h"

@protocol LJTapDetectingImageViewDelegate;

@interface LJTapDetectingImageView : FLAnimatedImageView

@property (nonatomic, weak) id <LJTapDetectingImageViewDelegate> tapDelegate;

@end

@protocol LJTapDetectingImageViewDelegate <NSObject>

@optional

- (void)imageView:(FLAnimatedImageView *)imageView singleTapDetected:(UITapGestureRecognizer *)tap;
- (void)imageView:(FLAnimatedImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)tap;
- (void)imageView:(FLAnimatedImageView *)imageView LongTapDetected:(UILongPressGestureRecognizer *)tap;

@end
