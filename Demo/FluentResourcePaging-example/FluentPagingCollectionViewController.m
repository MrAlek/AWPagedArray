//
//  FluentPagingCollectionViewController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "FluentPagingCollectionViewController.h"
#import "DataProvider.h"
#import "AWPagedArray.h"
#import "LabelCollectionViewCell.h"

const NSUInteger FluentPagingCollectionViewPreloadMargin = 10;

@interface FluentPagingCollectionViewController ()<AWPagedArrayControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *preloadSwitch;
@end

@implementation FluentPagingCollectionViewController
@synthesize dataProvider = _dataProvider;

#pragma mark - Accessors
- (void)setDataProvider:(DataProvider *)dataProvider {
    
    if (dataProvider != _dataProvider) {
        _dataProvider = dataProvider;
        _dataProvider.delegate = self;;
        _dataProvider.shouldLoadPagesAutomatically = YES;
        _dataProvider.automaticPreloadIndexMargin = self.preloadSwitch.on ? FluentPagingCollectionViewPreloadMargin : 0;
        
        if ([self isViewLoaded]) {
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - User interaction
- (IBAction)preloadSwitchChanged:(UISwitch *)sender {
    self.dataProvider.automaticPreloadIndexMargin = sender.on ? FluentPagingCollectionViewPreloadMargin : 0;
}

#pragma mark - Collection view data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataProvider.allObjects.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"data cell";
    
    LabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id data = self.dataProvider.allObjects[indexPath.row];
    [self _configureCell:cell forDataObject:data animated:NO];
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)controller:(AWPagedArrayController *)controller didLoadObjectsAtIndexes:(NSIndexSet *)indexes error:(NSError *)error {
    if (error) {
        return;
    }
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        if ([self.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
            
            LabelCollectionViewCell *cell = (LabelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [self _configureCell:cell forDataObject:controller.allObjects[index] animated:YES];
        }
    }];
}

#pragma mark - Private methods
- (void)_configureCell:(LabelCollectionViewCell *)cell forDataObject:(id)dataObject animated:(BOOL)animated {
    
    if ([dataObject isKindOfClass:[NSNumber class]]) {
        
        cell.label.text = [dataObject description];

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
