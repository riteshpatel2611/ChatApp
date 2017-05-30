//
//  ChatProtocol.h
//  XMPPChat
//
//  Created by Xplor on 10/14/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import <Foundation/Foundation.h>
//com.Xplor.xmppchat
//com.xplor.dev

@protocol ChatProtocol <NSObject>

@optional

//Login Success/Failure
- (void)loginResult:(BOOL)success;

- (void)registerResult:(BOOL)success withError:(NSString *)error;

- (void)passwordChangeResult:(BOOL)success withError:(NSString* )error;
- (void)updatedAvatarResult:(UIImage*)image withError:(NSString* )error;

// Presence Delegates
- (void)newBuddyOnline:(NSString *)buddyName;
- (void)buddyWentOffline:(NSString *)buddyName;
- (void)allBuddyWentOffline;
// Buddies
- (void)updateFriendList:(NSArray *)buddies;
- (void)newBuddyAdded:(NSString *)buddyName;
- (void)removedBuddy:(NSString *)buddyName;

//Group
- (void)updateGroupList:(NSArray *)groups update:(BOOL)isUpdate;
- (void)groupCreated:(BOOL)success withRoomJID:(NSString *)roomJid;
- (void)buddyAddedToGroup:(BOOL)success users:(NSArray *)users;
- (void)buddyRemovedFromGroup:(BOOL)success users:(NSArray *)users;

// Message Delegates
- (void)newMessageReceived:(NSDictionary *)messageContent withBuddyType:(BOOL)isGroup;

- (void)updateBuddyInChatController:(id)obj;

//conversation history delegate
- (void)historyLoaded:(BOOL)success;
- (void)lastConversationLoaded:(BOOL)success;
@end