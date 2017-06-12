//
//  LJTapDetectingView.h
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/8/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LJTapDetectingViewDelegate;

@interface LJTapDetectingView : UIView

@property (nonatomic, weak) id <LJTapDetectingViewDelegate> tapDelegate;

@end

@protocol LJTapDetectingViewDelegate <NSObject>

@optional

- (void)view:(UIView *)view singleTapDetected:(UITapGestureRecognizer *)tap;
- (void)view:(UIView *)view doubleTapDetected:(UITapGestureRecognizer *)tap;
- (void)view:(UIView *)view LongTapDetected:(UILongPressGestureRecognizer *)tap;

@end
