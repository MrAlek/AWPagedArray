//
//  ClassicPagingViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "ClassicPagingViewController.h"
#import "DataProvider.h"
#import "AWPagedArray.h"

typedef NS_ENUM(NSInteger, ClassicPagingViewControllerLoadingStyle) {
    ClassicPagingViewControllerLoadingStyleManual,
    ClassicPagingViewControllerLoadingStyleAutomatic
};

const NSUInteger ClassicPagingTablePreloadMargin = 5;

@interface ClassicPagingViewController ()<AWPagedArrayControllerDelegate>
@property (nonatomic) ClassicPagingViewControllerLoadingStyle loadingStyle;
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation ClassicPagingViewController {
    NSIndexPath *_loaderCellIndexPath;
}
@synthesize dataProvider = _dataProvider;

#pragma mark - Accessors
- (void)setDataProvider:(DataProvider *)dataProvider {
    
    if (dataProvider != _dataProvider) {
        
        _dataProvider = dataProvider;
        [_dataProvider loadObjectAtIndex:0];
        _dataProvider.delegate = self;
        
        if ([self isViewLoaded]) {
            
            _dataProvider.shouldLoadPagesAutomatically = self.preloadSwitch.on;
            _dataProvider.automaticPreloadIndexMargin = self.preloadSwitch.on ? ClassicPagingTablePreloadMargin : 0;
            
            [self.tableView reloadData];
        }
    }
}
- (void)setLoadingStyle:(ClassicPagingViewControllerLoadingStyle)loadingStyle {
    
    _loadingStyle = loadingStyle;
    self.preloadSwitch.enabled = (loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic);
    self.dataProvider.shouldLoadPagesAutomatically = (loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic);
    
    [self.tableView reloadData];
}

#pragma mark - User interaction
- (IBAction)loadingStyleSegmentChanged:(UISegmentedControl *)sender {
    self.loadingStyle = sender.selectedSegmentIndex;
}
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataProvider.automaticPreloadIndexMargin = sender.on ? ClassicPagingTablePreloadMargin : 0;
}

#pragma mark - Table view
#pragma mark data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.dataProvider.loadedObjectCount+1, self.dataProvider.allObjects.count);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DataCellIdentifier = @"data cell";
    static NSString *LoadMoreCellIdentifier = @"load more cell";
    static NSString *LoaderCellIdentifier = @"loader cell";
    
    NSString *cellIdentifier;
    NSUInteger index = indexPath.row;
    
    if (index < self.dataProvider.loadedObjectCount) {
        cellIdentifier = DataCellIdentifier;
    } else if ([self.dataProvider isLoadingObjectAtIndex:index] || self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic) {
        cellIdentifier = LoaderCellIdentifier;
        _loaderCellIndexPath = indexPath;
    } else {
        cellIdentifier = LoadMoreCellIdentifier;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (cellIdentifier == DataCellIdentifier) {
        id data = self.dataProvider.allObjects[indexPath.row];
        
        if ([data isKindOfClass:[NSNumber class]]) {
            cell.textLabel.text = [data description];
        } else {
            cell.textLabel.text = nil;
        }
    }
    
    return cell;
}

#pragma mark delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == self.dataProvider.loadedObjectCount) {
        [self.dataProvider loadObjectAtIndex:indexPath.row];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic && [indexPath isEqual:_loaderCellIndexPath]) {
        [self.dataProvider loadObjectAtIndex:indexPath.row];
    }
}

#pragma mark - Data controller delegate
- (void)controller:(AWPagedArrayController *)controller willLoadObjectsAtIndexes:(NSIndexSet *)indexes {
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleManual) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:controller.loadedObjectCount inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}
- (void)controller:(AWPagedArrayController *)controller didLoadObjectsAtIndexes:(NSIndexSet *)indexes error:(NSError *)error {
    if (error) {
        return;
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[_loaderCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < controller.allObjects.count-1) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    [self.tableView endUpdates];
}

@end
