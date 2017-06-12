//
//  LJBrowserHelper.h
//  LJPhotoBrowser
//
//  Created by liuliangju on 6/11/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LJPhoto;

@interface LJBrowserHelper : NSObject

+ (CGRect)calcfromFrame:(LJPhoto *)photo;

+ (CGRect)calcToFrame:(LJPhoto *)photo;

@end
