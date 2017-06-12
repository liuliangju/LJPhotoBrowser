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
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) id image;
@property (nonatomic, strong) UIImage *placeHolder;
@property (nonatomic) BOOL emptyImage;
@property (nonatomic) BOOL isVideo;
@property (nonatomic) BOOL isHaveOriginalImg;
@property (nonatomic, assign) CGRect imageFrame;


+ (LJPhoto *)photoWithImage:(UIImage *)image;
+ (LJPhoto *)photoWithData:(NSData *)gifImage;

+ (LJPhoto *)photoWithFilePath:(NSString *)path;
+ (LJPhoto *)photoWithURL:(NSURL *)url;

- (id)initWithImage:(id)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithFilePath:(NSString *)path;


@end
