//
//  LJPhoto.h
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "LJPhotoProtocol.h"

@interface LJPhoto : NSObject <LJPhoto>

//@property (nonatomic, strong) NSString *caption;
@property (nonatomic, copy) NSURL *photoURL;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) id image;
@property (nonatomic, strong) UIImage *placeHolder;
@property (nonatomic) BOOL emptyImage;
@property (nonatomic) BOOL isVideo;
@property (nonatomic) BOOL isHaveOriginalImg;
@property (nonatomic, assign) CGRect imageFrame;
@property (nonatomic, copy) NSString *totalSize;                   //原图大小



+ (LJPhoto *)photoWithImage:(UIImage *)image;
+ (LJPhoto *)photoWithData:(NSData *)gifImage;

+ (LJPhoto *)photoWithFilePath:(NSString *)path;
+ (LJPhoto *)photoWithURL:(NSURL *)url;

// Load from local file
- (void)p_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url isOriginalImg:(BOOL)isOriginal;

- (void)cancelAnyLoading;

- (id)initWithImage:(id)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithFilePath:(NSString *)path;




@end
