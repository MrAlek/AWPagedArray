//
// AWMutablePagedArray.m
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

#import "AWMutablePagedArray.h"

NSString *const AWMutablePagedArrayObjectsPerPageMismatchException = @"AWMutablePagedArrayObjectsPerPageMismatchException";

@implementation AWMutablePagedArray {
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
        [NSException raise:AWMutablePagedArrayObjectsPerPageMismatchException format:@"Expected object count per page: %ld received: %ld", _objectsPerPage, objects.count];
    }
}
- (NSUInteger)pageForIndex:(NSUInteger)index {
    return index/_objectsPerPage + 1;
}
- (NSDictionary *)pages {
    return _pages;
}

#pragma mark - NSArray overrides
- (NSUInteger)count {
    return _totalCount;
}
- (id)objectAtIndex:(NSUInteger)index {
    
    NSUInteger page = [self pageForIndex:index];
    NSUInteger indexInPage = index%_objectsPerPage;
    
    NSArray *objectsForPage = _pages[@(page)];
    
    id returnValue;
    
    if (objectsForPage) {
        returnValue = objectsForPage[indexInPage];
    } else if (index < _totalCount) {
        returnValue = [NSNull null];
    } else {
            
        [NSException raise:NSRangeException format:@"index %ld beyond bounds [0 .. %ld]", index, _totalCount];
        returnValue = nil;
    }
    
    [self.delegate pagedArray:self
              willAccessIndex:index
                        value:returnValue];
    
    return returnValue;
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
    return;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [[self _proxiedArray] methodSignatureForSelector:sel];
}
+ (BOOL)respondsToSelector:(SEL)aSelector {
    
    id proxy = [[[self class] alloc] init];
    return [proxy respondsToSelector:aSelector];
}

#pragma mark - Private methods
- (NSUInteger)numberOfPages {
    return ceil(_totalCount/_objectsPerPage);
}
- (NSArray *)_proxiedArray {
    
    if (!_proxiedArray || _needsUpdateProxiedArray) {
        
        _proxiedArray = [self _concatinatedPages];
        _needsUpdateProxiedArray = NO;
    }
    
    return _proxiedArray;
}
- (NSArray *)_concatinatedPages {
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:_totalCount];
    
    [_pages enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *page, BOOL *stop) {
        [objects addObjectsFromArray:page];
    }];
    
    return objects;
}


@end
