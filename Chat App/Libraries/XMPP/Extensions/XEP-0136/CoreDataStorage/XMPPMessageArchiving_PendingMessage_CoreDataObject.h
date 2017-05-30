//
//  XMPPMessageArchiving_PendingMessage_CoreDataObject.h
//  XMPPChat

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface XMPPMessageArchiving_PendingMessage_CoreDataObject : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+ (XMPPMessageArchiving_PendingMessage_CoreDataObject *)createPendingMessage;
- (void)savePendingMessage;
- (void)deletePendingMessage;
+ (NSArray *)getAllPendingMessage;
+ (NSArray *)getAllPendingMessageOfSender:(NSString *)senderName Reciver:(NSString *)reciverName;
+ (XMPPMessageArchiving_PendingMessage_CoreDataObject *)getPendingMessageForMsgId:(NSString *)msgId;

@end

NS_ASSUME_NONNULL_END

#import "XMPPMessageArchiving_PendingMessage_CoreDataObject+CoreDataProperties.h"
