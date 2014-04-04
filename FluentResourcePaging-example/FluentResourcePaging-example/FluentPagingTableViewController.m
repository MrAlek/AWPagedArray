//
//  FluentPagingTableViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingTableViewController.h"
#import "DataController.h"

const NSUInteger FluentPagingTablePreloadMargin = 5;

@interface FluentPagingTableViewController ()<DataControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation FluentPagingTableViewController
@synthesize dataController = _dataController;

#pragma mark - Accessors
- (void)setDataController:(DataController *)dataController {
    
    if (dataController != _dataController) {
        _dataController = dataController;
        _dataController.delegate = self;
        _dataController.shouldLoadAutomatically = YES;
        _dataController.automaticPreloadMargin = self.preloadSwitch.on ? FluentPagingTablePreloadMargin : 0;
        
        if ([self isViewLoaded]) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - User interaction
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataController.automaticPreloadMargin = sender.on ? FluentPagingTablePreloadMargin : 0;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataController.dataObjects.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id data = self.dataController.dataObjects[indexPath.row];
    
    if ([data isKindOfClass:[NSNumber class]]) {
        cell.textLabel.text = [data description];
    } else {
        cell.textLabel.text = nil;
    }
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.tableView beginUpdates];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [self.tableView endUpdates];
}

@end
