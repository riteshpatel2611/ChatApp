//
//  CustomColor.m
//  Kidi
//
//  Created by Developer on 10/03/14.
//  Copyright (c) 2014 Xplor. All rights reserved.
//

#import "CustomColor.h"

@implementation UIColor(NewColor)

+ (UIColor *)MyColor:(float)Red green:(float)Green blue:(float)Blue
{
    return [UIColor colorWithRed:(Red / 255.0) green:(Green / 255.0) blue:(Blue / 255.0) alpha:1.0];
}

+ (UIColor *)MyColor:(float)Red green:(float)Green blue:(float)Blue opacity:(float)opacity
{
    return [UIColor colorWithRed:(Red / 255.0) green:(Green / 255.0) blue:(Blue / 255.0) alpha:opacity];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
//    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
