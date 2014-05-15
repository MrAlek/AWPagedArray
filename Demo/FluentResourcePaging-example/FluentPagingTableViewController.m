//
//  FluentPagingTableViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingTableViewController.h"
#import "DataProvider.h"
#import "AWPagedArray.h"

const NSUInteger FluentPagingTablePreloadMargin = 5;

@interface FluentPagingTableViewController ()<AWPagedArrayControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation FluentPagingTableViewController
@synthesize dataProvider = _dataProvider;

#pragma mark - Accessors
- (void)setDataProvider:(DataProvider *)dataProvider {
    
    if (dataProvider != _dataProvider) {
        _dataProvider = dataProvider;
        _dataProvider.delegate = self;
        _dataProvider.shouldLoadPagesAutomatically = YES;
        _dataProvider.automaticPreloadIndexMargin = self.preloadSwitch.on ? FluentPagingTablePreloadMargin : 0;
        
        if ([self isViewLoaded]) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - User interaction
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataProvider.automaticPreloadIndexMargin = sender.on ? FluentPagingTablePreloadMargin : 0;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataProvider.allObjects.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id dataObject = self.dataProvider.allObjects[indexPath.row];
    [self _configureCell:cell forDataObject:dataObject];
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)controller:(AWPagedArrayController *)controller didLoadObjectsAtIndexes:(NSIndexSet *)indexes error:(NSError *)error {
    if (error) {
        return;
    }
    
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            [indexPathsToReload addObject:indexPath];
        }
    }];

    if (indexPathsToReload.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Private methods
- (void)_configureCell:(UITableViewCell *)cell forDataObject:(id)dataObject {
    
    if ([dataObject isEqual:self.dataProvider.pagedArray.placeholderObject]) {
        cell.textLabel.text = nil;
    } else {
        cell.textLabel.text = [dataObject description];
    }
}

@end
