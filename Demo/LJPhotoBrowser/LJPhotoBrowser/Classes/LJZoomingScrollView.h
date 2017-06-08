//
//  LJZoomingScrollView.h
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/9/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LJPhotoBrowser, LJPhoto;

@interface LJZoomingScrollView : UIScrollView

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) LJPhoto *photo;

- (instancetype)initWithPhotoBrowser:(LJPhotoBrowser *)browser;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;


@end
