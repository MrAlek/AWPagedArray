//
//  DataController.h
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

@import Foundation;

@class DataController;
@protocol DataControllerDelegate<NSObject>

- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes;
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes;

@end

@interface DataController : NSObject

- (instancetype)initWithPageSize:(NSUInteger)pageSize;

@property (nonatomic, readonly) NSUInteger dataCount;
@property (nonatomic, readonly) NSUInteger pageSize;
@property (nonatomic, readonly) NSUInteger loadedCount;
@property (nonatomic) BOOL shouldLoadAutomatically;
@property (nonatomic, weak) id<DataControllerDelegate> delegate;

- (NSNumber *)dataAtIndex:(NSUInteger)index;
- (BOOL)isLoadingDataAtIndex:(NSUInteger)index;
- (void)loadDataAtIndex:(NSUInteger)index;

@end
