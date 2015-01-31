//
// AWPagedArrayTests.m
//
// Copyright (c) 2014 Alek Åström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <XCTest/XCTest.h>
#import "AWPagedArray.h"

@interface AWPagedArrayTests : XCTestCase
@end

const NSUInteger MutablePagedArraySize = 50;
const NSUInteger MutablePagedArrayObjectsPerPage = 6;
const NSUInteger MutablePagedArrayInitialPageIndex = 1;

@implementation AWPagedArrayTests {
    AWPagedArray *_pagedArray;
    NSMutableArray *_firstPage;
    NSMutableArray *_secondPage;
}

- (void)setUp {
    [super setUp];

    _pagedArray = [[AWPagedArray alloc] initWithCount:MutablePagedArraySize objectsPerPage:MutablePagedArrayObjectsPerPage initialPageIndex:MutablePagedArrayInitialPageIndex];
    
    _firstPage = [NSMutableArray array];
    for (NSInteger i = 1; i <= MutablePagedArrayObjectsPerPage; i++) {
        [_firstPage addObject:@(i)];
    }
    [_pagedArray setObjects:_firstPage forPage:MutablePagedArrayInitialPageIndex];
    
    _secondPage = [NSMutableArray array];
    for (NSInteger i = MutablePagedArrayObjectsPerPage+1; i <= MutablePagedArrayObjectsPerPage*2; i++) {
        [_secondPage addObject:@(i)];
    }
    [_pagedArray setObjects:_secondPage forPage:MutablePagedArrayInitialPageIndex+1];
    
}
- (NSArray *)array {
    return (NSArray *)_pagedArray;
}

#pragma mark - Tests
- (void)testSizeIsCorrect {
    XCTAssertEqual([self array].count, MutablePagedArraySize, @"Paged array has wrong size");
}
- (void)testSizeIsCorrectWithEvenPagePartitioning {
    
    AWPagedArray *pagedArray = [[AWPagedArray alloc] initWithCount:10 objectsPerPage:1 initialPageIndex:5];
    XCTAssertEqual([(NSArray *)pagedArray count], 10, @"Paged array has wrong size");
}
- (void)testObjectsPerPageIsCorrect {
    XCTAssertEqual(_pagedArray.objectsPerPage, MutablePagedArrayObjectsPerPage, @"Paged array has wrong objects per page count");
}
- (void)testReturnsRightObject {
    XCTAssertEqualObjects([self array][0], _firstPage[0], @"Returns wrong object!");
}
- (void)testThrowsExceptionWhenSettingPageWithWrongSize {
    
    XCTAssertThrowsSpecificNamed([_pagedArray setObjects:@[@1] forPage:1], NSException, NSInternalInconsistencyException, @"Paged array throws wrong exception");
}
- (void)testDoesNotThrowExceptionWhenSettingLastPageWithOddSize {
    
    NSInteger lastPage = MutablePagedArrayInitialPageIndex+[_pagedArray numberOfPages]-1;
    
    XCTAssertNoThrow([_pagedArray setObjects:@[@(1)] forPage:lastPage], @"Paged array throws exception on last page!");
}
- (void)testFastEnumeration {
    
    NSMutableArray *objects = [NSMutableArray array];
    for (id object in [self array]) {
        if (![object isKindOfClass:[NSNull class]]) {
            [objects addObject:object];
        }
    }
    
    NSArray *testObjects = [_firstPage arrayByAddingObjectsFromArray:_secondPage];
    
    XCTAssertEqualObjects(objects, testObjects, @"Fast enumeration outputs wrong objects");
}
- (void)testFastEnumerationUpdatesAfterSettingNewPage {
    
    NSMutableArray *beforeObjects = [NSMutableArray array];
    for (id object in [self array]) {
        [beforeObjects addObject:object];
    }
    
    [_pagedArray setObjects:_firstPage forPage:MutablePagedArrayInitialPageIndex+2];
    
    NSMutableArray *afterObjects = [NSMutableArray array];
    for (id object in [self array]) {
        [afterObjects addObject:object];
    }
    
    XCTAssertNotEqualObjects(beforeObjects, afterObjects, @"Fast enumeration still returns same objects after setting new page");
}
- (void)testIndexOfObjectReturnsRightIndex {
    
    NSNumber *testNumber = _secondPage[0];
    
    XCTAssertEqual([[self array] indexOfObject:testNumber], MutablePagedArrayObjectsPerPage, @"Paged array returned wrong index for object");
}
- (void)testIndexOfObjectReturnsNSNotFoundWhenLookingForAnObjectNotInTheArray {
    
    XCTAssert(([[self array] indexOfObject:@(NSNotFound)] == NSNotFound), @"Index returned for an object not present in the array");
}
- (void)testObjectAtIndexForEmptyPageReturnsNSNull {
    
    id object = [[self array] objectAtIndex:MutablePagedArraySize-1];
    XCTAssertEqualObjects([object class], [NSNull class], @"Array doesn't return NSNull for value not yet loaded");
}
- (void)testNoThrowForLiteralSyntaxForEmptyIndex {
    
    XCTAssertNoThrow([self array][MutablePagedArraySize-1], @"Array shouldn't throw exception when using literal syntax for an empty index");
}
- (void)testObjectAtIndexForTooLargeIndexReturnsNSRangeException {
    
    XCTAssertThrowsSpecificNamed([[self array] objectAtIndex:MutablePagedArraySize], NSException, NSRangeException, @"Paged array doesn't throw NSRangeException when accessing index beyond its size");
}
- (void)testMutableCopyWorks {
    
    NSMutableArray *mutableCopy = [[self array] mutableCopy];
    [mutableCopy removeObjectsInArray:_secondPage];
    [mutableCopy removeObjectIdenticalTo:[NSNull null]];
    
    XCTAssertEqualObjects(mutableCopy, _firstPage, @"Mutable copy doesn't match original");
    
}
- (void)testPagedArrayActsAsNSArray {
    
    XCTAssert([[self array] isKindOfClass:[NSArray class]], @"Paged array isn't an NSArray");
}
- (void)testArrayProxyActuallyContainsNullValues {
    
    for (id object in [self array]) {
        if ([object isKindOfClass:[NSNull class]]) {
            return;
        }
    }
    
    XCTFail(@"Array proxy didn't contain null values for empty pages");
}
- (void)testArrayRealCountMatchesProxyCount {
    
    NSMutableArray *objects = [NSMutableArray array];
    for (id object in [self array]) {
        [objects addObject:object];
    }
    
    XCTAssertEqual(objects.count, [[self array] count], @"Real count doesn't match proxy count");
}
- (void)testNumberOfPages {
    XCTAssertEqual([_pagedArray numberOfPages], ceil((CGFloat)MutablePagedArraySize/MutablePagedArrayObjectsPerPage), @"Wrong number of pages");
}
@end

#pragma mark Delegate tests
@interface AWPagedArrayTestsTestingDelegate : NSObject <AWPagedArrayDelegate> {
    @public
    NSUInteger _accessIndex;
    id _returnedObject;
}
@end
@implementation AWPagedArrayTestsTestingDelegate
- (void)pagedArray:(AWPagedArray *)pagedArray willAccessIndex:(NSUInteger)index returnObject:(__autoreleasing id *)returnObject {
    _accessIndex = index;
    _returnedObject = *returnObject;
}
@end

@interface AWPagedArrayTestsReturnObjectChangingDelegate : AWPagedArrayTestsTestingDelegate {
    @public
    id _objectToChangeReturnValueTo;
}
@end
@implementation AWPagedArrayTestsReturnObjectChangingDelegate
- (void)pagedArray:(AWPagedArray *)pagedArray willAccessIndex:(NSUInteger)index returnObject:(__autoreleasing id *)returnObject {
    *returnObject = @"test";
    [super pagedArray:pagedArray willAccessIndex:index returnObject:returnObject];
}
@end

@implementation AWPagedArrayTests (DelegateTests)
- (void)testReturnValuesAreCorrectForDelegateCall {
    
    AWPagedArrayTestsTestingDelegate *delegate = [AWPagedArrayTestsTestingDelegate new];
    _pagedArray.delegate = delegate;
    
    NSUInteger index = 5;
    id object = [self array][index];
    
    XCTAssertEqual(delegate->_accessIndex, index, @"Delegate's returned index doesn't match index accessed from array");
    XCTAssertEqualObjects(delegate->_returnedObject, object, @"Delegate's returnObject doesn't match returned object from array");
}
- (void)testDelegateCanChangeReturnedObject {
    
    AWPagedArrayTestsReturnObjectChangingDelegate *delegate = [AWPagedArrayTestsReturnObjectChangingDelegate new];
    _pagedArray.delegate = delegate;
    id objectToChangeTo = @"test";
    
    delegate->_objectToChangeReturnValueTo = objectToChangeTo;
    
    id returnedObject = [self array][0];
    
    XCTAssertEqual(returnedObject, objectToChangeTo, @"Delegate couldn't replace object returned by array");
    
}
@end


