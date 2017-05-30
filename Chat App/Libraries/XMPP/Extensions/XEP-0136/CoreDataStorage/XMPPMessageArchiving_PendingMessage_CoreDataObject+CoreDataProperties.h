//
//  XMPPMessageArchiving_PendingMessage_CoreDataObject+CoreDataProperties.h
//  XMPPChat


#import "XMPPMessageArchiving_PendingMessage_CoreDataObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface XMPPMessageArchiving_PendingMessage_CoreDataObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *msgId;
@property (nullable, nonatomic, retain) NSString *senderName;
@property (nullable, nonatomic, retain) NSString *reciverName;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) NSString *msg;
@property (nullable, nonatomic, retain) NSString *imagePath;

@end

NS_ASSUME_NONNULL_END
