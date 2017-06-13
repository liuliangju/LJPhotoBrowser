//
//  ViewController.m
//  LJPhotoBrowser
//
//  Created by liuliangju on 5/30/17.
//  Copyright © 2017 https://liuliangju.github.io. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "LJPhotoBrowser.h"
#import "LJCommonMacro.h"

@interface ViewController ()<LJPhotoBrowserDelegate> {
    UISegmentedControl *_segmentedControl;
    NSMutableArray *_selections;
}

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
//@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
//@property (nonatomic, strong) NSMutableArray *assets;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Push", @"Modal", @"Full", nil]];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if (SYSTEM_VERSION_LESS_THAN(@"7")) {
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    }
#endif
    _segmentedControl.selectedSegmentIndex = 0;
    [_segmentedControl addTarget:self action:@selector(segmentChange) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_segmentedControl];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)segmentChange {
    [self.tableView reloadData];
}

#pragma mark View

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"LJPhotoBrowserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = _segmentedControl.selectedSegmentIndex == 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    // Configure
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = @"Multiple photos and video";
            break;
        }
        
        case 1: {
            cell.textLabel.text = @"Single video";
            cell.detailTextLabel.text = @"with auto-play";
            break;
        }
        default: break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    LJPhoto *photo;
    BOOL autoPlayOnAppear = NO;
    switch (indexPath.row) {
        case 0: {
            // Local Photos and Videos
//            photo = [LJPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"]]];
//            CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
//            photo.imageFrame = rectInTableView;
//            photo.isHaveOriginalImg = YES;
//            photo.totalSize = @"1.6M";
//            [photos addObject:photo];
//            photo = [LJPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo5" ofType:@"jpg"]]];
//            [photos addObject:photo];
//            photo = [LJPhoto photoWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"photo11" ofType:@"gif"]]];
//            
            photo = [LJPhoto photoWithURL:[NSURL URLWithString:@"http://cochat.cn/file/3jBxTu6FF82XUCX0LwLgOZ.jpg"]];
//            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo11" ofType:@"gif"]]];
            photo.isHaveOriginalImg = YES;
            photo.totalSize = @"1.6M";
            [photos addObject:photo];
//            photo = [LJPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo6" ofType:@"jpg"]]];
//            [photos addObject:photo];
//            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"]]];
//            photo.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]];
//            [photos addObject:photo];
            
            break;
        }
            
        case 1: {
//            photo = [LJPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"]]];
            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"]]];

            photo.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]];
            autoPlayOnAppear = YES;
            [photos addObject:photo];
        }
    }
    self.photos = photos;
    LJPhotoBrowser *browser = [[LJPhotoBrowser alloc]initWithDelegate:self];
    browser.autoPlayOnAppear = autoPlayOnAppear;
    
    NSInteger selectedSegmentIndex = _segmentedControl.selectedSegmentIndex;
    
    switch (selectedSegmentIndex) {
        case 0: { // Push
            [self.navigationController pushViewController:browser animated:YES];
            break;
        }
        case 1: { // Modal
         
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:nc animated:YES completion:nil];
            break;
        }
        default: { // Transition
            browser.isWindow = YES;
            browser.animationTime = 0.3;
            [browser showPhotoBrowserWithFirstPhoto:self.photos[0]];
            break;
        }
    }
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(LJPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (void)photoBrowser:(LJPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (LJPhoto *)photoBrowser:(LJPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count)
        return [self.photos objectAtIndex:index];
    return nil;
}

//- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
//    if (index < _thumbs.count)
//        return [_thumbs objectAtIndex:index];
//    return nil;
//}



#pragma mark Data 
- (void)loadAssets {
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
