//
//  LJPhoto.h
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LJPhotoProtocol.h"

@interface LJPhoto : NSObject <LJPhoto>

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, readonly) NSURL *photoURL;
@property (nonatomic, copy, readonly) NSString *filePath;


+ (LJPhoto *)photoWithImage:(UIImage *)image;
+ (LJPhoto *)photoWithFilePath:(NSString *)path;
+ (LJPhoto *)photoWithURL:(NSURL *)url;


- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithFilePath:(NSString *)path;


@end
