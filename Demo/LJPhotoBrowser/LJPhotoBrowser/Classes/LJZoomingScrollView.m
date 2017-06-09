//
//  LJZoomingScrollView.m
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/9/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJZoomingScrollView.h"
#import "LJPhotoProtocol.h"
#import "LJTapDetectingImageView.h"
#import "LJTapDetectingView.h"

#import "LJPhotoBrowser.h"
#import "LJPhoto.h"
#import "DACircularProgressView.h"
//#import "LJPhotoBrowserPrivate.h"
#import "LJCommonMacro.h"


@interface LJZoomingScrollView () <UIScrollViewDelegate, LJTapDetectingImageViewDelegate, LJTapDetectingViewDelegate> {
    LJPhotoBrowser __weak *_photoBrowser;
    LJTapDetectingView *_tapView;
    LJTapDetectingImageView *_photoImageView;
    DACircularProgressView *_loadingIndicator;
    UIImageView *_loadingError;
}

@end

@implementation LJZoomingScrollView

- (instancetype)initWithPhotoBrowser:(LJPhotoBrowser *)browser {
    self = [super init];
    if (self) {
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        
        // Tap view for background
        _tapView = [[LJTapDetectingView alloc]initWithFrame:self.bounds];
        _tapView.tapDelegate = self;
        _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tapView.backgroundColor = [UIColor blackColor];
        [self addSubview:_tapView];

        // Image view
        _photoImageView = [[LJTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_photoImageView];
        
        // Loading indicator
        _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        _loadingIndicator.userInteractionEnabled = NO;
        _loadingIndicator.thicknessRatio = 0.1;
        _loadingIndicator.roundedCorners = NO;
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_loadingIndicator];
        
        // Listen progress notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:LJPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];
        
        // Setup
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {
    if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [_photo cancelAnyLoading];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
