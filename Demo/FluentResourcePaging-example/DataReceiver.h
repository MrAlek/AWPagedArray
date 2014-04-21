//
//  DataReceiver.h
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2014-04-04.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DataProvider;
@protocol DataReceiver <NSObject>

@property (nonatomic) DataProvider *dataProvider;

@end
