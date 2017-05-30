//
//  Utility.h
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Utility : NSObject

+ (void)setNavigationBarTheme;
+ (void)setNavigationBarThemeForContactsUI;

+ (id)getValueFromDictionary:(NSDictionary *)dictionary Key:(NSString *)key;
@end
