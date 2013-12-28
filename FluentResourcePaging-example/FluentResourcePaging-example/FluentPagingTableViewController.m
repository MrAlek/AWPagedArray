//
//  FluentPagingTableViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingTableViewController.h"
#import "DataController.h"

@interface FluentPagingTableViewController ()<DataControllerDelegate>
@property (nonatomic) DataController *dataController;
@end

@implementation FluentPagingTableViewController

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _dataController = nil;
    [self.tableView reloadData];
}

#pragma mark - Accessors
- (DataController *)dataController {
    
    if (!_dataController) {
        _dataController = [DataController new];
        _dataController.delegate = self;
        _dataController.shouldLoadAutomatically = YES;
    }
    
    return _dataController;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataController.dataCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSNumber *data = [self.dataController dataAtIndex:indexPath.row];
    
    cell.textLabel.text = data ? [NSString stringWithFormat:@"Content data %d", data.intValue] : nil;
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
}
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.tableView beginUpdates];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [self.tableView endUpdates];
}

@end
