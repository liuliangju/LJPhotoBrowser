//
//  LJTapDetectingView.m
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/8/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJTapDetectingView.h"

@implementation LJTapDetectingView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if ([self.tapDelegate respondsToSelector:@selector(view:singleTapDetected:)]) {
        [self.tapDelegate view:self singleTapDetected:tap];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if ([self.tapDelegate respondsToSelector:@selector(view:doubleTapDetected:)]) {
        [self.tapDelegate view:self doubleTapDetected:tap];
    }
}

- (void)handleLongTap:(UILongPressGestureRecognizer *)tap {
    if ([self.tapDelegate respondsToSelector:@selector(view:LongTapDetected:)]) {
        [self.tapDelegate view:self LongTapDetected:tap];
    }
}

- (void)addTapGestureRecognizer {
    // singleTapDetected
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.delaysTouchesBegan = YES;
    singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTap];
    
    // doubleTapDetected
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    // Only double click on the failure to come into force or no testing to double click
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    
    // longTapDetected
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongTap:)];
    [self addGestureRecognizer:longTap];
}


@end
