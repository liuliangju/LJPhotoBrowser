//
//  LJPhotoBrowser.m
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJPhotoBrowser.h"
#import "LJCommonMacro.h"
#import "LJPhotoBrowserPrivate.h"

#define PADDING                  10

static void *LJVideoPlayerObservation = &LJVideoPlayerObservation;

@interface LJPhotoBrowser ()

@end

@implementation LJPhotoBrowser

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_initialisation];
    }
    return self;
}

- (void)setIsWindow:(BOOL)isWindow {
    _isWindow = isWindow;
}

- (instancetype)initWithDelegate:(id<LJPhotoBrowserDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    self = [super init];
    if (self) {
        _fixedPhotosArray = photosArray;
    }
    return self;
}

- (void)showPhotoBrowserWithFirstPhoto:(LJPhoto *)photo {
    if (photo.image) {
        self.overlayWindow.hidden = NO;
        _avatarImageView.image = photo.image;
        CGRect fromFrame = [self calcPhotoFrame:photo];
        CGRect toFrame = [self calcToFrame:photo];
        _avatarImageView.frame = fromFrame;
        
        [UIView animateWithDuration:0.9 animations:^{
            _backgroundView.alpha = 1;
            _avatarImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            //动画有问题 需要调整
            //        if ([self isVerticallLargerPhoto]) {
            //            self.avatarImageView.frame = [self verticallLargerImageViewFrame];
            //        }
            // 动画执行完了之后隐藏替身
            //        _avatarImageView.hidden = YES;
            
        }];
    } else {
        
        // photo.image 不存在直接下载图片
    }
}

// frame转换
- (CGRect)calcPhotoFrame:(LJPhoto *)photo {
    CGRect photoFrame = photo.imageFrame;
    if (CGRectEqualToRect(photoFrame, CGRectZero)) {
        return CGRectZero;
    }
    CGRect fromFrame = CGRectMake(photoFrame.origin.x, photoFrame.origin.y, photoFrame.size.width, photoFrame.size.height);
    return fromFrame;
}

- (CGRect)calcToFrame:(LJPhoto *)photo {
    CGRect toFrame = CGRectZero;
    CGFloat width = screenWidth;
    CGFloat height = screenHeight;
    UIImage *image = photo.image;
    CGFloat imageWid;
    CGFloat imageHei;
    if (image) {
        imageWid = image.size.width;
        imageHei = image.size.height;
    } else {
        imageWid = screenWidth;
        imageHei = screenHeight;
    }
    
    // 宽度固定为屏幕宽
    toFrame.size.width = width;
    toFrame.size.height = width * imageHei / imageWid;
    toFrame.origin.x = 0;
    toFrame.origin.y = (height - toFrame.size.height) / 2;
    
    // 如果缩放后的高度仍超过屏幕高则高度固定为屏幕高
    if (toFrame.size.height > height) {
        toFrame.size.height = height;
        toFrame.size.width = height * imageWid / imageHei;
        toFrame.origin.y = 0;
        toFrame.origin.x = (width - toFrame.size.width) / 2;
    }
    
    return toFrame;
}

- (void)p_initialisation {
//    if (!_isWindow) {
//        self.hidesBottomBarWhenPushed = YES;
//    }
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _currentVideoIndex = NSUIntegerMax;
    _performingLayout = NO; // Reset on view did appear
    _rotating = NO;
    _viewIsActive = NO;
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];
    _thumbPhotos = [[NSMutableArray alloc] init];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _backgroundView = [[UIView alloc] initWithFrame:kLJPhotoBrowserScreenBounds];
    _backgroundView.backgroundColor = [UIColor blackColor];
    _backgroundView.alpha = 0;
    
    // 用于查看图片的UIImageView
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.backgroundColor = [UIColor clearColor];
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    // Listen for MWPhoto notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLJPhotoLoadingDidEndNotification:)
                                                 name:LJPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];

}

- (void)p_additionalInitialisation {
    // Defaults
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum) {
        _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    } else {
        _isVCBasedStatusBarAppearance = YES; // default
    }
    
    self.hidesBottomBarWhenPushed = YES;
    _hasBelongedToViewController = NO;
}

- (void)dealloc {
//    [self clearCurrentVideo];
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self releaseAllUnderlyingPhotos:NO];
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
//    // Create a copy in case this array is modified while we are looping through
//    // Release photos
//    NSArray *copy = [_photos copy];
//    for (id p in copy) {
//        if (p != [NSNull null]) {
//            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
//                continue; // skip current
//            }
//            [p unloadUnderlyingImage];
//        }
//    }
//    // Release thumbs
//    copy = [_thumbPhotos copy];
//    for (id p in copy) {
//        if (p != [NSNull null]) {
//            [p unloadUnderlyingImage];
//        }
//    }
}



- (void)didReceiveMemoryWarning {
    
    // Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos:YES];
    [_recycledPages removeAllObjects];
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View Loading
- (void)viewDidLoad {
    // Setup paging scrolling view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.alpha = _isWindow ? 0.0f: 1.0f;
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self.view addSubview:_pagingScrollView];
    
    [super viewDidLoad];
}


#pragma mark - Appearance
- (void)viewWillAppear:(BOOL)animated {
    // Super
    [super viewWillAppear:animated];
    if (_isWindow) {
        [self.view addSubview:_backgroundView];
        [self.view addSubview:_avatarImageView];
    } else {
        [self p_additionalInitialisation];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    // Super
    [super viewWillDisappear:animated];
}

#pragma mark - Nav Bar Appearance


#pragma mark - Layout
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
//    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {

}

#pragma mark - Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
//    // Perform layout
//    _currentPageIndex = _pageIndexBeforeRotation;
//    
//    // Delay control holding
//    [self hideControlsAfterDelay];
//    
//    // Layout
//    [self layoutVisiblePages];
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    _rotating = NO;
//    // Ensure nav bar isn't re-displayed
//    if ([self areControlsHidden]) {
//        self.navigationController.navigationBarHidden = NO;
//        self.navigationController.navigationBar.alpha = 0;
//    }
}

#pragma mark - Data
- (NSUInteger)currentIndex {
    return _currentPageIndex;
}

- (void)reloadData {

}

- (NSUInteger)numberOfPhotos {
//    if (_photoCount == NSNotFound) {
//        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
//            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
//        } else if (_fixedPhotosArray) {
//            _photoCount = _fixedPhotosArray.count;
//        }
//    }
//    if (_photoCount == NSNotFound) _photoCount = 0;
//    return _photoCount;
    return 0;
}

- (id<LJPhoto>)photoAtIndex:(NSUInteger)index {
    id <LJPhoto> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            } else if (_fixedPhotosArray && index < _fixedPhotosArray.count) {
                photo = [_fixedPhotosArray objectAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (id<LJPhoto>)thumbPhotoAtIndex:(NSUInteger)index {
    id <LJPhoto> photo = nil;
    if (index < _thumbPhotos.count) {
        if ([_thumbPhotos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)]) {
                photo = [_delegate photoBrowser:self thumbPhotoAtIndex:index];
            }
            if (photo) [_thumbPhotos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_thumbPhotos objectAtIndex:index];
        }
    }
    return photo;
}

- (id)imageForPhoto:(id<LJPhoto>)photo {
    if (photo) {
        // Get image or obtain in background
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
    return nil;
}

#pragma mark - LJPhoto Loading Notification
- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {

    
}
#pragma mark - Paging

- (void)tilePages {

}

- (void)updateVisiblePageStates {
//    NSSet *copy = [_visiblePages copy];
//    for (MWZoomingScrollView *page in copy) {
//        
//        // Update selection
//        page.selectedButton.selected = [self photoIsSelectedAtIndex:page.index];
//        
//    }
}

//- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
//    for (MWZoomingScrollView *page in _visiblePages)
//        if (page.index == index) return YES;
//    return NO;
//}
//
//- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
//    MWZoomingScrollView *thePage = nil;
//    for (MWZoomingScrollView *page in _visiblePages) {
//        if (page.index == index) {
//            thePage = page; break;
//        }
//    }
//    return thePage;
//}
//
//- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo {
//    MWZoomingScrollView *thePage = nil;
//    for (MWZoomingScrollView *page in _visiblePages) {
//        if (page.photo == photo) {
//            thePage = page; break;
//        }
//    }
//    return thePage;
//}
//
//- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index {
//    page.frame = [self frameForPageAtIndex:index];
//    page.index = index;
//    page.photo = [self photoAtIndex:index];
//}

//- (MWZoomingScrollView *)dequeueRecycledPage {
//    MWZoomingScrollView *page = [_recycledPages anyObject];
//    if (page) {
//        [_recycledPages removeObject:page];
//    }
//    return page;
//}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
}

#pragma mark - Frame Calculations
- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

//- (CGRect)frameForPageAtIndex:(NSUInteger)index {
//    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
//    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
//    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
//    // because it has a rotation transform applied.
//    CGRect bounds = _pagingScrollView.bounds;
//    CGRect pageFrame = bounds;
//    pageFrame.size.width -= (2 * PADDING);
//    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
//    return CGRectIntegral(pageFrame);
//}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}


- (UIWindow *)overlayWindow {
    if (!_overlayWindow) {
        _overlayWindow = [[UIWindow alloc]init];
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.windowLevel = UIWindowLevelStatusBar; // 可盖住状态栏
        _overlayWindow.frame = [[[UIApplication sharedApplication] delegate] window].frame;
        _overlayWindow.rootViewController = self;
        [_overlayWindow makeKeyAndVisible];
    }
    return _overlayWindow;
}

@end
