//
//  DataController.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "DataController.h"
#import "AWPagedArray.h"

const NSUInteger DataControllerDefaultPageSize = 20;
const NSUInteger DataControllerDataCount = 200;
const NSTimeInterval DataControllerOperationDuration = 0.3;

@interface DataController () <AWPagedArrayDelegate> @end

@implementation DataController {
    AWPagedArray *_pagedArray;
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
        _pagedArray = [[AWPagedArray alloc] initWithCount:DataControllerDataCount objectsPerPage:DataControllerDefaultPageSize];
        _pagedArray.delegate = self;
        _dataLoadingOperations = [NSMutableDictionary dictionary];
        _operationQueue = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - Accessors
- (NSUInteger)loadedCount {
    return _pagedArray.pages.count*_pagedArray.objectsPerPage;
}
- (NSUInteger)pageSize {
    return _pagedArray.objectsPerPage;
}
- (NSArray *)dataObjects {
    return (NSArray *)_pagedArray;
}

#pragma mark - Other public methods
- (BOOL)isLoadingDataAtIndex:(NSUInteger)index {
    return (_dataLoadingOperations[@([_pagedArray pageForIndex:index])]);
}
- (void)loadDataForIndex:(NSUInteger)index {
    [self setShouldLoadDataForPage:[_pagedArray pageForIndex:index]];
}

#pragma mark - Private methods
- (NSIndexSet *)indexSetForPage:(NSUInteger)page {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange((page-1)*_pagedArray.objectsPerPage, _pagedArray.objectsPerPage)];
}
- (void)setShouldLoadDataForPage:(NSUInteger)page {
    
    if (!_pagedArray.pages[@(page)] && !_dataLoadingOperations[@(page)]) {
        // Don't load data if there already is a loading operation in progress
        [self loadDataForPage:page];
    }
}
- (void)loadDataForPage:(NSUInteger)page {
    
    NSIndexSet *indexes = [self indexSetForPage:page];
    
    NSOperation *loadingOperation = [self loadingOperationForPage:page indexes:indexes];
    _dataLoadingOperations[@(page)] = loadingOperation;
    
    if ([self.delegate respondsToSelector:@selector(dataController:willLoadDataAtIndexes:)]) {
        [self.delegate dataController:self willLoadDataAtIndexes:indexes];
    }
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
            [strongSelf->_pagedArray setObjects:dataPage forPage:page];
            
            if ([strongSelf.delegate respondsToSelector:@selector(dataController:didLoadDataAtIndexes:)]) {
                [strongSelf.delegate dataController:self didLoadDataAtIndexes:indexes];
            }
        }];
    }];

    return loadingOperation;
}
- (void)preloadNextPageIfNeededForIndex:(NSUInteger)index {
    
    if (!self.shouldLoadAutomatically) {
        return;
    }
    
    NSUInteger currentPage = [_pagedArray pageForIndex:index];
    NSUInteger preloadPage = [_pagedArray pageForIndex:index+self.automaticPreloadMargin];
    
    if (preloadPage > currentPage && preloadPage < _pagedArray.numberOfPages) {
        [self setShouldLoadDataForPage:preloadPage];
    }
}

#pragma mark - Paged array delegate
- (void)pagedArray:(AWPagedArray *)pagedArray willAccessIndex:(NSUInteger)index value:(id)value {

    if ([value isKindOfClass:[NSNull class]] && self.shouldLoadAutomatically) {
        [self setShouldLoadDataForPage:[pagedArray pageForIndex:index]];
    } else {
        [self preloadNextPageIfNeededForIndex:index];
    }
}

@end
