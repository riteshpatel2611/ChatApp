//
//  CustomColor.h
//  Kidi
//
//  Created by Developer on 10/03/14.
//  Copyright (c) 2014 Xplor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(NewColor)

+ (UIColor *)MyColor:(float)Red green:(float)Green blue:(float)Blue;
+ (UIColor *)MyColor:(float)Red green:(float)Green blue:(float)Blue opacity:(float)opacity;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
