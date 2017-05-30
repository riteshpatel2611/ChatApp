//
//  NSString+NSString_Helper.h
//  XMPPChat


#import <Foundation/Foundation.h>

@interface NSString (Helper)

- (NSString *)addHostName;
- (NSString *)addGroupHostName;
- (NSString *)removeHostName;

- (UIImage *)decodeBase64ToImage;
+ (NSString *)encodeBase64FromImage:(UIImage *)image;

- (NSString *)removeLastPathComponent;
- (NSString *)removeFirstPathComponent;
- (NSString*)MD5;
@end
