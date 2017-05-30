//
//  Utility.m
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (void)setNavigationBarTheme{
    
    [[UINavigationBar appearance] setBarTintColor:COLOR_NAVIGATION_BAR_TINT];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:COLOR_NAVIGATION_TITLE, NSForegroundColorAttributeName,  [UIFont fontWithName:FONT_ROBOTO_BOLD size:18.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:COLOR_NAVIGATION_TINT];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage new]
//                                       forBarMetrics:UIBarMetricsDefault];
//    [UINavigationBar appearance].shadowImage = [UIImage new];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
}

+ (void)setNavigationBarThemeForContactsUI{
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName,  [UIFont fontWithName:FONT_ROBOTO_BOLD size:18.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    //    [[UINavigationBar appearance] setBackgroundImage:[UIImage new]
    //                                       forBarMetrics:UIBarMetricsDefault];
    //    [UINavigationBar appearance].shadowImage = [UIImage new];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
}

+ (id)getValueFromDictionary:(NSDictionary *)dictionary Key:(NSString *)key
{
    if (isObjectEmpty(dictionary))
    {
        if (isObjectEmpty([dictionary valueForKey:key]))
        {
            return [dictionary valueForKey:key];
        }
    }
    return @"";
}
@end
