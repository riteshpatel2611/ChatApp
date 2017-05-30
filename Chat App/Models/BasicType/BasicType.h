//
//  BasicType.h
//  XMPPChat
//
//  Created by Xplor on 10/17/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kBaseTypeBuddy = 1,
    kBaseTypeGroup,
} KBaseType;

@interface BasicType : NSObject

@property KBaseType type;
@property (nonatomic, strong) NSString *profileImageURL;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *accountName;
@property (nonatomic, strong) NSString *recentMessage;
@property (nonatomic, strong) NSDate * recentMessageTimestamp;
@property (nonatomic, strong) NSDate * lastSeenTimeStamp;
@property BOOL recentMessageOutgoing;
@property BOOL deleted;
@property NSInteger unreadMessageCount;
@property NSInteger user_type;
@property (nonatomic, strong) NSString * centerId;
- (NSString *)name;
- (NSString *)accountNameChat;
@end

#import "XMPPJID.h"
typedef enum : NSUInteger {
    
    kBuddyStatusOffline = 0,
    kBuddyStatusAway = 1,
    kBuddyStatusAvailable = 2
} BuddyStatus;

@interface Buddy : BasicType

@property (nonatomic) BuddyStatus status;

@property (nonatomic, strong) NSString *subscriptionType;
@property (nonatomic, strong) XMPPJID *user;

- (BuddyStatus)getStatus;

@end

@interface Group : BasicType

@property (nonatomic, strong) XMPPJID *roomJID;
@property (nonatomic, strong) NSMutableArray *groupUsers;
@property BOOL isJoined;

@end
