//
//  LJBrowserHelper.m
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/11/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJBrowserHelper.h"
#import "LJPhoto.h"
#import "LJCommonMacro.h"

@implementation LJBrowserHelper


// frame change
+ (CGRect)calcfromFrame:(LJPhoto *)photo {
    CGRect photoFrame = photo.imageFrame;
    if (CGRectEqualToRect(photoFrame, CGRectZero)) {
        return CGRectZero;
    }
    CGRect fromFrame = CGRectMake(photoFrame.origin.x, photoFrame.origin.y, photoFrame.size.width, photoFrame.size.height);
    return fromFrame;
}

+ (CGRect)calcToFrame:(LJPhoto *)photo {
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


@end
