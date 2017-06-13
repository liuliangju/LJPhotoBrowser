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
#import "LJPhotoBrowser.h"
#import "NSData+ImageContentType.h"

@interface LJPhoto () {
    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
    PHImageRequestID _assetRequestID;
    PHImageRequestID _assetVideoRequestID;
}

//@property (nonatomic, strong) id image;
//@property (nonatomic, strong) UIImage *placeHolder;

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic) CGSize assetTargetSize;



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

#pragma mark - OriginalImage

- (void)loadOriginalImageWithURL:(NSURL *)originalImgUrl {
    
    [self p_performLoadUnderlyingImageAndNotifyWithWebURL:originalImgUrl isOriginalImg:YES];
    
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


#pragma mark - LJPhoto Protocol Methods
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
    } else if (_photoURL) {
        
        // Check what type of url it is
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            
            // Load from assets library
            [self p_performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL: _photoURL];
            
        } else if ([_photoURL isFileReferenceURL]) {
            
            // Load from local file async
            [self p_performLoadUnderlyingImageAndNotifyWithLocalFileURL: _photoURL];
            
        } else {
            
            // Load async from web (using SDWebImage)
            [self p_performLoadUnderlyingImageAndNotifyWithWebURL: _photoURL];
            
        }
        
    } else if (_asset) {
        
        // Load from photos asset
        [self p_performLoadUnderlyingImageAndNotifyWithAsset: _asset targetSize:_assetTargetSize];
        
    } else {
        
        // Image is empty
        [self imageLoadingComplete];
        
    }
}

// Load from local file

- (void)p_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    [self p_performLoadUnderlyingImageAndNotifyWithWebURL:url isOriginalImg:NO];
}


- (void)p_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url isOriginalImg:(BOOL)isOriginal {

    @try {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        _webImageOperation = [manager loadImageWithURL:url
                                               options:SDWebImageRefreshCached
                                              progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                                                  
                                                  if (receivedSize > 0) {
                                                      double progress = 100.f * receivedSize / expectedSize;
                                                      NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                            [NSNumber numberWithDouble:progress], @"progress",
                                                                            self, @"photo", nil];
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:LJPHOTO_PROGRESS_NOTIFICATION object:dict];
                                                      if (isOriginal) {
                                                          NSString *stringFloat =[NSString stringWithFormat:@"%.f%@",progress, @"%"];

                                                          NSDictionary *tmpdict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                   stringFloat, @"progress",
                                                                                   self, @"photo", nil];
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:LJPHOTO_LOADING_ORIGINAL_NOTIFICATION object:tmpdict];
                                                      }
                                                  }
                                              }
                                             completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                                 if (error) {
                                                     LJLog(@"SDWebImage failed to download image: %@", error);
                                                 }
                                                 _webImageOperation = nil;
                                                 
                                                 SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
                                                 
                                                 if (imageFormat == SDImageFormatGIF) {
                                                     self.underlyingImage = [FLAnimatedImage animatedImageWithGIFData:data];
                                                 } else {
                                                     self.underlyingImage = image;
                                                 }
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self imageLoadingComplete];
                                                 });
                                             }];
    } @catch (NSException *e) {
        LJLog(@"Photo from web: %@", e);
        _webImageOperation = nil;
        [self imageLoadingComplete];
    }
}
// Load from local file
- (void)p_performLoadUnderlyingImageAndNotifyWithLocalFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                self.underlyingImage = [UIImage imageWithContentsOfFile:url.path];
                if (!_underlyingImage) {
                    LJLog(@"Error loading photo from path: %@", url.path);
                }
            } @finally {
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }
        }
    });
}

// Load from asset library async
- (void)p_performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                [assetslibrary assetForURL:url
                               resultBlock:^(ALAsset *asset){
                                   ALAssetRepresentation *rep = [asset defaultRepresentation];
                                   CGImageRef iref = [rep fullScreenImage];
                                   if (iref) {
                                       self.underlyingImage = [UIImage imageWithCGImage:iref];
                                   }
                                   [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                               }
                              failureBlock:^(NSError *error) {
                                  self.underlyingImage = nil;
                                  LJLog(@"Photo from asset library error: %@",error);
                                  [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                              }];
            } @catch (NSException *e) {
                LJLog(@"Photo from asset library error: %@", e);
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }
        }
    });
}


// Load from photos library
- (void)p_performLoadUnderlyingImageAndNotifyWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = false;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithDouble: progress], @"progress",
                              self, @"photo", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:LJPHOTO_PROGRESS_NOTIFICATION object:dict];
    };
    
    _assetRequestID = [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.underlyingImage = result;
            [self imageLoadingComplete];
        });
    }];
    
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
