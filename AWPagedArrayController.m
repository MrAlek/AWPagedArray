//
//  AWPagedArrayController.m
//  FluentResourcePaging-example
//
//  Created by Zachary Radke on 5/15/14.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import "AWPagedArrayController.h"

#import "AWPagedArray.h"

@interface AWPagedArrayController () <AWPagedArrayDelegate> {
    void (^_pageLoadingBlock)(NSUInteger, AWPageLoadingCompletionHandler);
    NSRecursiveLock *_lock;
    NSMutableDictionary *_completionHandlersForPages;
}
@end

@implementation AWPagedArrayController

- (instancetype)initWithPagedArray:(AWPagedArray *)pagedArray pageLoadingBlock:(void (^)(NSUInteger, AWPageLoadingCompletionHandler))pageLoadingBlock {
    NSParameterAssert(pagedArray);
    NSParameterAssert(pageLoadingBlock);
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _pagedArray = [pagedArray copy];
    _pagedArray.delegate = self;
    _pageLoadingBlock = [pageLoadingBlock copy];
    _completionHandlersForPages = [NSMutableDictionary dictionary];
    _lock = [[NSRecursiveLock alloc] init];
    
    return self;
}
- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"Please use the designated initializer (%@) instead.", NSStringFromSelector(@selector(initWithPagedArray:pageLoadingBlock:))];
    return nil;
}
- (AWPagedArray *)pagedArray {
    // Make a copy and unset the delegate to free it from affecting this controller.
    AWPagedArray *pagedArrayCopy = [_pagedArray copy];
    pagedArrayCopy.delegate = nil;
    
    return pagedArrayCopy;
}
- (NSArray *)allObjects {
    return (NSArray *)_pagedArray;
}
- (NSUInteger)loadedObjectCount {
    NSUInteger count = 0;
    
    [_lock lock];
    for (NSArray *page in [_pagedArray.pages allValues]) {
        count += page.count;
    }
    [_lock unlock];
    
    return count;
}
- (BOOL)isLoadingObjectAtIndex:(NSUInteger)index {
    BOOL isLoading = NO;
    
    [_lock lock];
    NSUInteger page = [_pagedArray pageForIndex:index];
    isLoading = (_completionHandlersForPages[@(page)] != nil);
    [_lock unlock];
    
    return isLoading;
}
- (void)loadObjectAtIndex:(NSUInteger)index {
    [self _tryLoadingContentForPage:[_pagedArray pageForIndex:index]];
}

#pragma mark - AWPagedArrayDelegate
- (void)pagedArray:(AWPagedArray *)pagedArray willAccessIndex:(NSUInteger)index returnObject:(__autoreleasing id *)returnObject {
    if (self.shouldLoadPagesAutomatically) {
        if ([*returnObject isEqual:_pagedArray.placeholderObject]) {
            [self _tryLoadingContentForPage:[_pagedArray pageForIndex:index]];
        } else {
            [self _tryPreloadingObjectAtIndex:index];
        }
    }
}

#pragma mark - Private
- (void)_tryPreloadingObjectAtIndex:(NSUInteger)index {
    NSUInteger currentPage = [_pagedArray pageForIndex:index];
    NSUInteger preloadIndex = MIN(self.automaticPreloadIndexMargin, _pagedArray.objectsPerPage);
    NSUInteger preloadPage = [_pagedArray pageForIndex:index+preloadIndex];
    
    if (preloadPage > currentPage && preloadPage <= _pagedArray.numberOfPages) {
        [self _tryLoadingContentForPage:preloadPage];
    }
}
- (void)_tryLoadingContentForPage:(NSUInteger)page {
    if (!_pagedArray.pages[@(page)] && !_completionHandlersForPages[@(page)]) {
        [self _loadContentForPage:page];
    }
}
- (void)_loadContentForPage:(NSUInteger)page {
    [_lock lock];
    NSIndexSet *indexes = [_pagedArray indexSetForPage:page];
    
    __weak typeof(self) weakSelf = self;
    AWPageLoadingCompletionHandler completionHandler = ^(NSArray *fetchedObjects, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _loadingCompletedForPage:page objects:fetchedObjects error:error];
    };
    _completionHandlersForPages[@(page)] = completionHandler;
    
    id<AWPagedArrayControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controller:willLoadObjectsAtIndexes:)]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [delegate controller:self willLoadObjectsAtIndexes:indexes];
        }];
    }
    
    _pageLoadingBlock(page, completionHandler);
    [_lock unlock];
}
- (void)_loadingCompletedForPage:(NSUInteger)page objects:(NSArray *)objects error:(NSError *)error {
    [_lock lock];
    
    if (objects) {
        [_pagedArray setObjects:objects forPage:page];
    }
    
    [_completionHandlersForPages removeObjectForKey:@(page)];
    [_lock unlock];
    
    id<AWPagedArrayControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controller:didLoadObjectsAtIndexes:error:)]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [delegate controller:self didLoadObjectsAtIndexes:[_pagedArray indexSetForPage:page] error:error];
        }];
    }
}


@end
