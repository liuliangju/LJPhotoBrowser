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
    return 5;
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
            cell.textLabel.text = @"Single photo";
            cell.detailTextLabel.text = @"with caption, no grid button";
            break;
        }
        case 1: {
            cell.textLabel.text = @"Multiple photos and video";
            cell.detailTextLabel.text = @"with captions";
            break;
        }
        case 2: {
            cell.textLabel.text = @"Multiple photo grid";
            cell.detailTextLabel.text = @"showing grid first, nav arrows enabled";
            break;
        }
        case 3: {
            cell.textLabel.text = @"Photo selections";
            cell.detailTextLabel.text = @"selection enabled";
            break;
        }
        case 4: {
            cell.textLabel.text = @"Photo selection grid";
            cell.detailTextLabel.text = @"selection enabled, start at grid";
            break;
        }
        case 5: {
            cell.textLabel.text = @"Web photos";
            cell.detailTextLabel.text = @"photos from web";
            break;
        }
        case 6: {
            cell.textLabel.text = @"Web photo grid";
            cell.detailTextLabel.text = @"showing grid first";
            break;
        }
        case 7: {
            cell.textLabel.text = @"Single video";
            cell.detailTextLabel.text = @"with auto-play";
            break;
        }
        case 8: {
            cell.textLabel.text = @"Web videos";
            cell.detailTextLabel.text = @"showing grid first";
            break;
        }
        case 9: {
            cell.textLabel.text = @"Library photos and videos";
            cell.detailTextLabel.text = @"media from device library";
            break;
        }
        default: break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    LJPhoto *photo, *thumb;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = YES;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    switch (indexPath.row) {
        case 0:
            // Photos
            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
            CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
            photo.imageFrame = rectInTableView;
            [photos addObject:photo];
            // Options
            enableGrid = NO;
            break;
        case 1: {
            // Local Photos and Videos
            photo = [LJPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"]]];
            CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
            photo.imageFrame = rectInTableView;
            [photos addObject:photo];
            photo = [LJPhoto photoWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"photo11" ofType:@"gif"]]];
            [photos addObject:photo];
//            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
//            [photos addObject:photo];
//            photo = [LJPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo3" ofType:@"jpg"]]];
//            [photos addObject:photo];
            break;
        }
    }
    


    
    self.photos = photos;

    LJPhotoBrowser *browser = [[LJPhotoBrowser alloc]init];
//    browser.delegate = self;

    
    NSInteger selectedSegmentIndex = _segmentedControl.selectedSegmentIndex;
    
    switch (selectedSegmentIndex) {
        case 0: { // Push
            LJPhotoBrowser *browser = [[LJPhotoBrowser alloc]initWithDelegate:self];

            
            [self.navigationController pushViewController:browser animated:YES];
            break;
        }
        case 1: { // Modal
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
            //        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:nc animated:YES completion:nil];
            break;
        }
        default: { // Transition
            browser.isWindow = YES;
            UITableViewCell *currentCell = [self.tableView cellForRowAtIndexPath:indexPath];
            [browser showPhotoBrowserWithFirstPhoto:self.photos[0]];
            
            break;
        }
    }
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(LJPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <LJPhoto>)photoBrowser:(LJPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
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
