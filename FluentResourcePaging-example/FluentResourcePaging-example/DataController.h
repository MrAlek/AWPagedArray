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

@optional
- (void)dataController:(DataController *)dataController willLoadDataAtIndexes:(NSIndexSet *)indexes;
- (void)dataController:(DataController *)dataController didLoadDataAtIndexes:(NSIndexSet *)indexes;

@end

@interface DataController : NSObject

- (instancetype)initWithPageSize:(NSUInteger)pageSize;

@property (nonatomic, weak) id<DataControllerDelegate> delegate;

/**
 * The array returned will be a proxy object containing
 * NSNull values for data objects not yet loaded. As data
 * loads, the proxy updates automatically to include
 * the newly loaded objects.
 *
 * @see shouldLoadAutomatically
 */
@property (nonatomic, readonly) NSArray *dataObjects;

@property (nonatomic, readonly) NSUInteger pageSize;
@property (nonatomic, readonly) NSUInteger loadedCount;

/**
 * When this property is set, new data is automatically loaded when
 * the dataObjects array returns an NSNull reference.
 *
 * @see dataObjects
 */
@property (nonatomic) BOOL shouldLoadAutomatically;
@property (nonatomic) NSUInteger automaticPreloadMargin;

- (BOOL)isLoadingDataAtIndex:(NSUInteger)index;
- (void)loadDataForIndex:(NSUInteger)index;

@end
