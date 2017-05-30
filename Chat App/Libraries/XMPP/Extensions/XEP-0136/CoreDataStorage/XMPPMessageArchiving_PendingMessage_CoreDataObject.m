//
//  XMPPMessageArchiving_PendingMessage_CoreDataObject.m
//  XMPPChat


#import "XMPPMessageArchiving_PendingMessage_CoreDataObject.h"
#import "XMPPMessageArchivingCoreDataStorage.h"

@implementation XMPPMessageArchiving_PendingMessage_CoreDataObject

+ (XMPPMessageArchiving_PendingMessage_CoreDataObject  *)createPendingMessage  {

    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject" inManagedObjectContext:moc];
    
    // Initialize Record
    XMPPMessageArchiving_PendingMessage_CoreDataObject *pendingMsgRecord = [[XMPPMessageArchiving_PendingMessage_CoreDataObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    return pendingMsgRecord;
}

- (void)savePendingMessage {

    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSError *error = nil;
    if ([moc save:&error]) {

    } else {
	  if (error) {
		NSLog(@"%@",error.description);
	  }
    }
}


- (void)deletePendingMessage {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    [moc deleteObject:self];
    NSError *error = nil;
    if ([moc save:&error]) {
        
    } else {
        if (error) {
            NSLog(@"deletePendingMessage %@",error.description);
        }
    }
}


+ (NSArray *)getAllPendingMessage {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject"
									   inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    for (NSManagedObject *obj in messages) {
	  NSLog(@"%@",obj);
    }
    return messages;
}

+ (NSArray *)getAllPendingMessageOfSender:(NSString *)senderName Reciver:(NSString *)reciverName {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject"
									   inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSString *predicateFrmt = @"reciverName == %@ AND senderName == %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFrmt, reciverName, senderName];
    request.predicate = predicate;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    for (NSManagedObject *obj in messages) {
	  NSLog(@"%@",obj);
    }
    return messages;
}

+ (XMPPMessageArchivingCoreDataStorage *)getPendingMessageForMsgId:(NSString *)msgId {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject"
									   inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSString *predicateFrmt = @"msgId == %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFrmt, msgId];
    request.predicate = predicate;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    for (NSManagedObject *obj in messages) {
	  NSLog(@"%@",obj);
    }
    
    if (messages.count == 0) {
	  return nil;
    }
    
    return [messages firstObject];
}

@end
