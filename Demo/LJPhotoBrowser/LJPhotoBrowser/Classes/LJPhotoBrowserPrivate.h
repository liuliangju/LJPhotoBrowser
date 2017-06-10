//
//  LJPhotoBrowserPrivate.h
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/10/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//



#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LJZoomingScrollView.h"

@interface LJPhotoBrowser () {
    
    // Data
    NSUInteger _photoCount;
    NSMutableArray *_photos;
    NSArray *_fixedPhotosArray; // Provided via init

    // Views
    UIScrollView *_pagingScrollView;
    
    // Paging & layout
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
    CGRect _previousLayoutBounds;
    NSUInteger _pageIndexBeforeRotation;
    
    // Navigation & controls
    NSTimer *_controlVisibilityTimer;
    MBProgressHUD *_progressHUD;

    
    // Video
    MPMoviePlayerViewController *_currentVideoPlayerViewController;
    NSUInteger _currentVideoIndex;
    UIActivityIndicatorView *_currentVideoLoadingIndicator;
    
    // Misc
    BOOL _hasBelongedToViewController;
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _performingLayout;
    BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _skipNextPagingScrollViewPositioning;
    BOOL _viewHasAppearedInitially;
    CGPoint _currentGridContentOffset;
}

// Layout
- (void)layoutVisiblePages;
- (void)performLayout;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (LJZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (LJZoomingScrollView *)pageDisplayingPhoto:(id<LJPhoto>)photo;
- (LJZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(LJZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;


// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;


// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (id<LJPhoto>)photoAtIndex:(NSUInteger)index;
- (id<LJPhoto>)thumbPhotoAtIndex:(NSUInteger)index;
- (id)imageForPhoto:(id<LJPhoto>)photo;
- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index;
- (void)setPhotoSelected:(BOOL)selected atIndex:(NSUInteger)index;
- (void)loadAdjacentPhotosIfNecessary:(id<LJPhoto>)photo;
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;


@end



