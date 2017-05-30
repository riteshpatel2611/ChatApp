//
//  DataBase.h
//  Snag
//
//  Created by   on 2/12/14.
//  Copyright (c) 2014  Technology Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Database : NSObject

#pragma mark - Function

+(Database *)connection;

#pragma mark - Database migration function
// Implemented for migration of data for new release
- (void)migrateSqliteStatments;

#pragma mark -- Insert/ Select/ Update Contacts table
- (NSMutableArray *)getAllContactsForUser:(NSString *)userJId ;
- (NSMutableDictionary *)getContact:(NSString *)contactJId forUser:(NSString *)userJId ;
- (void)insertContacts:(NSArray *)contacts;
- (void)updateContact:(NSDictionary *)dict ;
- (NSDictionary *)getLastMessageIdOfUser:(NSString *)contactJid ;
- (void)updateLastMessageId:(NSString *)messageId forContact:(NSString *)contactJid ;

#pragma mark -- Insert/ Select/ Update UserGroups table
- (NSMutableArray *)getAllGroupsOfUser:(NSString *)userJId ;
- (NSMutableDictionary *)getGroup:(NSString *)groupJId forUser:(NSString *)userJId ;
- (void)insertUserGroups:(NSArray *)groups;
- (void)updateGroup:(NSDictionary *)dict ;
- (void)updateLastMessageId:(NSString *)messageId forGroup:(NSString *)groupJid ;
- (NSDictionary *)getLastMessageIdOfGroup:(NSString *)groupJid ;

#pragma mark -- Insert/ Select/ Update UserGroups Members table
- (NSMutableArray *)getGroupMembers:(NSString *)groupJId forUser:(NSString *)userJId ;
- (NSMutableDictionary *)getGroupMember:(NSString *)groupJId forUser:(NSString *)userJId member:(NSString *)memberJId ;
- (void)insertUserGroupMembers:(NSArray *)members group:(NSString *)groupJId user:(NSString *)userJId ;
- (void)updateGroupMember:(NSDictionary *)dict ;

#pragma mark -- Insert/ Select/ Update Messages table
- (void)insertMessage:(NSDictionary *)dict ;
- (void)updateMessageDeliveryStatusForUser:(int)status idVal:(NSString *)idVal forUser:(NSString *)receiverJId sender:(NSString *)senderJId ;
- (void)updateMessageDeliveryStatusForGroup:(int)status idVal:(NSString *)idVal forUser:(NSString *)receiverJId sender:(NSString *)groupJId ;
- (NSMutableDictionary *)getMessageWithMessageId:(NSString *)messageId forGroup:(NSString *)groupJId member:(NSString *)memberJId toUser:(NSString *)userJId ;
- (NSMutableDictionary *)getMessageWithMessageId:(NSString *)messageId forBuddy:(NSString *)buddyJID toUser:(NSString *)userJId ;
- (NSMutableArray *)getMessagesOfUser:(NSString *)buddyJId loggedinUser:(NSString *)userJId min:(NSInteger)min max:(NSInteger)max ;
- (NSMutableArray *)getMessagesOfGroup:(NSString *)groupJId loggedinUser:(NSString *)userJId ;
- (NSInteger)getUserMessagesCount:(double)lastSeen :(NSString *)groupJId loggedinUser:(NSString *)userJId ;
- (NSInteger)getGroupMessagesCount:(double)lastSeen :(NSString *)groupJId loggedinUser:(NSString *)userJId ;
- (NSMutableArray *)getPendingMessagesOfUser:(NSString *)userJId ;


#pragma mark -- Insert/ Select/ Update Recent Messages table
- (NSMutableDictionary *)getRecentMessageOf:(NSString *)receiverJId andUser:(NSString *)senderJId ;
- (void)insertRecentMessage:(NSMutableDictionary *)messageDetail ;
- (void)updateRecentMessage:(NSDictionary *)messageDetail ;

#pragma mark - Insert/ Select/ Delete Pending Messages
- (void)insertPendingMessage:(NSDictionary *)dict ;
- (void)deletePendingMessage:(NSString *)msgId ;
- (NSMutableArray *)getPendingMessagesOfSender:(NSString *)senderJid andReciver:(NSString *)reciverJid ;
- (NSMutableArray *)getPendingMessagesWithID:(NSString *)MsgID ;

#pragma mark -- Insert/ Select/ Update Media table
- (NSInteger)insertMediaAndGetMediaID:(NSDictionary *)dict ;
- (void)updateMedia:(NSDictionary *)dict ;

- (int)getAllUserMessagesCountloggedinUser:(NSString *)userJId ;

@end
