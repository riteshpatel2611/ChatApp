//
//  BuddyListManager.h
//  XMPPChat


#import <Foundation/Foundation.h>

@interface BuddyListManager : NSObject

+(instancetype)sharedBuddyListManager;
@property (nonatomic, strong)NSArray *onlineBuddies;

@end
