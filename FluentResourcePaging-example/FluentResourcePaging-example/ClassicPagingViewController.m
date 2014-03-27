//
//  ClassicPagingViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "ClassicPagingViewController.h"
#import "DataController.h"

typedef NS_ENUM(NSInteger, ClassicPagingViewControllerLoadingStyle) {
    ClassicPagingViewControllerLoadingStyleManual,
    ClassicPagingViewControllerLoadingStyleAutomatic
};

const NSUInteger ClassicPagingTablePreloadMargin = 5;

@interface ClassicPagingViewController ()<DataControllerDelegate>
@property (nonatomic) DataController *dataController;
@property (nonatomic) ClassicPagingViewControllerLoadingStyle loadingStyle;
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation ClassicPagingViewController {
    NSIndexPath *_loaderCellIndexPath;
}

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
        [_dataController loadDataAtIndex:0];
        _dataController.shouldLoadAutomatically = self.preloadSwitch.on;
        _dataController.automaticPreloadMargin = self.preloadSwitch.on ? ClassicPagingTablePreloadMargin : 0;
    }
    
    return _dataController;
}
- (void)setLoadingStyle:(ClassicPagingViewControllerLoadingStyle)loadingStyle {
    
    _loadingStyle = loadingStyle;
    _dataController = nil;
    [self.tableView reloadData];
}

#pragma mark - User interaction
- (IBAction)loadingStyleSegmentChanged:(UISegmentedControl *)sender {
    self.loadingStyle = sender.selectedSegmentIndex;
}
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataController.shouldLoadAutomatically = sender.on;
    self.dataController.automaticPreloadMargin = sender.on ? 5 : 0;
}

#pragma mark - Table view
#pragma mark data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.dataController.loadedCount+1, self.dataController.dataCount);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DataCellIdentifier = @"data cell";
    static NSString *LoadMoreCellIdentifier = @"load more cell";
    static NSString *LoaderCellIdentifier = @"loader cell";
    
    NSString *cellIdentifier;
    NSUInteger index = indexPath.row;
    
    if (index < self.dataController.loadedCount) {
        cellIdentifier = DataCellIdentifier;
    } else if ([self.dataController isLoadingDataAtIndex:index] || self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic) {
        cellIdentifier = LoaderCellIdentifier;
        _loaderCellIndexPath = indexPath;
    } else {
        cellIdentifier = LoadMoreCellIdentifier;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSNumber *data = [self.dataController dataAtIndex:index];
    if (data) {
        cell.textLabel.text = [NSString stringWithFormat:@"Content data %ld", data.integerValue];
    }
    
    return cell;
}

#pragma mark delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == self.dataController.loadedCount) {
        [self.dataController loadDataAtIndex:indexPath.row];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleAutomatic && [indexPath isEqual:_loaderCellIndexPath]) {
        [self.dataController loadDataAtIndex:indexPath.row];
    }
}

#pragma mark - Data controller delegate
- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    if (self.loadingStyle == ClassicPagingViewControllerLoadingStyleManual) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:dataController.loadedCount inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[_loaderCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < dataController.dataCount-1) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    [self.tableView endUpdates];
}

@end
