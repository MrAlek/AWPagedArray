//
// AWPagedArray.m
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

#import "AWPagedArray.h"

NSString *const AWPagedArrayObjectsPerPageMismatchException = @"AWPagedArrayObjectsPerPageMismatchException";

@implementation AWPagedArray {
    NSUInteger _totalCount;
    NSUInteger _objectsPerPage;
    NSMutableDictionary *_pages;
    
    BOOL _needsUpdateProxiedArray;
    NSArray *_proxiedArray;
}

#pragma mark - Public methods
- (instancetype)initWithCount:(NSUInteger)count objectsPerPage:(NSUInteger)objectsPerPage {
    
    _totalCount = count;
    _objectsPerPage = objectsPerPage;
    _pages = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfPages]];
    
    return self;
}
- (void)setObjects:(NSArray *)objects forPage:(NSUInteger)page {
    
    if (objects.count == _objectsPerPage || page == self.numberOfPages) {
        
        _pages[@(page)] = objects;
        _needsUpdateProxiedArray = YES;
    } else {
        [NSException raise:AWPagedArrayObjectsPerPageMismatchException format:@"Expected object count per page: %ld received: %ld", (unsigned long)_objectsPerPage, (unsigned long)objects.count];
    }
}
- (NSUInteger)pageForIndex:(NSUInteger)index {
    return index/_objectsPerPage + 1;
}
- (NSIndexSet *)indexSetForPage:(NSUInteger)page {
    NSUInteger rangeLength = _objectsPerPage;
    if (page == [self numberOfPages]) {
        rangeLength = (_totalCount % _objectsPerPage) ?: _objectsPerPage;
    }
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange((page - 1) * _objectsPerPage, rangeLength)];
}
- (NSDictionary *)pages {
    return _pages;
}

#pragma mark - NSArray overrides
- (id)objectAtIndex:(NSUInteger)index {
    
    id object = [[self _proxiedArray] objectAtIndex:index];
    
    [self.delegate pagedArray:self
              willAccessIndex:index
                 returnObject:&object];
    
    return object;
}
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

#pragma mark - Proxying
+ (Class)class {
    return [NSArray class];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    [anInvocation setTarget:[self _proxiedArray]];
    [anInvocation invoke];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [[self _proxiedArray] methodSignatureForSelector:sel];
}
+ (BOOL)respondsToSelector:(SEL)aSelector {
    
    id proxy = [[[self class] alloc] init];
    return [proxy respondsToSelector:aSelector];
}
- (NSString *)description {
    return [[self _proxiedArray] description];
}

#pragma mark - Private methods
- (NSUInteger)numberOfPages {
    return ceil((CGFloat)_totalCount/_objectsPerPage);
}
- (NSArray *)_proxiedArray {
    
    if (!_proxiedArray || _needsUpdateProxiedArray) {
        
        [self _generateProxiedArray];
        _needsUpdateProxiedArray = NO;
    }
    
    return _proxiedArray;
}
- (void)_generateProxiedArray {
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:_totalCount];
    
    for (NSInteger pageIndex = 1; pageIndex <= [self numberOfPages]; pageIndex++) {
        
        NSArray *page = _pages[@(pageIndex)];
        if (!page) page = [self _placeholdersForPage:pageIndex];
        
        [objects addObjectsFromArray:page];
    }
    
    _proxiedArray = objects;
}
- (NSArray *)_placeholdersForPage:(NSUInteger)page {
    
    NSMutableArray *placeholders = [[NSMutableArray alloc] initWithCapacity:_objectsPerPage];
    
    NSUInteger pageLimit = [[self indexSetForPage:page] count];
    for (NSUInteger i = 0; i < pageLimit; ++i) {
        [placeholders addObject:[NSNull null]];
    }
    
    return placeholders;
}

@end
