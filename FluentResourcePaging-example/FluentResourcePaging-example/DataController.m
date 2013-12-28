//
//  DataController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "DataController.h"

const NSUInteger DataControllerDefaultPageSize = 20;
const NSUInteger DataControllerDataCount = 200;
const NSTimeInterval DataControllerOperationDuration = 0.3;

@implementation DataController {
    NSMutableDictionary *_dataPages;
    NSOperationQueue *_operationQueue;
    NSMutableDictionary *_dataLoadingOperations;
}

#pragma mark - Cleanup
- (void)dealloc {
    [_operationQueue.operations makeObjectsPerformSelector:@selector(cancel)];
}

#pragma mark - Initialization
- (instancetype)init {
    return [self initWithPageSize:DataControllerDefaultPageSize];
}
- (instancetype)initWithPageSize:(NSUInteger)pageSize {

    self = [super init];
    if (self) {
        _dataCount = DataControllerDataCount;
        _pageSize = pageSize;
        _dataPages = [NSMutableDictionary dictionary];
        _dataLoadingOperations = [NSMutableDictionary dictionary];
        _operationQueue = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - Accessors
- (NSNumber *)dataAtIndex:(NSUInteger)index {
    
    NSUInteger page = [self pageForIndex:index];
    NSArray *dataPage = _dataPages[@(page)];
    
    if (!dataPage && self.shouldLoadAutomatically) {
        [self setNeedsloadDataForPage:page];
    }
    
    [self preloadNextPageIfNeededForOriginalIndex:index];
    
    return dataPage[index%_pageSize];
}
- (NSUInteger)loadedCount {
    return _dataPages.count*_pageSize;
}

#pragma mark - Other public methods
- (BOOL)isLoadingDataAtIndex:(NSUInteger)index {
    return (_dataLoadingOperations[@([self pageForIndex:index])]);
}
- (void)loadDataAtIndex:(NSUInteger)index {
    [self setNeedsloadDataForPage:[self pageForIndex:index]];
}

#pragma mark - Private methods
- (NSUInteger)pageForIndex:(NSUInteger)index {
    return index/_pageSize;
}
- (NSIndexSet *)indexSetForPage:(NSUInteger)page {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(page*_pageSize, _pageSize)];
}
- (void)setNeedsloadDataForPage:(NSUInteger)page {
    
    if (!_dataPages[@(page)] && !_dataLoadingOperations[@(page)]) {
        // Don't load data if there already is a loading operation in progress
        [self loadDataForPage:page];
    }
}
- (void)loadDataForPage:(NSUInteger)page {
    
    NSIndexSet *indexes = [self indexSetForPage:page];
    
    NSOperation *loadingOperation = [self loadingOperationForPage:page indexes:indexes];
    _dataLoadingOperations[@(page)] = loadingOperation;
    
    [self.delegate dataController:self willLoadDataAtIndexes:indexes];
    [_operationQueue addOperation:loadingOperation];
}
- (NSOperation *)loadingOperationForPage:(NSUInteger)page indexes:(NSIndexSet *)indexes {
    // Load new data, remember to not retain self in block since we store the operation
    __weak typeof(self) weakSelf = self;
    NSOperation *loadingOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        // Simulate waiting (in background)
        [NSThread sleepForTimeInterval:DataControllerOperationDuration];
        
        // Now go to main queue and deliver
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            typeof(self) strongSelf = weakSelf;

            [strongSelf->_dataLoadingOperations removeObjectForKey:@(page)];
            
            // Generate data
            NSMutableArray *dataPage = [NSMutableArray array];
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [dataPage addObject:@(idx+1)];
            }];
            strongSelf->_dataPages[@(page)] = dataPage;
            
            [self.delegate dataController:self didLoadDataAtIndexes:indexes];
        }];
    }];

    return loadingOperation;
}
- (void)preloadNextPageIfNeededForOriginalIndex:(NSUInteger)index {
    
    if (self.shouldLoadAutomatically && index%_pageSize+self.automaticPreloadMargin >= _pageSize) {
        NSUInteger preloadPage = [self pageForIndex:index+self.automaticPreloadMargin];
        
        if (preloadPage < [self numberOfPages] && !_dataPages[@(preloadPage)]) {
            [self setNeedsloadDataForPage:preloadPage];
        }
    }
}
- (NSUInteger)numberOfPages {
    return ceil(_dataCount/(float)_pageSize);
}

@end
