//
//  DataLoadingOperation.h
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2014-04-11.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataLoadingOperation : NSBlockOperation

- (instancetype)initWithIndexes:(NSIndexSet *)indexes;

@property (nonatomic, readonly) NSIndexSet *indexes;
@property (nonatomic, readonly) NSArray *dataPage;

@end
