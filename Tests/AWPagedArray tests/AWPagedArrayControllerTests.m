//
//  AWPagedArrayControllerTests.m
//  AWPagedArrayTests
//
//  Created by Zachary Radke on 5/15/14.
//
//

#import <XCTest/XCTest.h>
#import "AWPagedArray.h"
#import "AWPagedArrayController.h"

@interface AWPagedArrayControllerTests : XCTestCase {
    NSObject *_placeholder;
    AWPagedArray *_sourceArray;
    NSArray *(^_dataSource)(NSUInteger);
    AWPagedArrayController *_controller;
}
@end

@implementation AWPagedArrayControllerTests

static NSUInteger AWArrayCount = 22;
static NSUInteger AWObjectsPerPage = 5;

- (void)setUp {
    [super setUp];
    
    _placeholder = [NSObject new];
    _sourceArray = [[AWPagedArray alloc] initWithCount:AWArrayCount objectsPerPage:AWObjectsPerPage placeholderObject:_placeholder];
    _dataSource = ^NSArray *(NSUInteger page) {
        NSMutableArray *objects = [NSMutableArray array];
        NSUInteger end = MIN(page * 5, AWArrayCount) + 1;
        for (NSUInteger i = (page - 1) * 5 + 1; i < end; i++) {
            [objects addObject:@(i)];
        }
        return objects;
    };
    
    _controller = [[AWPagedArrayController alloc] initWithPagedArray:_sourceArray pageLoadingBlock:^(NSUInteger page, AWPageLoadingCompletionHandler completionHandler) {
        completionHandler(_dataSource(page), nil);
    }];
}
- (void)tearDown {
    _controller = nil;
    
    _dataSource = nil;
    _sourceArray = nil;
    _placeholder = nil;
    
    [super tearDown];
}
- (void)testLoadObjectAtIndex {
    [_controller loadObjectAtIndex:0];
    XCTAssertTrue(_controller.loadedObjectCount == AWObjectsPerPage, @"The objects should be loaded.");
    
    NSArray *actual = _controller.pagedArray.pages[@1];
    NSArray *expected = _dataSource(1);
    XCTAssertEqualObjects(actual, expected, @"The objects should actually be loaded into the paged array.");
}
- (void)testAutoloadObjectAtIndex {
    _controller.shouldLoadPagesAutomatically = YES;
    XCTAssertTrue(_controller.loadedObjectCount == 0, @"No objects should be loaded");
    id object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, _placeholder, @"The placeholder should be returned.");
    XCTAssertTrue(_controller.loadedObjectCount == AWObjectsPerPage, @"The objects should be loaded.");
    object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, @1, @"The actual content should be returned.");
}
- (void)testPreloadObjectAtIndex {
    _controller.shouldLoadPagesAutomatically = YES;
    _controller.automaticPreloadIndexMargin = 2;
    XCTAssertTrue(_controller.loadedObjectCount == 0, @"No objects should be loaded.");
    id object = _controller.allObjects[3];
    XCTAssertTrue(_controller.loadedObjectCount == AWObjectsPerPage, @"The first page should be loaded.");
    object = _controller.allObjects[3];
    XCTAssertEqualObjects(object, @4, @"The object should be returned!");
    XCTAssertTrue(_controller.loadedObjectCount == (AWObjectsPerPage * 2), @"The second page should also be loaded.");
    object = _controller.allObjects[5];
    XCTAssertEqualObjects(object, @6, @"The object from the second page should be returned.");
}
- (void)testIsLoadingObject {
    _controller = [[AWPagedArrayController alloc] initWithPagedArray:_sourceArray pageLoadingBlock:^(NSUInteger page, AWPageLoadingCompletionHandler completionHandler) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completionHandler(_dataSource(page), nil);
        });
    }];
    
    XCTAssertFalse([_controller isLoadingObjectAtIndex:0], @"The controller should not be loading the page.");
    [_controller loadObjectAtIndex:0];
    XCTAssertTrue([_controller isLoadingObjectAtIndex:0], @"The controller should be loading the page.");
}

@end

@interface AWPagedArrayControllerTestsDelegate : NSObject <AWPagedArrayControllerDelegate>
@property (strong, nonatomic, readonly) NSIndexSet *willChangeIndexSet;
@property (strong, nonatomic, readonly) NSDate *willChangeDate;
@property (strong, nonatomic, readonly) NSIndexSet *didChangeIndexSet;
@property (strong, nonatomic, readonly) NSDate *didChangeDate;
@property (strong, nonatomic, readonly) NSError *error;
@end

@implementation AWPagedArrayControllerTestsDelegate
- (void)controller:(AWPagedArrayController *)controller willLoadObjectsAtIndexes:(NSIndexSet *)indexes {
    _willChangeDate = [NSDate date];
    _willChangeIndexSet = indexes;
}
- (void)controller:(AWPagedArrayController *)controller didLoadObjectsAtIndexes:(NSIndexSet *)indexes error:(NSError *)error {
    _didChangeDate = [NSDate date];
    _didChangeIndexSet = indexes;
    _error = error;
}
@end

@implementation AWPagedArrayControllerTests (DelegateTests)

- (void)testDelegateSuccess {
    __block BOOL didLoadPage = NO;
    _controller = [[AWPagedArrayController alloc] initWithPagedArray:_sourceArray pageLoadingBlock:^(NSUInteger page, AWPageLoadingCompletionHandler completionHandler) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            didLoadPage = YES;
            completionHandler(_dataSource(page), nil);
        });
    }];
    
    AWPagedArrayControllerTestsDelegate *delegate = [AWPagedArrayControllerTestsDelegate new];
    _controller.delegate = delegate;
    
    [_controller loadObjectAtIndex:0];
    
    id object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, _placeholder, @"The array should still have a placeholder.");
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while (!didLoadPage && [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    NSIndexSet *expectedIndexSet = [_sourceArray indexSetForPage:1];
    
    XCTAssertTrue(didLoadPage, @"The page should be loaded.");
    XCTAssertTrue([delegate.didChangeDate compare:delegate.willChangeDate] == NSOrderedDescending, @"The delegate should be notified of the loading before it actually finishes.");
    XCTAssertEqualObjects(delegate.willChangeIndexSet, expectedIndexSet, @"The delegate should be notified the loading will start.");
    XCTAssertEqualObjects(delegate.didChangeIndexSet, expectedIndexSet, @"The delegate should be notified the loading finished.");
    XCTAssertNil(delegate.error, @"There should be no error reported.");
    object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, @1, @"The object should now be populated.");
}
- (void)testDelegateFailure {
    NSError *error = [NSError errorWithDomain:@"test.domain" code:9999 userInfo:nil];
    __block BOOL didLoadPage = NO;
    _controller = [[AWPagedArrayController alloc] initWithPagedArray:_sourceArray pageLoadingBlock:^(NSUInteger page, AWPageLoadingCompletionHandler completionHandler) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            didLoadPage = YES;
            completionHandler(nil, error);
        });
    }];
    
    AWPagedArrayControllerTestsDelegate *delegate = [AWPagedArrayControllerTestsDelegate new];
    _controller.delegate = delegate;
    
    [_controller loadObjectAtIndex:0];
    
    id object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, _placeholder, @"The array should still have a placeholder.");
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while (!didLoadPage && [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    NSIndexSet *expectedIndexSet = [_sourceArray indexSetForPage:1];
    
    XCTAssertTrue(didLoadPage, @"The page should be loaded.");
    XCTAssertTrue([delegate.didChangeDate compare:delegate.willChangeDate] == NSOrderedDescending, @"The delegate should be notified of the loading before it actually finishes.");
    XCTAssertEqualObjects(delegate.willChangeIndexSet, expectedIndexSet, @"The delegate should be notified the loading will start.");
    XCTAssertEqualObjects(delegate.didChangeIndexSet, expectedIndexSet, @"The delegate should be notified the loading finished.");
    XCTAssertEqualObjects(delegate.error, error, @"The error should be passed to the delegate.");
    object = _controller.allObjects[0];
    XCTAssertEqualObjects(object, _placeholder, @"The object should remain the placeholder.");
}

@end

