//
//  DataProvider.h
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

@import Foundation;

#import "AWPagedArrayController.h"

@interface DataProvider : AWPagedArrayController

- (instancetype)initWithPageSize:(NSUInteger)pageSize;

@end
