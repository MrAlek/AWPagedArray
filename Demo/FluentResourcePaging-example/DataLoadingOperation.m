//
//  DataLoadingOperation.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2014-04-11.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import "DataLoadingOperation.h"

const NSTimeInterval DataLoadingOperationDuration = 0.3;

@implementation DataLoadingOperation

- (instancetype)initWithIndexes:(NSIndexSet *)indexes{

    self = [super init];
    
    if (self) {
        
        _indexes = indexes;
        
        typeof(self) weakSelf = self;
        [self addExecutionBlock:^{
            // Simulate fetching
            [NSThread sleepForTimeInterval:DataLoadingOperationDuration];
            
            // Generate data
            NSMutableArray *dataPage = [NSMutableArray array];
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [dataPage addObject:@(idx+1)];
            }];
            
            weakSelf->_dataPage = dataPage;
        }];
    }
    
    return self;
}

@end
