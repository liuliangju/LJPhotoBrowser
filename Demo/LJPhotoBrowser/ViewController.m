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

@interface ViewController () {
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
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"LJPhotoBrowserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = _segmentedControl.selectedSegmentIndex == 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    cell.textLabel.text = @"test";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LJPhotoBrowser *browser = [[LJPhotoBrowser alloc]init];
    
    NSInteger selectedSegmentIndex = _segmentedControl.selectedSegmentIndex;
    
    switch (selectedSegmentIndex) {
        case 0: { // Push
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
            [self.navigationController pushViewController:browser animated:YES];
            break;
        }
    }
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark Data 
- (void)loadAssets {
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
