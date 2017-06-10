//
//  LJPhotoBrowser.m
//  LJPhotoBrowser
//
//  Created by liangju on 5/31/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "LJPhotoBrowser.h"
#import "LJCommonMacro.h"
#import "LJPhotoBrowserPrivate.h"

#define PADDING                  10

static void *LJVideoPlayerObservation = &LJVideoPlayerObservation;

@interface LJPhotoBrowser ()

@end

@implementation LJPhotoBrowser

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_initialisation];
    }
    return self;
}

- (void)setIsWindow:(BOOL)isWindow {
    _isWindow = isWindow;
}

- (instancetype)initWithDelegate:(id<LJPhotoBrowserDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    self = [super init];
    if (self) {
        _fixedPhotosArray = photosArray;
    }
    return self;
}

- (void)showPhotoBrowserWithFirstPhoto:(LJPhoto *)photo {
    if (photo.image) {
        self.overlayWindow.hidden = NO;
        _avatarImageView.image = photo.image;
        CGRect fromFrame = [self calcPhotoFrame:photo];
        CGRect toFrame = [self calcToFrame:photo];
        _avatarImageView.frame = fromFrame;
        
        [UIView animateWithDuration:0.9 animations:^{
            _backgroundView.alpha = 1;
            _avatarImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            //动画有问题 需要调整
            //        if ([self isVerticallLargerPhoto]) {
            //            self.avatarImageView.frame = [self verticallLargerImageViewFrame];
            //        }
            // 动画执行完了之后隐藏替身
            //        _avatarImageView.hidden = YES;
            
        }];
    } else {
        
        // photo.image 不存在直接下载图片
    }
}

// frame转换
- (CGRect)calcPhotoFrame:(LJPhoto *)photo {
    CGRect photoFrame = photo.imageFrame;
    if (CGRectEqualToRect(photoFrame, CGRectZero)) {
        return CGRectZero;
    }
    CGRect fromFrame = CGRectMake(photoFrame.origin.x, photoFrame.origin.y, photoFrame.size.width, photoFrame.size.height);
    return fromFrame;
}

- (CGRect)calcToFrame:(LJPhoto *)photo {
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

- (void)viewWillAppear:(BOOL)animated {
    if (_isWindow) {
        [self.view addSubview:_backgroundView];
        [self.view addSubview:_avatarImageView];
    }
}

- (void)p_initialisation {
//    if (!_isWindow) {
//        self.hidesBottomBarWhenPushed = YES;
//    }
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _currentVideoIndex = NSUIntegerMax;
    _performingLayout = NO; // Reset on view did appear
    _rotating = NO;
    _viewIsActive = NO;
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];
    _thumbPhotos = [[NSMutableArray alloc] init];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _backgroundView = [[UIView alloc] initWithFrame:kLJPhotoBrowserScreenBounds];
    _backgroundView.backgroundColor = [UIColor blackColor];
    _backgroundView.alpha = 0;
    
    // 用于查看图片的UIImageView
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.backgroundColor = [UIColor clearColor];
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.view.backgroundColor = [UIColor redColor];
    
    
}


- (UIWindow *)overlayWindow {
    if (!_overlayWindow) {
        _overlayWindow = [[UIWindow alloc]init];
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.windowLevel = UIWindowLevelStatusBar; // 可盖住状态栏
        _overlayWindow.frame = [[[UIApplication sharedApplication] delegate] window].frame;
        _overlayWindow.rootViewController = self;
        [_overlayWindow makeKeyAndVisible];
    }
    return _overlayWindow;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
