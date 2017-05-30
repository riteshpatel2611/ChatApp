//
//  NSDate+Helper.h
//  XMPPChat


#import <Foundation/Foundation.h>

@interface NSDate (Helper)

- (NSString *)composeMessageDate;
+ (NSDate *)composeDateFromSring:(NSString *)strDate;
- (NSString *)composeMessageDateForBuddyList;
@end
