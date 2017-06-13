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
#import "SDImageCache.h"
#import "FLAnimatedImage.h"

#define PADDING                                           10
#define kDownLoadOriginalImgButtonWidth                  100

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
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    self = [self init];
    if (self) {
        _fixedPhotosArray = photosArray;
    }
    return self;
}

- (void)showPhotoBrowserWithFirstPhoto:(LJPhoto *)photo {
    self.overlayWindow.hidden = NO;
    if (photo.image) {
        _avatarImageView.image = photo.image;
        CGRect fromFrame = [LJBrowserHelper calcfromFrame:photo];
        CGRect toFrame = [LJBrowserHelper calcToFrame:photo];
        _avatarImageView.frame = fromFrame;
        [UIView animateWithDuration:self.animationTime animations:^{
            _backgroundView.alpha = 1;
            _pagingScrollView.alpha = 1;
            _avatarImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            _avatarImageView.hidden = YES;
            _backgroundView.hidden = YES;
            [self reloadData];
        }];
    } else {  // if firstPhoto image is nil download the images
        [UIView animateWithDuration:self.animationTime animations:^{
            _backgroundView.alpha = 1;
            _pagingScrollView.alpha = 1;
        } completion:^(BOOL finished) {
            _avatarImageView.hidden = YES;
            _backgroundView.hidden = YES;
            [self reloadData];
        }];
    }
}

- (void)p_initialisation {
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _currentVideoIndex = NSUIntegerMax;
    _currentOriginalIndex = NSUIntegerMax;
    _previousLayoutBounds = CGRectZero;
    _performingLayout = NO; // Reset on view did appear
    _zoomPhotosToFill = YES;
    _rotating = NO;
    _viewIsActive = NO;
    _delayToHideElements = 5;
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];
    _thumbPhotos = [[NSMutableArray alloc] init];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _backgroundView = [[UIView alloc] initWithFrame:kLJPhotoBrowserScreenBounds];
    _backgroundView.backgroundColor = [UIColor blackColor];
    _backgroundView.alpha = 0;
    
    // 用于查看图片的UIImageView
    _avatarImageView = [[FLAnimatedImageView alloc] init];
    _avatarImageView.backgroundColor = [UIColor clearColor];
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    // Listen for LJPhoto notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLJPhotoLoadingDidEndNotification:)
                                                 name:LJPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLJPhotoLoadingOriginalNotification:)
                                                 name:LJPHOTO_LOADING_ORIGINAL_NOTIFICATION
                                               object:nil];
    
    // Custom
    _useDefaultBarButtons = YES;

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
    _enableSwipeToDismiss = YES;
}

- (void)dealloc {
    [self clearCurrentVideo];
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self releaseAllUnderlyingPhotos:NO];
    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    // Create a copy in case this array is modified while we are looping through
    // Release photos
    NSArray *copy = [_photos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
                continue; // skip current
            }
            [p unloadUnderlyingImage];
        }
    }
    // Release thumbs
    copy = [_thumbPhotos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage];
        }
    }
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
    
    // Update
    if (!_isWindow) [self reloadData];
    
    // Swipe to dismiss
    if (_enableSwipeToDismiss && !_isWindow) {
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonPressed:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
        [self.view addGestureRecognizer:swipeGesture];
    }
    
    [super viewDidLoad];
}

- (void)performLayout {
    // Setup
    _performingLayout = YES;
//    NSUInteger numberOfPhotos = [self numberOfPhotos];
    // Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];

    if (_useDefaultBarButtons) {
        // Navigation buttons
        if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
            // We're first on stack so show done button
            _doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
            // Set appearance
            [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
            [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
            [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
            self.navigationItem.rightBarButtonItem = _doneButton;
        } else {
            // We're not first so show back button
            UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
            NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
            UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil];
            // Appearance
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
            _previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
            previousViewController.navigationItem.backBarButtonItem = newBackButton;
        }
    }
    
    // Update nav
    [self updateNavigation];
    
    // Content offset
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
    _currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
//    _toolbar = nil;
    _previousButton = nil;
    _nextButton = nil;
    _progressHUD = nil;
    [super viewDidUnload];
}

- (BOOL)presentingViewControllerPrefersStatusBarHidden {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        // We're in a navigation controller so get previous one!
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO;
    }
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
        // Status bar
        if (!_viewHasAppearedInitially) {
            _leaveStatusBarAlone = [self presentingViewControllerPrefersStatusBarHidden];
            // Check if status bar is hidden on first appear, and if so then ignore it
            if (CGRectEqualToRect([[UIApplication sharedApplication] statusBarFrame], CGRectZero)) {
                _leaveStatusBarAlone = YES;
            }
        }
        // Set style
        if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
        }
        
        // Navigation bar appearance
        if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
            [self storePreviousNavBarAppearance];
        }
        [self setNavBarAppearance:animated];
        
        // Update UI
        [self hideControlsAfterDelay];
    }
    
    // If rotation occured while we're presenting a modal
    // and the index changed, make sure we show the right one now
    if (_currentPageIndex != _pageIndexBeforeRotation) {
        [self jumpToPageAtIndex:_pageIndexBeforeRotation animated:NO];
    }
    
    // Layout
    [self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
    // Autoplay if first is video
    if (!_viewHasAppearedInitially) {
        if (_autoPlayOnAppear) {
            LJPhoto *photo = [self photoAtIndex:_currentPageIndex];
            if ([photo respondsToSelector:@selector(isVideo)] && photo.isVideo) {
                [self playVideoAtIndex:_currentPageIndex];
            }
        }
    }
    _viewHasAppearedInitially = YES;
}


- (void)viewWillDisappear:(BOOL)animated {

    // Detect if rotation occurs while we're presenting a modal
    _pageIndexBeforeRotation = _currentPageIndex;
    
    if (!_isWindow) {
        // Check that we're disappearing for good
        // self.isMovingFromParentViewController just doesn't work, ever. Or self.isBeingDismissed
        if ((_doneButton && self.navigationController.isBeingDismissed) ||
            ([self.navigationController.viewControllers objectAtIndex:0] != self && ![self.navigationController.viewControllers containsObject:self])) {
            
            // State
            _viewIsActive = NO;
            [self clearCurrentVideo]; // Clear current playing video
            
            // Bar state / appearance
            [self restorePreviousNavBarAppearance:animated];
            
        }
        
        // Controls
        [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
        [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
        [self setControlsHidden:NO animated:NO permanent:YES];
        
        // Status bar
        if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent && _hasBelongedToViewController) {
        [NSException raise:@"LJPhotoBrowser Instance Reuse" format:@"LJPhotoBrowser instances cannot be reused."];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (!parent) _hasBelongedToViewController = YES;
}

#pragma mark - Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
}

- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact];
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        navBar.barTintColor = _previousNavBarBarTintColor;
        navBar.barStyle = _previousNavBarStyle;
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsCompact];
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}


#pragma mark - Layout
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {
    // Flag
    _performingLayout = YES;
    
    // Remember index
    NSUInteger indexPriorToLayout = _currentPageIndex;
    
    // Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    // Frame needs changing
    if (!_skipNextPagingScrollViewPositioning) {
        _pagingScrollView.frame = pagingScrollViewFrame;
    }
    _skipNextPagingScrollViewPositioning = NO;
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // Adjust frames and configuration of each visible page
    for (LJZoomingScrollView *page in _visiblePages) {
        NSUInteger index = page.index;
        page.frame = [self frameForPageAtIndex:index];
        if (page.playButton) {
            page.playButton.frame = [self frameForPlayButton:page.playButton atIndex:index];
        }
        
        if (page.originalBtn) {
            page.originalBtn.frame = [self frameForOriginalBtn:page.originalBtn atIndex:index];
        }
        // Adjust scales if bounds has changed since last time
        if (!CGRectEqualToRect(_previousLayoutBounds, self.view.bounds)) {
            // Update zooms for new bounds
            [page setMaxMinZoomScalesForCurrentBounds];
            _previousLayoutBounds = self.view.bounds;
        }
        
    }
    
    // Adjust video loading indicator if it's visible
    [self positionVideoLoadingIndicator];
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    [self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
    // Reset
    _currentPageIndex = indexPriorToLayout;
    _performingLayout = NO;
}

#pragma mark - Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Remember page index before rotation
    _pageIndexBeforeRotation = _currentPageIndex;
    _rotating = YES;
    
    // In iOS 7 the nav bar gets shown after rotation, but might as well do this for everything!
    if (!_isWindow) {
        if ([self areControlsHidden]) {
            // Force hidden
            self.navigationController.navigationBarHidden = YES;
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Perform layout
    _currentPageIndex = _pageIndexBeforeRotation;

    // Delay control holding
//    [self hideControlsAfterDelay];
    
    // Layout
    [self layoutVisiblePages];
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _rotating = NO;
    // Ensure nav bar isn't re-displayed
    if (!_isWindow) {
        if ([self areControlsHidden]) {
            self.navigationController.navigationBarHidden = NO;
            self.navigationController.navigationBar.alpha = 0;
        }
    }
}

#pragma mark - Data
- (NSUInteger)currentIndex {
    return _currentPageIndex;
}

- (void)reloadData {
    
    // Reset
    _photoCount = NSNotFound;
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos:YES];
    
    if (!_isWindow) {
        [_photos removeAllObjects];
        [_thumbPhotos removeAllObjects];
    }
    for (int i = 0; i < numberOfPhotos; i++) {
        [_photos addObject:[NSNull null]];
        [_thumbPhotos addObject:[NSNull null]];
    }
    // Update current page index
    if (numberOfPhotos > 0) {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    } else {
        _currentPageIndex = 0;
    }
    // Update layout
    if ([self isViewLoaded]) {
        while (_pagingScrollView.subviews.count) {
            [[_pagingScrollView.subviews lastObject] removeFromSuperview];
        }
        [self performLayout];
        [self.view setNeedsLayout];
    }
}

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        } else if (_fixedPhotosArray) {
            _photoCount = _fixedPhotosArray.count;
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (LJPhoto *)photoAtIndex:(NSUInteger)index {
    LJPhoto *photo = nil;
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

- (LJPhoto *)thumbPhotoAtIndex:(NSUInteger)index {
    LJPhoto *photo = nil;
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

- (id)imageForPhoto:(LJPhoto *)photo {
    if (photo) {
        // Get image or obtain in background
        
        id image;
        if (photo.isHaveOriginalImg) {
            image = [[SDImageCache sharedImageCache]imageFromCacheForKey:photo.originalImgUrl.absoluteString];
            if (image) {
                _originalLasLoad = YES;
                photo.underlyingImage = image;
                return image;
            }
        }
        
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
    return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(LJPhoto *)photo {
    LJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = page.index;
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                LJPhoto *photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    LJLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                LJPhoto *photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    LJLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex+1);
                }
            }
        }
    }
}


#pragma mark - Paging

- (void)tilePages {
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    
    // Recycle no longer needed pages
    NSInteger pageIndex;
    for (LJZoomingScrollView *page in _visiblePages) {
        pageIndex = page.index;
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
            [_recycledPages addObject:page];
//            [page.captionView removeFromSuperview];
//            [page.selectedButton removeFromSuperview];
            [page.playButton removeFromSuperview];
            [page.originalBtn removeFromSuperview];
            [page prepareForReuse];
            [page removeFromSuperview];
            LJLog(@"Removed page at index %lu", (unsigned long)pageIndex);
        }
    }
    
    [_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
       
        if (![self isDisplayingPageForIndex:index]) {
        
            // Add new page
            LJZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page) {
                page = [[LJZoomingScrollView alloc] initWithPhotoBrowser:self];
            }
            
            [_visiblePages addObject:page];
            [self configurePage:page forIndex:index];
            
            [_pagingScrollView addSubview:page];
            LJLog(@"Added page at index %lu", (unsigned long)index);
            
            // Add play button if needed
            if (page.displayingVideo) {
                UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [playButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PlayButtonOverlayLarge" ofType:@"png"]] forState:UIControlStateNormal];
                [playButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PlayButtonOverlayLargeTap" ofType:@"png"]] forState:UIControlStateHighlighted];

                [playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [playButton sizeToFit];
                playButton.frame = [self frameForPlayButton:playButton atIndex:index];
                [_pagingScrollView addSubview:playButton];
                page.playButton = playButton;
            }
            
            if (page.disloadingOriginalBtn) {
                NSString *downLoadTitle =[NSString stringWithFormat:@"查看原图(%@) ",page.photo.totalSize];
                [ self.originalBtn setTitle:downLoadTitle forState:UIControlStateNormal];
                self.originalBtn.tag = LJPhotoBrowser_willLoad;
                [ self.originalBtn addTarget:self action:@selector(loadOriginalTapped:) forControlEvents:UIControlEventTouchUpInside];
                [ self.originalBtn sizeToFit];
                 self.originalBtn.frame = [self frameForOriginalBtn:self.originalBtn atIndex:index];
                [_pagingScrollView addSubview: self.originalBtn];
                page.originalBtn =  self.originalBtn;
            }
        }
    }
}


//- (void)updateVisiblePageStates {
//    NSSet *copy = [_visiblePages copy];
//    for (LJZoomingScrollView *page in copy) {
//        
//        // Update selection
//        page.selectedButton.selected = [self photoIsSelectedAtIndex:page.index];
//        
//    }
//}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (LJZoomingScrollView *page in _visiblePages)
        if (page.index == index) return YES;
    return NO;
}

- (LJZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
    LJZoomingScrollView *thePage = nil;
    for (LJZoomingScrollView *page in _visiblePages) {
        if (page.index == index) {
            thePage = page; break;
        }
    }
    return thePage;
}

- (LJZoomingScrollView *)pageDisplayingPhoto:(LJPhoto *)photo {
    LJZoomingScrollView *thePage = nil;
    for (LJZoomingScrollView *page in _visiblePages) {
        if (page.photo == photo) {
            thePage = page; break;
        }
    }
    return thePage;
}

- (void)configurePage:(LJZoomingScrollView *)page forIndex:(NSUInteger)index {
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.photo = [self photoAtIndex:index];
}

- (LJZoomingScrollView *)dequeueRecycledPage {
    LJZoomingScrollView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    // Handle 0 photos
    if (![self numberOfPhotos]) {
        // Show controls
        if (!_isWindow) {
            [self setControlsHidden:NO animated:YES permanent:YES];
        }
        return;
    }
    // Handle video on page change
    if (!_rotating && index != _currentVideoIndex) {
        [self clearCurrentVideo];
    }
    
    // Release images further away than +/-1
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                LJLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                LJLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    LJPhoto *currentPhoto = [self photoAtIndex:index];
        if (_originalLasLoad) {
        LJZoomingScrollView *page = [self pageDisplayingPhoto:currentPhoto];
        if (page.originalBtn) {
            page.originalBtn.hidden = YES;
        }
    }
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
    // Notify delegate
    if (index != _previousPageIndex) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDisplayPhotoAtIndex:)])
            [_delegate photoBrowser:self didDisplayPhotoAtIndex:index];
        _previousPageIndex = index;
    }
    // Update nav
    [self updateNavigation];
}

#pragma mark - Frame Calculations
- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}

- (CGRect)frameForPlayButton:(UIButton *)playButton atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    return CGRectMake(floorf(CGRectGetMidX(pageFrame) - playButton.frame.size.width / 2),
                      floorf(CGRectGetMidY(pageFrame) - playButton.frame.size.height / 2),
                      playButton.frame.size.width,
                      playButton.frame.size.height);
}

- (CGRect)frameForOriginalBtn:(UIButton *)originalBtn atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    return CGRectMake(floorf(CGRectGetMidX(pageFrame) - kDownLoadOriginalImgButtonWidth / 2),
                      (floorf(CGRectGetMaxY(pageFrame) - originalBtn.frame.size.height) - 10),
                      kDownLoadOriginalImgButtonWidth,
                      25);
}


#pragma mark - UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating) return;
    // Tile pages
    [self tilePages];
    
    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (!_isWindow) {
        [self hideControlsAfterDelay];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Update nav when page changes
    [self updateNavigation];
}

#pragma mark - Navigation

- (void)updateNavigation {
    // Title
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    if (numberOfPhotos > 1) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)]) {
            self.title = [_delegate photoBrowser:self titleForPhotoAtIndex:_currentPageIndex];
        } else {
            self.title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long)numberOfPhotos];
        }
    } else {
        self.title = nil;
    }
    
    // Buttons
    _previousButton.enabled = (_currentPageIndex > 0);
    _nextButton.enabled = (_currentPageIndex < numberOfPhotos - 1);
    
    // Disable action button if there is no image or it's a video
//    LJPhoto *photo = [self photoAtIndex:_currentPageIndex];
//    if ([photo underlyingImage] == nil || ([photo respondsToSelector:@selector(isVideo)] && photo.isVideo)) {
//        _actionButton.enabled = NO;
//        _actionButton.tintColor = [UIColor clearColor]; // Tint to hide button
//    } else {
//        _actionButton.enabled = YES;
//        _actionButton.tintColor = nil;
//    }
    
}


- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // Change page
    if (index < [self numberOfPhotos]) {
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
        [self updateNavigation];
    }
    
    // Update timer to give more time
    [self hideControlsAfterDelay];
}

- (void)gotoPreviousPage {
    [self showPreviousPhotoAnimated:NO];
}
- (void)gotoNextPage {
    [self showNextPhotoAnimated:NO];
}

- (void)showPreviousPhotoAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex-1 animated:animated];
}

- (void)showNextPhotoAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex+1 animated:animated];
}


#pragma mark - Interactions

- (void)playButtonTapped:(id)sender {
    // Ignore if we're already playing a video
    if (_currentVideoIndex != NSUIntegerMax) {
        return;
    }
    NSUInteger index = [self indexForPlayButton:sender];
    if (index != NSUIntegerMax) {
        if (!_currentVideoPlayerViewController) {
            [self playVideoAtIndex:index];
        }
    }
}

- (void)loadOriginalTapped:(UIButton *)sender {
   
    NSUInteger index = [self indexForOriginalButton:sender];

    LJOriginalLoadState loadingState = sender.tag;
    
    switch (loadingState) {
        case LJPhotoBrowser_willLoad: { 
            if (index != NSUIntegerMax) {
                self.originalBtn.tag = LJPhotoBrowser_loading;
                [self loadOriginalImageAtIndex:index];
            }
        }
            break;
        case LJPhotoBrowser_loading: {
            LJPhoto *photo = [self photoAtIndex:index];
            [photo cancelAnyLoading];
            LJZoomingScrollView *thePage = nil;
            for (LJZoomingScrollView *page in _visiblePages) {
                if (page.index == index) {
                    thePage = page;
                    thePage.originalBtn.hidden = YES;
                    break;
                }
            }
        }
            break;
            
        case LJPhotoBrowser_cancelLoad: {
        }
            break;
            
        case LJPhotoBrowser_LoadFail: {
            
        }
            break;
            
        default:
            break;
    }
}

- (NSUInteger)indexForPlayButton:(UIView *)playButton {
    NSUInteger index = NSUIntegerMax;
    for (LJZoomingScrollView *page in _visiblePages) {
        if (page.playButton == playButton) {
            index = page.index;
            break;
        }
    }
    return index;
}

- (NSUInteger)indexForOriginalButton:(UIView *)originalButton {
    NSUInteger index = NSUIntegerMax;
    for (LJZoomingScrollView *page in _visiblePages) {
        if (page.originalBtn == originalButton) {
            index = page.index;
            break;
        }
    }
    return index;
}


#pragma mark - OriginalImage
- (void)loadOriginalImageAtIndex:(NSUInteger)index {
    LJPhoto *photo = [self photoAtIndex:index];    
    _currentOriginalIndex = index;
    LJZoomingScrollView *thePage = nil;
    for (LJZoomingScrollView *page in _visiblePages) {
        if (page.index == _currentOriginalIndex) {
            thePage = page;
            [self.originalBtn setTitle:@"0.0%" forState:UIControlStateNormal];
            break;
        }
    }
    [photo p_performLoadUnderlyingImageAndNotifyWithWebURL:photo.originalImgUrl isOriginalImg:YES];
}


#pragma mark - LJPhoto Loading Notification
- (void)handleLJPhotoLoadingDidEndNotification:(NSNotification *)notification {
    LJPhoto *photo = [notification object];
    LJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if (page.originalBtn) {
            page.originalBtn.hidden = YES;
        }
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
        }
        // Update nav
        [self updateNavigation];
    }
}

- (void)handleLJPhotoLoadingOriginalNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification object];
        LJPhoto *photo = [dict valueForKey:@"photo"];
        NSString *progress = [dict valueForKey:@"progress"];
        LJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
        [self.originalBtn setTitle:[NSString stringWithFormat:@"取消下载 %@", progress] forState:UIControlStateNormal];
        if ([progress isEqualToString:@"100%"]) {
            page.originalBtn.hidden = YES;
        }
    });
}


#pragma mark - Video

- (void)playVideoAtIndex:(NSUInteger)index {
    id photo = [self photoAtIndex:index];
    if ([photo respondsToSelector:@selector(getVideoURL:)]) {
        
        // Valid for playing
        [self clearCurrentVideo];
        _currentVideoIndex = index;
        [self setVideoLoadingIndicatorVisible:YES atPageIndex:index];
        
        // Get video and play
        typeof(self) __weak weakSelf = self;
        [photo getVideoURL:^(NSURL *url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // If the video is not playing anymore then bail
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                if (strongSelf->_currentVideoIndex != index || !strongSelf->_viewIsActive) {
                    return;
                }
                if (url) {
                    [weakSelf p_playVideo:url atPhotoIndex:index];
                } else {
                    [weakSelf setVideoLoadingIndicatorVisible:NO atPageIndex:index];
                }
            });
        }];
    }
}

- (void)p_playVideo:(NSURL *)videoURL atPhotoIndex:(NSUInteger)index {
    
    // Setup player
    _currentVideoPlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
    [_currentVideoPlayerViewController.moviePlayer prepareToPlay];
    _currentVideoPlayerViewController.moviePlayer.shouldAutoplay = YES;
    _currentVideoPlayerViewController.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    _currentVideoPlayerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Remove the movie player view controller from the "playback did finish" notification observers
    // Observe ourselves so we can get it to use the crossfade transition
    [[NSNotificationCenter defaultCenter] removeObserver:_currentVideoPlayerViewController
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:_currentVideoPlayerViewController.moviePlayer];
    
    // Show
    [self presentViewController:_currentVideoPlayerViewController animated:YES completion:nil];
}

- (void)videoFinishedCallback:(NSNotification*)notification {
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    
    // Clear up
    [self clearCurrentVideo];
    
    // Dismiss
    BOOL error = [[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue] == MPMovieFinishReasonPlaybackError;
    if (error) {
        // Error occured so dismiss with a delay incase error was immediate and we need to wait to dismiss the VC
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        if (_photos.count == 1) {
            if (_isWindow) {
                self.overlayWindow.hidden = YES;
                [self.overlayWindow.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)]; // 删除UIWindow里的所有子view
                self.overlayWindow.rootViewController = nil; // 避免影响其它的UIViewController
                self.overlayWindow = nil;
            }
        }
    }
}

- (void)clearCurrentVideo {
    [_currentVideoPlayerViewController.moviePlayer stop];
    [_currentVideoLoadingIndicator removeFromSuperview];
    _currentVideoPlayerViewController = nil;
    _currentVideoLoadingIndicator = nil;
    [[self pageDisplayedAtIndex:_currentVideoIndex] playButton].hidden = NO;
    _currentVideoIndex = NSUIntegerMax;
}

- (void)setVideoLoadingIndicatorVisible:(BOOL)visible atPageIndex:(NSUInteger)pageIndex {
    if (_currentVideoLoadingIndicator && !visible) {
        [_currentVideoLoadingIndicator removeFromSuperview];
        _currentVideoLoadingIndicator = nil;
        [[self pageDisplayedAtIndex:pageIndex] playButton].hidden = NO;
    } else if (!_currentVideoLoadingIndicator && visible) {
        _currentVideoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        [_currentVideoLoadingIndicator sizeToFit];
        [_currentVideoLoadingIndicator startAnimating];
        [_pagingScrollView addSubview:_currentVideoLoadingIndicator];
        [self positionVideoLoadingIndicator];
        [[self pageDisplayedAtIndex:pageIndex] playButton].hidden = YES;
    }
}

- (void)positionVideoLoadingIndicator {
    if (_currentVideoLoadingIndicator && _currentVideoIndex != NSUIntegerMax) {
        CGRect frame = [self frameForPageAtIndex:_currentVideoIndex];
        _currentVideoLoadingIndicator.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    }
}

#pragma mark - Grid


#pragma mark - Control Hiding / Showing
// If permanent then we don't set timers to hide again
// Fades all controls on iOS 5 & 6, and iOS 7 controls slide and fade
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    // Force visible
    if (![self numberOfPhotos])
        hidden = NO;
    
    // Cancel any timers
    [self cancelControlHiding];
    
    // Animations & positions
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if (!_leaveStatusBarAlone) {
        
        // Hide status bar
        if (!_isVCBasedStatusBarAppearance) {
            
            // Non-view controller based
            [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
            
        } else {
            
            // View controller based so animate away
            _statusBarShouldBeHidden = hidden;
            [UIView animateWithDuration:animationDuration animations:^(void) {
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:^(BOOL finished) {}];
            
        }
    }
    
    [UIView animateWithDuration:animationDuration animations:^(void) {
        
        CGFloat alpha = hidden ? 0 : 1;
        
        // Nav bar slides up on it's own on iOS 7+
        [self.navigationController.navigationBar setAlpha:alpha];
        
//        // Toolbar
//        _toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
//        if (hidden) _toolbar.frame = CGRectOffset(_toolbar.frame, 0, animatonOffset);
//        _toolbar.alpha = alpha;
        _isHiddenNavBarHidden = hidden;
//        
//        // Captions
//        for (MWZoomingScrollView *page in _visiblePages) {
//            if (page.captionView) {
//                MWCaptionView *v = page.captionView;
//                // Pass any index, all we're interested in is the Y
//                CGRect captionFrame = [self frameForCaptionView:v atIndex:0];
//                captionFrame.origin.x = v.frame.origin.x; // Reset X
//                if (hidden) captionFrame = CGRectOffset(captionFrame, 0, animatonOffset);
//                v.frame = captionFrame;
//                v.alpha = alpha;
//            }
//        }
//        
//        // Selected buttons
//        for (MWZoomingScrollView *page in _visiblePages) {
//            if (page.selectedButton) {
//                UIButton *v = page.selectedButton;
//                CGRect newFrame = [self frameForSelectedButton:v atIndex:0];
//                newFrame.origin.x = v.frame.origin.x;
//                v.frame = newFrame;
//            }
//        }
        
    } completion:^(BOOL finished) {}];
    
    // Control hiding timer
    // Will cancel existing timer but only begin hiding if
    // they are visible
    if (!permanent) [self hideControlsAfterDelay];
}

- (BOOL)prefersStatusBarHidden {
    if (!_leaveStatusBarAlone) {
        return _statusBarShouldBeHidden;
    } else {
        return [self presentingViewControllerPrefersStatusBarHidden];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)cancelControlHiding {
    // If a timer exists then cancel and release
    if (_controlVisibilityTimer) {
        [_controlVisibilityTimer invalidate];
        _controlVisibilityTimer = nil;
    }
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    if (![self areControlsHidden]) {
        [self cancelControlHiding];
        _controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayToHideElements target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    }
}

- (BOOL)areControlsHidden {
    return _isHiddenNavBarHidden;
}

- (void)hideControls {
    [self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)showControls {
    [self setControlsHidden:NO animated:YES permanent:NO];
}

- (void)toggleControls:(LJPhoto *)photo {
    // 强制旋转到人像模式
    if (_isWindow) {
        if ([UIDevice currentDevice].orientation != UIDeviceOrientationPortrait) {
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }

        if ([photo.image isKindOfClass:[UIImage class]]) {
            _avatarImageView.image = photo.image;
        } else {
            _avatarImageView.image = ((FLAnimatedImage *)photo.image).posterImage;
        }
        
        _avatarImageView.frame = [LJBrowserHelper calcToFrame:photo];
        _avatarImageView.hidden = NO;
        _backgroundView.hidden = NO;
        _pagingScrollView.hidden = YES;
        [UIView animateWithDuration:self.animationTime delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            _backgroundView.alpha = 0;
            if (CGRectEqualToRect(photo.imageFrame, CGRectZero)) {
                _avatarImageView.alpha = 0;
            } else {
                _avatarImageView.frame = [LJBrowserHelper calcfromFrame:photo];
            }
        } completion:^(BOOL finished) {
            [self.overlayWindow.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)]; // 删除UIWindow里的所有子view
//            self.overlayWindow.hidden = YES;
            
            self.overlayWindow.rootViewController = nil; // 避免影响其它的UIViewController
            [self.overlayWindow removeFromSuperview];
            self.overlayWindow = nil;
        }];
    } else {
         [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO];
    }
}

- (UIWindow *)mainWindow {
    UIApplication *app = [UIApplication sharedApplication];
    if ([app.delegate respondsToSelector:@selector(window)]) {
        return [app.delegate window];
    } else {
        return [app keyWindow];
    }
}

        
#pragma mark - Properties

- (void)setCurrentPhotoIndex:(NSUInteger)index {
    // Validate
    NSUInteger photoCount = [self numberOfPhotos];
    if (photoCount == 0) {
        index = 0;
    } else {
        if (index >= photoCount)
            index = [self numberOfPhotos]-1;
    }
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
        if (!_viewIsActive)
            [self tilePages]; // Force tiling if view is not visible
    }
}

#pragma mark - Misc

- (void)doneButtonPressed:(id)sender {
    // Only if we're modal and there's a done button
    if (_doneButton) {
        // See if we actually just want to show/hide grid
        
        // Dismiss view controller
        if ([_delegate respondsToSelector:@selector(photoBrowserDidFinishModalPresentation:)]) {
            // Call delegate method and let them dismiss us
            [_delegate photoBrowserDidFinishModalPresentation:self];
        } else  {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
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

- (UIButton *)originalBtn {
    if (!_originalBtn) {
        _originalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalBtn.titleLabel.font = [UIFont systemFontOfSize: 13.0];
        [_originalBtn.layer setCornerRadius:4.0f]; //设置矩形四个圆角半径
        [_originalBtn.layer setBorderWidth:1.0f]; //边框宽度
        [_originalBtn.layer setMasksToBounds:YES];
        _originalBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:.2];
    }
    return _originalBtn;
}

@end
