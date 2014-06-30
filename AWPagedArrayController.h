//
//  AWPagedArrayController.h
//  FluentResourcePaging-example
//
//  Created by Zachary Radke on 5/15/14.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Block passed by AWPagedArrayController instances when loading pages. This block **must** be invoked at some point or the controller will not resolve.
 *
 *  @param fetchedObjects The objects that were fetched, or nil if an error occured. If an array is given, it must contain the correct number of objects for the given page.
 *  @param error          An error if one occured. While optional, passing an error can help provide context when using the controller.
 */
typedef void(^AWPageLoadingCompletionHandler)(NSArray *fetchedObjects, NSError *error);

@class AWPagedArray;
@protocol AWPagedArrayControllerDelegate;

/**
 *  This class acts similar to an NSFetchedResultsController, with configurations to automatically load content into an AWPagedArray as it is accessed.
 *
 *  @discussion Instances are initialized with an AWPagedArray which is treated as the starting state for the controller. This array is copied and not directly exposed afterwards. The pagedArray property will always return a detached copy of the internal AWPagedArray to prevent monkey business.
 *
 *  Content loading is performed in the block given when initializing a controller. This block can be invoked multiple times and is not manually released, so developers should take care to avoid creating retain cycles. Content is loaded once successfully per page, and cached for further access. When the content is loaded depends on the configurations of the individual controller.
 *
 *  Consumers of the controller should use the allObjects property, which returns an array of loaded and placeholder objects. If any loading is performed, consumers should also set the delegate of the controller to be notified when content has been loaded.
 *
 *  The controller is thread safe. Delegate calls will always be invoked on the main thread, so it is safe to perform UI changes in them.
 */
@interface AWPagedArrayController : NSObject {
    @protected
    AWPagedArray *_pagedArray; // This iVar is exposed for subclasses to monkey with as needed.
}

/**
 *  The designated initializer for this class. Generates a new controller with the given AWPagedArray as a starting point. Content is loaded through the provided page loading block. These parameters represent immutable properties of the controller.
 *
 *  @param pagedArray       The paged array to use as a starting point for the controller. This must not be nil. The given paged array will be copied and modified as needed.
 *  @param pageLoadingBlock The content loading block. This must not be nil. The block is invoked whenever content needs to be loaded for a specific page. The page index and a completion handler are passed. The completion handler **must** be invoked at some point in the lifecycle of the controller to avoid undefined behavior. The completion handler can be invoked from any thread.
 *
 *  @return A new controller configured to load content into a private paged array.
 */
- (instancetype)initWithPagedArray:(AWPagedArray *)pagedArray
                  pageLoadingBlock:(void (^)(NSUInteger page, AWPageLoadingCompletionHandler completionHandler))pageLoadingBlock;

/**
 *  Returns a detatched copy of the private paged array backing the controller.
 */
@property (copy, nonatomic, readonly) AWPagedArray *pagedArray;

/**
 *  Returns an array of all objects, including placeholders
 */
@property (nonatomic, readonly) NSArray *allObjects;

/**
 *  Returns a count of all loaded objects, excluding placeholders.
 */
@property (nonatomic, readonly) NSUInteger loadedObjectCount;

/**
 *  The delegate which will receive messages when content is loading.
 */
@property (weak, nonatomic) id<AWPagedArrayControllerDelegate> delegate;

/**
 *  YES if accesssing placeholder indexes in the allObjects array should automatically trigger loading for that page, or NO if loading shoud only be performed manually with the loadDataForIndex: method.
 *  @see automaticPreloadingIndexMargin, loadContentForIndex:
 */
@property (atomic) BOOL shouldLoadPagesAutomatically;

/**
 *  Set this to a number greater than zero in addition to shouldLoadPagesAutomatically to to have the controller automatically load content ahead of the accessed index. The number represents how many indexes ahead the controller will check for a placeholder object. If this number is greater than the objects-per-page of the backing paged array, the lower number will be used.
 */
@property (atomic) NSUInteger automaticPreloadIndexMargin;

/**
 *  Checks if the controller is currently loading the page for the given index.
 *
 *  @param index The index to check for loading, taken from the allObjects array.
 *
 *  @return YES if the controller is actively loading content for the given index, or NO if it is not.
 */
- (BOOL)isLoadingObjectAtIndex:(NSUInteger)index;

/**
 *  Manually invokes the content loading block with the page for the given index. This method will do nothing if the content has already been loaded successfully or if the content is currently being loaded.
 *
 *  @param index The index to load, taken from the allObjects array.
 */
- (void)loadObjectAtIndex:(NSUInteger)index;

@end

/**
 *  Delegate protocol for the AWPagedArrayController.
 */
@protocol AWPagedArrayControllerDelegate <NSObject>

@optional

/**
 *  Notifies the delegate that content will be loaded for the given indexes.
 *
 *  @param controller The controller that will begin loading content.
 *  @param indexes    The indexes that will be loaded, taken from the controller's allObjects property.
 */
- (void)controller:(AWPagedArrayController *)controller willLoadObjectsAtIndexes:(NSIndexSet *)indexes;

/**
 *  Notifies the delegate that content finished loading for the given indexes.
 *
 *  @param controller The controller that finished loading content.
 *  @param indexes    The indexes that were loaded, taken from the controller's allObjects property.
 *  @param error      Any error which may have occured during the content loading, invalidating the update.
 */
- (void)controller:(AWPagedArrayController *)controller didLoadObjectsAtIndexes:(NSIndexSet *)indexes error:(NSError *)error;

@end
