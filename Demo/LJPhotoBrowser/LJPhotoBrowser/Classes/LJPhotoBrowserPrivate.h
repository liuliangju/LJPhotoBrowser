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
#import "LJBrowserHelper.h"
#import "FLAnimatedImageView.h"


typedef NS_ENUM(NSInteger, LJOriginalLoadState) {
    LJPhotoBrowser_willLoad = 1,
    LJPhotoBrowser_loading = 2,
    LJPhotoBrowser_cancelLoad = 3,
    LJPhotoBrowser_LoadFail = 4
};

@interface LJPhotoBrowser () {
    
    // Data
    NSUInteger _photoCount;
    NSMutableArray *_photos;
    NSMutableArray *_thumbPhotos;
    NSArray *_fixedPhotosArray; // Provided via init

    // Views
    UIScrollView *_pagingScrollView;
    UIView *_backgroundView;           // The false background of the false at the beginning
    FLAnimatedImageView *_avatarImageView;     // The false background‘s ImageView at the beginning
    
    // Paging & layout
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
    CGRect _previousLayoutBounds;
    NSUInteger _pageIndexBeforeRotation;
    
    // Navigation & controls
    NSTimer *_controlVisibilityTimer;
    BOOL *_isHiddenNavBarHidden;
    UIBarButtonItem *_previousButton, *_nextButton, *_doneButton;
    MBProgressHUD *_progressHUD;

    // Appearance
    BOOL _previousNavBarHidden;
    BOOL _previousNavBarTranslucent;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIColor *_previousNavBarTintColor;
    UIColor *_previousNavBarBarTintColor;
    UIImage *_previousNavigationBarBackgroundImageDefault;
    UIImage *_previousNavigationBarBackgroundImageLandscapePhone;
    UIBarButtonItem *_previousViewControllerBackButton;

    // Video
    MPMoviePlayerViewController *_currentVideoPlayerViewController;
    NSUInteger _currentVideoIndex;
    UIActivityIndicatorView *_currentVideoLoadingIndicator;
    
    // Original image
    NSUInteger _currentOriginalIndex;


    
    // Misc
    BOOL _hasBelongedToViewController;
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _statusBarShouldBeHidden;
    BOOL _leaveStatusBarAlone;
    BOOL _performingLayout;
    BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _didSavePreviousStateOfNavBar;
    BOOL _skipNextPagingScrollViewPositioning;
    BOOL _viewHasAppearedInitially;
    BOOL _isWindow;    // whether to adopt the Window as a background
    CGPoint _currentGridContentOffset;
}

@property (nonatomic, strong) UIWindow *overlayWindow;  // Full screen window
@property (nonatomic, strong) UIButton *originalBtn;
@property (nonatomic, assign) LJOriginalLoadState loadingState;    // 图片加载状态



// Layout
- (void)layoutVisiblePages;
- (void)performLayout;
- (BOOL)presentingViewControllerPrefersStatusBarHidden;

// Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated;
- (void)storePreviousNavBarAppearance;
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (LJZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (LJZoomingScrollView *)pageDisplayingPhoto:(LJPhoto *)photo;
- (LJZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(LJZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;


// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)gotoPreviousPage;
- (void)gotoNextPage;



// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls:(LJPhoto *)photo;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (LJPhoto *)photoAtIndex:(NSUInteger)index;
- (LJPhoto *)thumbPhotoAtIndex:(NSUInteger)index;
- (id)imageForPhoto:(LJPhoto *)photo;
- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index;
- (void)loadAdjacentPhotosIfNecessary:(LJPhoto *)photo;
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;


@end



