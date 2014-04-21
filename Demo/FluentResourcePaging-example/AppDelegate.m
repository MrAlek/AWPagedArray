//
//  AppDelegate.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2013-12-28.
//  Copyright (c) 2013 Alek Åström. All rights reserved.
//

#import "AppDelegate.h"
#import "DataReceiver.h"
#import "DataProvider.h"

@interface AppDelegate() <UITabBarControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self.window makeKeyAndVisible];
    
    [[self _tabBarController] setDelegate:self];
    [self _setDataProviderForViewController:[self _tabBarController].selectedViewController];
    
    return YES;
}

- (void)_setDataProviderForViewController:(UIViewController *)viewController {
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        id <DataReceiver> dataViewController = (id<DataReceiver>)[((UINavigationController *)viewController) topViewController];
        if ([dataViewController conformsToProtocol:@protocol(DataReceiver) ]) {
            [dataViewController setDataProvider:[DataProvider new]];
        }
    }
}

- (UITabBarController *)_tabBarController {
    return (UITabBarController *)self.window.rootViewController;
}

#pragma mark - Tab bar controller delegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self _setDataProviderForViewController:viewController];
}

@end
