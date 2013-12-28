//
//  FluentPagingCollectionViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingCollectionViewController.h"
#import "DataController.h"
#import "LabelCollectionViewCell.h"

const NSUInteger FluentPagingCollectionViewPreloadMargin = 10;

@interface FluentPagingCollectionViewController ()<DataControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@property (nonatomic) DataController *dataController;
@end

@implementation FluentPagingCollectionViewController

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _dataController = nil;
    [self.collectionView reloadData];
}

#pragma mark - Accessors
- (DataController *)dataController {
    
    if (!_dataController) {
        _dataController = [[DataController alloc] initWithPageSize:40];
        _dataController.delegate = self;
        _dataController.shouldLoadAutomatically = YES;
        _dataController.automaticPreloadMargin = self.preloadSwitch.on ? FluentPagingCollectionViewPreloadMargin : 0;
    }
    
    return _dataController;
}

#pragma mark - User interaction
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataController.automaticPreloadMargin = sender.on ? FluentPagingCollectionViewPreloadMargin : 0;
}

#pragma mark - Collection view data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataController.dataCount;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    LabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSNumber *data = [self.dataController dataAtIndex:indexPath.row];
    
    cell.label.text = data ? [NSString stringWithFormat:@"%d", data.intValue] : nil;
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
}
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [self.collectionView performBatchUpdates:^{
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
        }];
    } completion:^(BOOL finished) {
        
    }];
}

@end
