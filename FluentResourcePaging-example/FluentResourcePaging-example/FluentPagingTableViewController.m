//
//  FluentPagingTableViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingTableViewController.h"
#import "DataProvider.h"

const NSUInteger FluentPagingTablePreloadMargin = 5;

@interface FluentPagingTableViewController ()<DataProviderDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation FluentPagingTableViewController
@synthesize dataProvider = _dataProvider;

#pragma mark - Accessors
- (void)setDataProvider:(DataProvider *)dataProvider {
    
    if (dataProvider != _dataProvider) {
        _dataProvider = dataProvider;
        _dataProvider.delegate = self;
        _dataProvider.shouldLoadAutomatically = YES;
        _dataProvider.automaticPreloadMargin = self.preloadSwitch.on ? FluentPagingTablePreloadMargin : 0;
        
        if ([self isViewLoaded]) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - User interaction
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataProvider.automaticPreloadMargin = sender.on ? FluentPagingTablePreloadMargin : 0;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataProvider.dataObjects.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id data = self.dataProvider.dataObjects[indexPath.row];
    
    if ([data isKindOfClass:[NSNumber class]]) {
        cell.textLabel.text = [data description];
    } else {
        cell.textLabel.text = nil;
    }
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataProvider:(DataProvider *)dataProvider didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.tableView beginUpdates];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [self.tableView endUpdates];
}

@end
