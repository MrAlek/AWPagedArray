//
//  DataProvider.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "DataProvider.h"
#import "AWPagedArray.h"
#import "DataLoadingOperation.h"

const NSUInteger DataProviderDefaultPageSize = 20;
const NSUInteger DataProviderDataCount = 200;

@implementation DataProvider {
    NSOperationQueue *_operationQueue;
}

#pragma mark - Initialization
- (instancetype)init {
    return [self initWithPageSize:DataProviderDefaultPageSize];
}
- (instancetype)initWithPageSize:(NSUInteger)pageSize {
    AWPagedArray *pagedArray = [[AWPagedArray alloc] initWithCount:DataProviderDataCount objectsPerPage:pageSize];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    self = [super initWithPagedArray:pagedArray pageLoadingBlock:^(NSUInteger page, AWPageLoadingCompletionHandler completionHandler) {
        DataLoadingOperation *loadingOperation = [[DataLoadingOperation alloc] initWithIndexes:[pagedArray indexSetForPage:page]];
        
        __weak typeof(loadingOperation) weakOperation = loadingOperation;
        [loadingOperation setCompletionBlock:^{
            completionHandler(weakOperation.dataPage, nil);
        }];
        
        [operationQueue addOperation:loadingOperation];
    }];
    if (self) {
        _operationQueue = operationQueue;
    }
    
    return self;
}

- (void)dealloc {
    [_operationQueue cancelAllOperations];
}

@end
