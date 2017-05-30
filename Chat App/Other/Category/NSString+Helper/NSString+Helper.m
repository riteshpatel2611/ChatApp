//
//  NSString+NSString_Helper.m
//  XMPPChat
//
//  Created by Xplor on 10/14/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import "NSString+Helper.h"

@implementation NSString (Helper)

- (NSString *)addHostName {
    
    NSString *buddyName = nil;
    if ([self rangeOfString:DEFAULT_HOST_NAME].length > 0) {
        buddyName = self;
    } else {
        buddyName = [self stringByAppendingFormat:@"@%@", DEFAULT_HOST_NAME];
    }
    return buddyName;
}

- (NSString *)addGroupHostName {
    
    NSString *buddyName = nil;
    buddyName = [self stringByAppendingFormat:@"@%@", DEFAULT_GROUP_HOST_NAME];
    return buddyName;
}

- (NSString *)removeHostName {
    
    NSString *buddyName = self;
    NSArray *objs = [self componentsSeparatedByString:@"@"];
    if (objs > 0) {
        buddyName = objs[0];
    }
    return buddyName;
}

- (UIImage *)decodeBase64ToImage {
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}


+ (NSString *)encodeBase64FromImage:(UIImage *)image {
    
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSString *)removeLastPathComponent {
    
    NSArray *strArr = [self componentsSeparatedByString:@"/"];
    return strArr[0];
}

- (NSString *)MD5{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5( cStr, strlen(cStr), result );
    
    
    return [NSString
            stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]];
}

- (NSString *)removeFirstPathComponent {
    
    NSArray *strArr = [self componentsSeparatedByString:@"/"];
    return strArr[1];
}
@end
