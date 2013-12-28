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
    NSMutableDictionary *_dataLoadingOperations;
}

#pragma mark - Cleanup
- (void)dealloc {
    [_dataLoadingOperations enumerateKeysAndObjectsUsingBlock:^(id key, NSOperation *operation, BOOL *stop) {
        [operation cancel];
    }];
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
    }
    return self;
}

#pragma mark - Accessors
- (NSNumber *)dataAtIndex:(NSUInteger)index {
    
    NSUInteger page = [self pageForIndex:index];
    NSArray *dataPage = _dataPages[@(page)];
    
    if (!dataPage) {
        [self setNeedsloadDataForPage:page];
    }
    
    return dataPage[index%_pageSize];
}

#pragma mark - Private methods
- (NSUInteger)pageForIndex:(NSUInteger)index {
    return index/_pageSize;
}
- (NSIndexSet *)indexSetForPage:(NSUInteger)page {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(page*_pageSize, _pageSize)];
}
- (void)setNeedsloadDataForPage:(NSUInteger)page {
    
    if (!_dataLoadingOperations[@(page)]) {
        // Don't load data if there already is a loading operation in progress
        [self loadDataForPage:page];
    }
}
- (void)loadDataForPage:(NSUInteger)page {
    
    NSIndexSet *indexes = [self indexSetForPage:page];
    
    NSOperation *loadingOperation = [self loadingOperationForPage:page indexes:indexes];
    _dataLoadingOperations[@(page)] = loadingOperation;
    
    [self.delegate dataController:self willLoadDataAtIndexes:indexes];
    [[NSOperationQueue mainQueue] addOperation:loadingOperation];
}
- (NSOperation *)loadingOperationForPage:(NSUInteger)page indexes:(NSIndexSet *)indexes {
    // Load new data, remember to not retain self in block since we store the operation
    __weak typeof(self) weakSelf = self;
    NSOperation *loadingOperation = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) strongSelf = weakSelf;
        
        // Simulate waiting
        [NSThread sleepForTimeInterval:DataControllerOperationDuration];
        
        strongSelf->_dataLoadingOperations[@(page)] = nil;
        
        // Generate data
        NSMutableArray *dataPage = [NSMutableArray array];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [dataPage addObject:@(idx+1)];
        }];
        strongSelf->_dataPages[@(page)] = dataPage;
        
        [self.delegate dataController:self didLoadDataAtIndexes:indexes];
    }];

    return loadingOperation;
}

@end
