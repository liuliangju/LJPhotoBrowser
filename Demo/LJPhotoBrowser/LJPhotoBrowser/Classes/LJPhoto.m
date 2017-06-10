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

@end

@implementation LJPhoto

#pragma mark - Class Methods

+ (LJPhoto *)photoWithImage:(UIImage *)image {
    return [[LJPhoto alloc] initWithImage:image];
}
+ (LJPhoto *)photoWithData:(NSData *)gifImage {
    return [[LJPhoto alloc] initWithImage:gifImage];
}


#pragma mark - Init
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

- (void)setup {
    _assetRequestID = PHInvalidImageRequestID;
    _assetVideoRequestID = PHInvalidImageRequestID;
}



@end
