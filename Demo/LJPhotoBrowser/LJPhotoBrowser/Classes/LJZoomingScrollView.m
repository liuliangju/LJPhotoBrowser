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
#import "LJPhotoBrowserPrivate.h"
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
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
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

- (void)prepareForReuse {
    [self hideImageFailure];
    self.photo = nil;
//    self.captionView = nil;
//    self.selectedButton = nil;
    self.playButton = nil;
    _photoImageView.hidden = NO;
    _photoImageView.image = nil;
    _index = NSUIntegerMax;
}

#pragma mark - Image
- (void)setPhoto:(id<LJPhoto>)photo {
    // Cancel any loading on old photo
    if (_photo && photo == nil) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _photo = photo;
    
    id tmpImage = [_photoBrowser imageForPhoto:_photo];
    if (tmpImage) {
        [self displayImage];
    } else {
        // Will be loading so show loading
        [self showLoadingIndicator];
    }
}

- (void)displayImage {
    if (_photo && _photoImageView.image == nil) {
    
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        id tmpImage = [_photoBrowser imageForPhoto:_photo];
        if (tmpImage) {
            // Hide indicator
            [self hideLoadingIndicator];
            
            // Set image
            
            if ([tmpImage isKindOfClass:[UIImage class]]) {

                UIImage *img = (UIImage *)tmpImage;
                // Set image
                _photoImageView.image = img;
                // Setup photo frame
                CGRect photoImageViewFrame = [LJBrowserHelper calcToFrame:_photo];;
                _photoImageView.frame = photoImageViewFrame;//[LJBrowserHelper calcToFrame:_photo];
                self.contentSize = photoImageViewFrame.size;
                
                // Set zoom to minimum zoom
//                [self setMaxMinZoomScalesForCurrentBounds];   
            } else {
//                _photoImageView.backgroundColor = [UIColor whiteColor];
                _photoImageView.contentMode = UIViewContentModeCenter;
                FLAnimatedImage *img = (FLAnimatedImage *)tmpImage;
                _photoImageView.animatedImage = img;
                _photoImageView.frame = kLJPhotoBrowserScreenBounds;//[LJBrowserHelper calcToFrame:_photo];
                self.contentSize = kLJPhotoBrowserScreenBounds.size;

            }
            _photoImageView.hidden = NO;

        }
        
        [self setNeedsLayout];

    }
    
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

#pragma mark - Loading Progress

- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
    [self hideImageFailure];
}


#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView && _photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}


- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_photoImageView.image == nil) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        
    }
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // If it's a video then disable zooming
//    if ([self displayingVideo]) {
//        self.maximumZoomScale = self.zoomScale;
//        self.minimumZoomScale = self.zoomScale;
//    }
    
    // Layout
    [self setNeedsLayout];
    
}

@end
