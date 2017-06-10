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

- (instancetype)initWithDelegate:(id<LJPhotoBrowserDelegate>)delegate {
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    self = [self init];
    if (self) {
        _fixedPhotosArray = photosArray;
    }
    return self;
}

- (void)showPhotos:(NSArray *)photos fromIndex:(NSInteger)index {
    
    
}

- (void)p_initialisation {

    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
