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
@end

@implementation FluentPagingCollectionViewController
@synthesize dataController = _dataController;

#pragma mark - Accessors
- (void)setDataController:(DataController *)dataController {
    
    if (dataController != _dataController) {
        _dataController = dataController;
        _dataController.delegate = self;
        _dataController.shouldLoadAutomatically = YES;
        _dataController.automaticPreloadMargin = self.preloadSwitch.on ? FluentPagingCollectionViewPreloadMargin : 0;
        
        if ([self isViewLoaded]) {
            [self.collectionView reloadData];
        }
    }
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
    return self.dataController.dataObjects.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    LabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id data = self.dataController.dataObjects[indexPath.row];
    [self _configureCell:cell forData:data animated:NO];
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
}
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        if ([self.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
            
            LabelCollectionViewCell *cell = (LabelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [self _configureCell:cell forData:dataController.dataObjects[index] animated:YES];
        }
    }];
}

#pragma mark - Private methods
- (void)_configureCell:(LabelCollectionViewCell *)cell forData:(id)data animated:(BOOL)animated {
    
    if ([data isKindOfClass:[NSNumber class]]) {
        
        cell.label.text = [data description];

        if (animated) {
            cell.label.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                cell.label.alpha = 1;
            }];
        }
    } else {
        cell.label.text = nil;
    }
}

@end
