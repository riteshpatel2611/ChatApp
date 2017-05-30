//
//  ChatProtocol.h
//  XMPPChat
//
//  Created by Xplor on 10/14/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatProtocol.h"


static const NSString *postNotificationMessageReceive = @"postNotificationMessageReceive";
static const NSString *postNotificationPresenceReceive = @"postNotificationPresenceReceive";

@interface ChatProtocolManager : NSObject

@property (nonatomic, strong) NSMutableArray *buddyList;
@property (nonatomic, assign) BOOL isConnected;
+(instancetype)sharedChatManager;

- (void)goOnline;
- (void)goOffline;
- (void)printPresence;

- (BOOL)connect;
- (void)disconnect;

- (BOOL)loginUser:(NSDictionary *)params;
- (void)registerUser:(NSDictionary *)params;
- (void)changePassword:(NSDictionary *)params;

//- (void)updateAvatar:(UIImage *)avatar forUser:(NSString*)userId;
//- (UIImage*)getAvatarForUser:(NSString *)userId;

- (NSArray *)fetchBuddyListFromDatabase;
- (void)addBuddy:(NSString *)buddyName;
- (void)removeBuddy:(Buddy *)buddy;
- (void)updateBuddyLastSeen:(BasicType *)obj;

//- (void)loadGroupListFromDatabase;
- (void)addGroup:(NSString *)groupName withBuddies:(NSArray *)buddies;
- (void)inviteUsers:(NSArray *)users forGroup:(NSString *)group;
- (void)joinChatRoomName:(NSString *)groupName users:(NSArray *)groupUsers;
- (void)leaveChatRoom:(NSString *)groupName user:(NSString *)userName;

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

- (void)sendMessage:(NSString *)messageStr ToUser:(NSString *)toUser;
- (void)sendMessage:(NSString *)messageStr toGroup:(BasicType *)group;

- (void)sendPendingMessage:(NSDictionary *)messageDic toGroup:(NSString *)groupJID;
- (void)sendPendingMessage:(NSDictionary *)messageDic ToUser:(NSString *)toUser;

- (void)sendMessagePN:(NSString *)messageStr toUser:(NSString *)toUser fromUser:(NSString *)fromUser;

- (void)sendImage:(UIImage *)image Url:(NSString *)strUrl ToUser:(NSString *)toUser;
- (void)sendImage:(UIImage *)image Url:(NSString *)strUrl ToGroup:(BasicType *)group;
- (void)sendImage:(UIImage *)image Url:(NSString *)strUrl MessageId:(NSString *)packetId ToGroup:(BasicType *)group;
- (void)updateBuddyListWithRecentMessage:(NSArray *)buddies;
- (NSString *)getTimeForLastRecivedMessageFromUser:(BasicType *)from;

- (NSArray *)loadChatHistoryWithUserName:(BasicType *)buddy min:(NSInteger)min max:(NSInteger)max;
- (NSArray *)loadChatHistoryWithGroup:(BasicType *)buddy;

- (void)loadBuddyListFromDatabase:(BOOL)needServerLoad;
- (void)loadGroupListFromDatabase:(BOOL)needServerLoad;

- (void)loadChatHistoryForUser:(BasicType *)buddy withMessageId:(NSString *)messageID orderBY:(NSString *)orderBy;
- (void)loadChatHistoryForGroup:(BasicType *)group withMessageId:(NSString *)messageID orderBY:(NSString *)orderBy;

- (void)fetchBuddyListFromServer;
- (void)fetchOldConversationFromServer;

// UI/UX
- (void)showLoader;
- (void)hideLoader;

- (NSString *)getResourceId;
- (NSString *)getMessageID;


- (int)getTotalAUnreadMessageCount:(NSArray *)buddies;
@end
