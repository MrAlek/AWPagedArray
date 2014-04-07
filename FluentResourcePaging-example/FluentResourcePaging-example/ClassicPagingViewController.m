//
//  ClassicPagingViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "ClassicPagingViewController.h"
#import "DataProvider.h"

typedef NS_ENUM(NSInteger, ClassicPagingViewControllerLoadingStyle) {
    ClassicPagingViewControllerLoadingStyleManual,
    ClassicPagingViewControllerLoadingStyleAutomatic
};

const NSUInteger ClassicPagingTablePreloadMargin = 5;

@interface ClassicPagingViewController ()<DataProviderDelegate>
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
        [_dataProvider loadDataForIndex:0];
        _dataProvider.delegate = self;
        
        if ([self isViewLoaded]) {
            
            _dataProvider.shouldLoadAutomatically = self.preloadSwitch.on;
            _dataProvider.automaticPreloadMargin = self.preloadSwitch.on ? ClassicPagingTablePreloadMargin : 0;
            
            [self.tableView reloadData];
        }
    }
}
- (void)setLoadingStyle:(ClassicPagingViewControllerLoadingStyle)loadingStyle {
    
    _loadingStyle = loadingStyle;
    self.preloadSwitch.enabled = (loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic);
    self.dataProvider.shouldLoadAutomatically = (loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic);
    
    [self.tableView reloadData];
}

#pragma mark - User interaction
- (IBAction)loadingStyleSegmentChanged:(UISegmentedControl *)sender {
    self.loadingStyle = sender.selectedSegmentIndex;
}
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataProvider.automaticPreloadMargin = sender.on ? ClassicPagingTablePreloadMargin : 0;
}

#pragma mark - Table view
#pragma mark data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.dataProvider.loadedCount+1, self.dataProvider.dataObjects.count);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DataCellIdentifier = @"data cell";
    static NSString *LoadMoreCellIdentifier = @"load more cell";
    static NSString *LoaderCellIdentifier = @"loader cell";
    
    NSString *cellIdentifier;
    NSUInteger index = indexPath.row;
    
    if (index < self.dataProvider.loadedCount) {
        cellIdentifier = DataCellIdentifier;
    } else if ([self.dataProvider isLoadingDataAtIndex:index] || self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic) {
        cellIdentifier = LoaderCellIdentifier;
        _loaderCellIndexPath = indexPath;
    } else {
        cellIdentifier = LoadMoreCellIdentifier;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (cellIdentifier == DataCellIdentifier) {
        id data = self.dataProvider.dataObjects[indexPath.row];
        
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
    
    if (indexPath.row == self.dataProvider.loadedCount) {
        [self.dataProvider loadDataForIndex:indexPath.row];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic && [indexPath isEqual:_loaderCellIndexPath]) {
        [self.dataProvider loadDataForIndex:indexPath.row];
    }
}

#pragma mark - Data controller delegate
- (void)dataProvider:(DataProvider *)dataProvider willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleManual) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:dataProvider.loadedCount inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}
- (void)dataProvider:(DataProvider *)dataProvider didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[_loaderCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < dataProvider.dataObjects.count-1) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    [self.tableView endUpdates];
}

@end
