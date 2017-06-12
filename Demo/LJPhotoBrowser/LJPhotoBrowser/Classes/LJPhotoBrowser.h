//
//  LJPhotoBrowser.h
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LJPhoto.h"
#import "LJPhotoProtocol.h"

// Debug Logging
#if 1 // Set to 1 to enable debug logging
#define LJLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define LJLog(x, ...)
#endif

@class LJPhotoBrowser;

@protocol LJPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(LJPhotoBrowser *)photoBrowser;
- (LJPhoto *)photoBrowser:(LJPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (void)photoBrowserDidFinishModalPresentation:(LJPhotoBrowser *)photoBrowser;
- (LJPhoto *)photoBrowser:(LJPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(LJPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;

@end

@interface LJPhotoBrowser : UIViewController <UIScrollViewDelegate>


@property (nonatomic, weak) IBOutlet id<LJPhotoBrowserDelegate> delegate;
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic, assign) BOOL isWindow;
@property (nonatomic) NSUInteger delayToHideElements;
@property (nonatomic, assign) double animationTime; // if use full screen window the animation time


// Init
- (instancetype)initWithDelegate:(id <LJPhotoBrowserDelegate>)delegate;
- (instancetype)initWithPhotos:(NSArray *)photosArray;
- (void)showPhotos:(NSArray *)photos fromIndex:(NSInteger)index; //This way the initialization using Window as a background
- (void)showPhotoBrowserWithFirstPhoto:(LJPhoto *)photo;


// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;



@end
