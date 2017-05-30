//
//  AppDelegate.h
//  Chat App
//
//  Created by Fxbytes on 5/17/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AppDelegate *)sharedDelegate;

@end

