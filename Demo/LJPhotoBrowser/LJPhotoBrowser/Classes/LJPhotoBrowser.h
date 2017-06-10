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


@class LJPhotoBrowser;
@protocol LJPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(LJPhotoBrowser *)photoBrowser;
- (id <LJPhoto>)photoBrowser:(LJPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (void)photoBrowserDidFinishModalPresentation:(LJPhotoBrowser *)photoBrowser;

@end

@interface LJPhotoBrowser : UIViewController <UIScrollViewDelegate>
//{
//    BOOL _isWindow;    // whether to adopt the Window as a background
//}

@property (nonatomic, weak) IBOutlet id<LJPhotoBrowserDelegate> delegate;
@property (nonatomic, assign) BOOL isWindow;
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
