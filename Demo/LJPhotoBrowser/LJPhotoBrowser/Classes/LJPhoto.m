//
//  LJPhoto.m
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJPhoto.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FLAnimatedImage.h"
#import "LJBrowserHelper.h"

@interface LJPhoto () {
    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
    PHImageRequestID _assetRequestID;
    PHImageRequestID _assetVideoRequestID;
}

//@property (nonatomic, strong) id image;
//@property (nonatomic, strong) UIImage *placeHolder;
@property (nonatomic, copy) NSURL *photoURL;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) PHAsset *asset;


- (void)imageLoadingComplete;

@end

@implementation LJPhoto

@synthesize underlyingImage = _underlyingImage; // synth property from protocol


#pragma mark - Class Methods

+ (LJPhoto *)photoWithImage:(UIImage *)image {
    return [[LJPhoto alloc] initWithImage:image];
}

+ (LJPhoto *)photoWithData:(NSData *)gifImage {
    return [[LJPhoto alloc] initWithImage:gifImage];
}

+ (LJPhoto *)photoWithURL:(NSURL *)url {
    return [[LJPhoto alloc] initWithURL:url];
}



#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        self.emptyImage = YES;
        [self setup];
    }
    return self;
}

- (id)initWithImage:(id)image {
    if ((self = [super init])) {
        if ([image isKindOfClass:[UIImage class]]) {
            self.image = image;
        } else {
            self.image = [FLAnimatedImage animatedImageWithGIFData:image];
        }
        
        [self setup];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        self.photoURL = url;
        [self setup];
    }
    return self;
}

- (id)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        self.videoURL = url;
        self.isVideo = YES;
        self.emptyImage = YES;
        [self setup];
    }
    return self;
}

- (void)setup {
    _assetRequestID = PHInvalidImageRequestID;
    _assetVideoRequestID = PHInvalidImageRequestID;
}

- (void)dealloc {
    [self cancelAnyLoading];
}

#pragma mark - Video

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    self.isVideo = YES;
}

- (void)getVideoURL:(void (^)(NSURL *url))completion {
    if (_videoURL) {
        completion(_videoURL);
    } else if (_asset && _asset.mediaType == PHAssetMediaTypeVideo) {
        [self cancelVideoRequest]; // Cancel any existing
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        typeof(self) __weak weakSelf = self;
        _assetVideoRequestID = [[PHImageManager defaultManager] requestAVAssetForVideo:_asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            
            // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ // Testing
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf->_assetVideoRequestID = PHInvalidImageRequestID;
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                completion(((AVURLAsset *)asset).URL);
            } else {
                completion(nil);
            }
        }];
    }
}


#pragma mark - MWPhoto Protocol Methods
- (id)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}


// Set the underlyingImage
- (void)performLoadUnderlyingImageAndNotify {
    
    // Get underlying image
    if (_image) {
        
        // We have UIImage!
        self.underlyingImage = _image;
        [self imageLoadingComplete];
        
    }
    
//    else if (_photoURL) {
//        
//        // Check what type of url it is
//        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
//            
//            // Load from assets library
//            [self _performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL: _photoURL];
//            
//        } else if ([_photoURL isFileReferenceURL]) {
//            
//            // Load from local file async
//            [self _performLoadUnderlyingImageAndNotifyWithLocalFileURL: _photoURL];
//            
//        } else {
//            
//            // Load async from web (using SDWebImage)
//            [self _performLoadUnderlyingImageAndNotifyWithWebURL: _photoURL];
//            
//        }
//        
//    } else if (_asset) {
//        
//        // Load from photos asset
//        [self _performLoadUnderlyingImageAndNotifyWithAsset: _asset targetSize:_assetTargetSize];
//        
//    } else {
//        
//        // Image is empty
//        [self imageLoadingComplete];
//        
//    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;
    self.underlyingImage = nil;
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:LJPHOTO_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

- (void)cancelAnyLoading {
    if (_webImageOperation != nil) {
        [_webImageOperation cancel];
        _loadingInProgress = NO;
    }
    [self cancelImageRequest];
    [self cancelVideoRequest];
}

- (void)cancelImageRequest {
    if (_assetRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_assetRequestID];
        _assetRequestID = PHInvalidImageRequestID;
    }
}

- (void)cancelVideoRequest {
    if (_assetVideoRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_assetVideoRequestID];
        _assetVideoRequestID = PHInvalidImageRequestID;
    }
}



@end
