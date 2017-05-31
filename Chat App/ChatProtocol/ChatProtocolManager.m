//
//  ChatProtocol.m
//  XMPPChat
//
//  Created by Xplor on 10/14/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import <Contacts/Contacts.h>
#import "ChatProtocolManager.h"
#import "RequestQueue.h"
#import "FXPushNoteView.h"
#import "Database.h"
#import "XMPP.h"
#import "XMPPRoster.h"
#import "XMPPReconnect.h"
#import "XMPPRoomCoreDataStorage.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPMessageArchiving_PendingMessage_CoreDataObject.h"
#import "XMPPMessageCarbons.h"
#import "XMPPRegistration.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardTemp.h"
#import "XMPPRoomHybridStorage.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "XMLDictionary.h"

#define DEFAULT_PORT_NUMBER 5222
#define DEFAULT_HOST_NAME               @"152.194.204.120"
#define DEFAULT_GROUP_HOST_NAME         @"conference.152.194.204.120"
#define URL_BASE_CHAT                   @""
typedef enum : NSUInteger {
    
    kTagXmppRequestNone = 101,
    kTagXmppRequestLogin,
    kTagXmppRequestRegister,
} XmppRequestType;

@interface ChatProtocolManager ()

@property (nonatomic, strong) NSTimer* sendPresenceTimer;

@property (nonatomic, strong) XMPPMessageCarbons *xmppMessageCarbon;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchivingModule;
@property (nonatomic, strong) XMPPRoomHybridStorage *xmppRoomArchiveStorage;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterArchiveStorage;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppVCardArchiveStorage;
@property (nonatomic, strong) XMPPMessageDeliveryReceipts* xmppMessageDeliveryRecipts;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRoom *xmppRoom;

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSArray *registerElements;
@property GCDMulticastDelegate <ChatProtocol> *multicastDelegate;
@property XmppRequestType requestType;
@property (nonatomic, retain) MBProgressHUD *m_HUD;
@end

@implementation ChatProtocolManager

+(instancetype)sharedChatManager {
    
    static ChatProtocolManager* sharedChatManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedChatManager = [[ChatProtocolManager alloc] init];
        sharedChatManager.multicastDelegate = (GCDMulticastDelegate <ChatProtocol> *)[[GCDMulticastDelegate alloc] init];
        sharedChatManager.buddyList = [[NSMutableArray alloc] init];
    });
    
    return sharedChatManager;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // Asynchronous operation (if outside xmppQueue)
    
    [self.multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // Synchronous operation
    
    [self.multicastDelegate removeDelegate:delegate delegateQueue:delegateQueue];
}

- (void)removeDelegate:(id)delegate
{
    // Synchronous operation
    
    [self.multicastDelegate removeDelegate:delegate];
}

- (void)setupStream {
    
    if (self.xmppStream == nil) {
        
        self.xmppStream = [[XMPPStream alloc] init];
        [self.xmppStream setHostName:DEFAULT_HOST_NAME];
        [self.xmppStream setHostPort:DEFAULT_PORT_NUMBER];
        self.xmppStream.enableBackgroundingOnSocket = YES;
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    if (self.xmppReconnect == nil) {
        
        self.xmppReconnect = [[XMPPReconnect alloc] init];
        [self.xmppReconnect activate:self.xmppStream];
        [self.xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    if (self.xmppMessageDeliveryRecipts == nil) {
        
        self.xmppMessageDeliveryRecipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        self.xmppMessageDeliveryRecipts.autoSendMessageDeliveryReceipts = YES;
        self.xmppMessageDeliveryRecipts.autoSendMessageDeliveryRequests = YES;
        [self.xmppMessageDeliveryRecipts activate:self.xmppStream];
    }
    
    if (self.xmppMessageArchivingModule == nil) {
        
        self.xmppMessageArchivingStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
        self.xmppMessageArchivingModule = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:self.xmppMessageArchivingStorage];
        [self.xmppMessageArchivingModule setClientSideMessageArchivingOnly:YES];
        [self.xmppMessageArchivingModule activate:self.xmppStream];
        [self.xmppMessageArchivingModule  addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    if (self.xmppRoster == nil) {
        
        self.xmppRosterArchiveStorage = [XMPPRosterCoreDataStorage sharedInstance];
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterArchiveStorage];
        self.xmppRoster.autoFetchRoster = YES;
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        [self.xmppRoster activate:self.xmppStream];
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    self.xmppRoomArchiveStorage = [XMPPRoomHybridStorage sharedInstance];
    if (self.xmppMessageCarbon == nil) {
        
        self.xmppMessageCarbon = [[XMPPMessageCarbons alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        [self.xmppMessageCarbon activate:self.xmppStream];
        [self.xmppMessageCarbon addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    //self.xmppVCardArchiveStorage = [XMPPvCardCoreDataStorage sharedInstance];
}

- (void)goOnline {
    
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}

- (void)printPresence {
    
    XMPPPresence * presence =[XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
    NSLog(@"*********%@",presence.type);
}

- (void)goOffline {
    if (self.sendPresenceTimer != nil)[self.sendPresenceTimer invalidate];
    
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

- (void)setAllOffline{
    
    for (BasicType *obj in self.buddyList) {
        if([obj isKindOfClass:[Buddy class]]){
            Buddy *buddy = (Buddy *)obj;
            buddy.status = kBuddyStatusOffline;
        }
    }
    BUDDYLISTMANAGER.onlineBuddies = @[];
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(allBuddyWentOffline)]) {
        [self.multicastDelegate allBuddyWentOffline];
    }
}

- (BOOL)isConnected{
    return [self.xmppStream isConnected];
}

- (void)registerUser:(NSDictionary *)params {
    
    [self showLoader];
    
    NSMutableArray *elements = [NSMutableArray array];
    [elements addObject:[NSXMLElement elementWithName:@"username" stringValue:params[@"username"]]];
    [elements addObject:[NSXMLElement elementWithName:@"password" stringValue:params[@"password"]]];
    [elements addObject:[NSXMLElement elementWithName:@"name" stringValue:params[@"username"]]];
    [elements addObject:[NSXMLElement elementWithName:@"email" stringValue:params[@"email"]]];
    //[elements addObject:[NSXMLElement elementWithName:@"accountType" stringValue:@"3"]];
    //[elements addObject:[NSXMLElement elementWithName:@"deviceToken" stringValue:@"adfg3455bhjdfsdfhhaqjdsjd635n"]];
    self.registerElements = elements;
    self.requestType = kTagXmppRequestRegister;
    [self setupStream];
    
    [self.xmppStream setMyJID:[XMPPJID jidWithString:[@"anonymous" addHostName]]];
    
    NSError *error = nil;
    if ([self.xmppStream isConnected] && self.xmppStream.supportsInBandRegistration) {
        [self hideLoader];
        
        if (![self.xmppStream registerWithElements:elements error:&error])
        {
            NSLog(@"Oops, I forgot something: %@", error);
        }else{
            NSLog(@"No Error");
        }
    } else {
        if (![self.xmppStream connectWithTimeout:30 error:&error]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
            [self hideLoader];
        }
    }
}

- (void)changePassword:(NSDictionary *)params{
    
    [self showLoader];
    
    XMPPRegistration *registration = [[XMPPRegistration alloc] init];
    [registration activate:self.xmppStream];
    [registration addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [registration changePassword:params[@"password"]];
}
/*
 - (UIImage*)getAvatarForUser:(NSString *)userId {
 
 [APPDELEGATE startLoading];
 XMPPvCardTempModule *vCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppVCardArchiveStorage];
 [vCardTempModule activate:self.xmppStream];
 [vCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
 UIImage *image = nil;
 
 if (![userId isEqualToString:GETUSERID]) {
 
 [vCardTempModule fetchvCardTempForJID:[XMPPJID jidWithString:[userId addHostName]] ignoreStorage:YES];
 } else {
 XMPPvCardTemp *myvCardTemp = [vCardTempModule myvCardTemp];
 image = [UIImage imageWithData:myvCardTemp.photo];
 [APPDELEGATE stopLoading];
 }
 
 return  image;
 }
 
 - (void)updateAvatar:(UIImage *)avatar forUser:(NSString*)userId {
 [APPDELEGATE startLoading];
 NSData *imageData1 = UIImageJPEGRepresentation(avatar,0.5);
 
 XMPPvCardTempModule *vCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppVCardArchiveStorage];
 [vCardTempModule activate:self.xmppStream];
 [vCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
 
 if (![userId isEqualToString:GETUSERID]) {
 [APPDELEGATE stopLoading];
 //        XMPPvCardTemp *vCardTemp = [vCardTempModule vCardTempForJID:[XMPPJID jidWithString:[userId addHostName]] shouldFetch:YES];
 
 //        [vCardTemp setPhoto:imageData1];
 //        [self.xmppVCardArchiveStorage setvCardTemp:vCardTemp forJID:[XMPPJID jidWithString:[userId addHostName]] xmppStream:self.xmppStream];
 
 NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
 
 [iq addAttributeWithName:@"id" stringValue:@"set1"];
 [iq addAttributeWithName:@"type" stringValue:@"set"];
 [iq addAttributeWithName:@"to" stringValue:[userId addGroupHostName]];
 
 NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"];
 [iq addChild:vCardXML];
 
 NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
 NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"stringValue:@"image/jpeg"];
 NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL" stringValue:[NSString encodeBase64FromImage:avatar]];
 
 [photoXML addChild:typeXML];
 [photoXML addChild:binvalXML];
 [vCardXML addChild:photoXML];
 
 [self.xmppStream sendElement:iq];
 
 }else
 {
 NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"];
 NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
 NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"stringValue:@"image/jpeg"];
 NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL" stringValue:[NSString encodeBase64FromImage:avatar]];
 
 [photoXML addChild:typeXML];
 [photoXML addChild:binvalXML];
 [vCardXML addChild:photoXML];
 XMPPvCardTemp *myvCardTemp = [vCardTempModule myvCardTemp];
 if (myvCardTemp) {
 [myvCardTemp setPhoto:imageData1];
 [vCardTempModule updateMyvCardTemp :myvCardTemp];
 }
 else {
 XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement:vCardXML];
 [vCardTempModule updateMyvCardTemp:newvCardTemp];
 }
 }
 }
 */
- (BOOL)loginUser:(NSDictionary *)params {
    
    NSString *jabberID      =  params[@"username"];
    NSString *myPassword    =  params[@"password"];
    
    jabberID = [jabberID addHostName];
    self.password = myPassword;
    
    [self setupStream];
    NSString *uniqueUUID = GETUNIQUEUUID;
    if (uniqueUUID == nil) {
        uniqueUUID = [self.xmppStream generateUUID];
        uniqueUUID = [@"ChatApp-" stringByAppendingString:uniqueUUID];
        [[NSUserDefaults standardUserDefaults] setObject:uniqueUUID forKey:UNIQUEUUID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self.xmppStream setMyJID:[XMPPJID jidWithString:jabberID resource:uniqueUUID]];
    
    NSError *error = nil;
    self.requestType = kTagXmppRequestLogin;
    
    if ([self.xmppStream isConnected]) {
        
        [[self xmppStream] authenticateWithPassword:self.password error:&error];
        return YES;
    } else {
        
        if (![self.xmppStream connectWithTimeout:30 error:&error]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
            [self hideLoader];
            return NO;
        }
    }
    return YES;
}

- (BOOL)connect {
    
    [self setupStream];
    
    [self.xmppStream setMyJID:[XMPPJID jidWithString:[@"anonymous" addHostName]]];
    
    NSError *error = nil;
    if (![self.xmppStream connectWithTimeout:30 error:&error]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        [self hideLoader];
        return NO;
    }
    
    return YES;
}

- (void)disconnect {
    
    [self goOffline];
    [self.buddyList removeAllObjects];
    
    [self.xmppStream removeDelegate:self];
    [self.xmppStream disconnectAfterSending];
    self.xmppStream = nil;
    
    [self.xmppMessageArchivingModule removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppMessageArchivingModule deactivate];
    self.xmppMessageArchivingModule = nil;
    
    [self.xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppRoster deactivate];
    self.xmppRoster = nil;
    
    [self.xmppMessageCarbon removeDelegate:self];
    [self.xmppMessageCarbon deactivate];
    self.xmppMessageCarbon = nil;
    
    [self.xmppMessageDeliveryRecipts deactivate];
    self.xmppMessageDeliveryRecipts = nil;
}

- (void)updateBuddyListXmpp:(NSArray *)buddies needRemove:(BOOL)status {
    
    for (BasicType *obj in buddies) {
        if (obj == nil) {
            continue;
        }
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == %@", obj.accountName];
        NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
        if (status) {
            if (results.count > 0) {
                [self.buddyList removeObject:obj];
            }
        } else {
            if (results.count == 0) {
                [self.buddyList addObject:obj];
            } else if (results.count == 1) {
                [self.buddyList removeObject:results[0]];
                [self.buddyList addObject:obj];
            }
        }
    }
    
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(updateFriendList:)]) {
        
        [self updateBuddyListWithRecentMessage:self.buddyList];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recentMessageTimestamp" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        self.buddyList = [NSMutableArray arrayWithArray:[self.buddyList sortedArrayUsingDescriptors:sortDescriptors]];
        [self.multicastDelegate updateFriendList:self.buddyList];
    }
}

- (void)loadChatHistoryFromXMPPServer {
    
    /*<iq type='get' id='mrug_sender@staging.openfire.com'>
     <list xmlns='urn:xmpp:archive'>
     <set xmlns='http://jabber.org/protocol/rsm'>
     <max>6900</max>
     </set>
     </list>
     </iq>*/
    
    /*
     <iq type='get' id='list1'>
     <list xmlns='urn:xmpp:archive'
     start='1469-07-21T02:00:00Z'>
     <set xmlns='http://jabber.org/protocol/rsm'>
     <max>30</max>
     </set>
     </list>
     </iq>
     */
    
    [self retrieveChatHistoryFromXMPPServer];
    
}

- (void)addBuddy:(NSString *)buddyName {
    
    XMPPJID *newBuddy = [XMPPJID jidWithString:[buddyName addHostName]];
    [self.xmppRoster addUser:newBuddy withNickname:buddyName];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[newBuddy user]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeBuddy:(Buddy *)buddy {
    
    [self.xmppRoster removeUser:buddy.user];
}

- (NSArray *)fetchBuddyListFromDatabase {
    
    NSArray *tempUsers = [DATABASEMANAGER getAllContactsForUser:[GETUSERID addHostName]];
    NSMutableArray *buddies = [[NSMutableArray alloc] init];
    
    for (NSDictionary *user in tempUsers) {
        
        Buddy *buddy = [[Buddy alloc] init];
        buddy.type = kBaseTypeBuddy;
        buddy.displayName = user[@"displayName"];
        buddy.accountName = [user[@"contactJId"] removeHostName];
        buddy.subscriptionType = user[@"subscriptionType"];
        buddy.profileImageURL = user[@"avatarPath"];
        buddy.user = [XMPPJID jidWithString:user[@"contactJId"]];
        buddy.user_type         = [user[@"user_type"] integerValue];
        [buddies addObject:buddy];
    }
    return buddies;
}

- (Buddy *)getBuddyListFromDatabase:(NSString *)sender {
    
    NSDictionary *user = [DATABASEMANAGER getContact:sender forUser:[GETUSERID addHostName]];
    
    Buddy *buddy = [[Buddy alloc] init];
    buddy.type = kBaseTypeBuddy;
    buddy.displayName = user[@"displayName"];
    buddy.accountName = [user[@"contactJId"] removeHostName];
    buddy.subscriptionType = user[@"subscriptionType"];
    buddy.profileImageURL = user[@"avatarPath"];
    buddy.user = [XMPPJID jidWithString:user[@"contactJId"]];
    buddy.user_type         = [user[@"user_type"] integerValue];
    
    return buddy;
}

- (void)loadBuddyListFromDatabase:(BOOL)needServerLoad {
    [self.buddyList removeAllObjects];
    [self updateBuddyListXmpp:[self fetchBuddyListFromDatabase] needRemove:NO];
    if (needServerLoad) {
        [self fetchBuddyListFromServer];
    }
}

- (void)loadGroupListFromDatabase:(BOOL)needServerLoad {
    
    NSArray *tempGroups = [DATABASEMANAGER getAllGroupsOfUser:[GETUSERID addHostName]];
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    
    for (NSDictionary *objGroup in tempGroups) {
        
        Group *group = [[Group alloc] init];
        group.type = kBaseTypeGroup;
        group.displayName = objGroup[@"displayName"];
        group.deleted = [objGroup[@"isDeleted"] boolValue];
        group.accountName = [objGroup[@"groupJId"] removeHostName];
        group.roomJID = [XMPPJID jidWithString:objGroup[@"groupJId"]];
        group.profileImageURL = objGroup[@"avatarPath"];
        group.groupUsers = [DATABASEMANAGER getGroupMembers:objGroup[@"groupJId"] forUser:[GETUSERID addHostName]];
        group.centerId  = objGroup[@"center_id"];
        [groups addObject:group];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self joinChatRoomName:group.accountName users:group.groupUsers];
        });
    }
    
    [self updateBuddyListXmpp:groups needRemove:NO];
    if (needServerLoad) {
            if(![CHATMANAGER isConnected])   // in case open fire is not connected
                return;
        [self getGroupListFromServer];
    }
}

- (void)getGroupListFromServer {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"username" : [self getMyJid]}];
    //NSLog(@"params = %@", params);
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_user_groups"];
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        NSLog(@"success = %d && responseData = %@", success, responseData);
        
        if (success) {
            
            NSMutableArray *tempGroups = [[NSMutableArray alloc] init];
            NSMutableArray *tempGroupsForDB = [[NSMutableArray alloc] init];
            NSString *center_id = [Utility getValueFromDictionary:responseData Key:@"center_id"];
            NSArray *groups = responseData[@"group_details"];
            for (NSDictionary *objGroup in groups) {
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", objGroup[@"group_id"]];
                NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
                Group *group = nil;
                if (results.count > 0) {
                    group= (Group *)results[0];
                } else {
                    group = [[Group alloc] init];
                }
                
                group.type = kBaseTypeGroup;
                group.displayName = objGroup[@"group_name"];
                group.accountName = objGroup[@"group_id"];
                group.roomJID = [XMPPJID jidWithString:[objGroup[@"group_id"] addGroupHostName]];
                group.deleted = NO;
                group.groupUsers = [NSMutableArray arrayWithArray:objGroup[@"members"]];
                group.centerId = [Utility getValueFromDictionary:objGroup Key:@"center_id"];
                [tempGroups addObject:group];
                
                [tempGroupsForDB addObject:@{@"displayName" : (group.displayName == nil ? @"" : group.displayName),
                                             @"groupAvatarPath" : @"",
                                             @"members" : group.groupUsers,
                                             @"groupJId" : [objGroup[@"group_id"] addGroupHostName],
                                             @"userJId" : [self getMyJid],
                                             @"isDeleted" : @0,
                                             @"center_id" : center_id}];
                
                NSMutableArray *members = [DATABASEMANAGER getGroupMembers:[objGroup[@"group_id"] addGroupHostName] forUser:[self.xmppStream myJID].bare];
                for (NSMutableDictionary *dict in members) {
                    [dict setValue:@1 forKey:@"isDeleted"];
                    [DATABASEMANAGER updateGroupMember:dict];
                }
                
                for (NSDictionary *d in group.groupUsers) {
                    NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[objGroup[@"group_id"] addGroupHostName] forUser:[self.xmppStream myJID].bare member:d[@"name"] ];
                    if (dict == nil || dict.count == 0) {
                        [DATABASEMANAGER insertUserGroupMembers:@[d] group:[objGroup[@"group_id"] addGroupHostName] user:[self.xmppStream myJID].bare];
                    } else {
                        [dict setValue:@0 forKey:@"isDeleted"];
                        [DATABASEMANAGER updateGroupMember:dict];
                    }
                }
            }
            
            if (tempGroups.count > 0) {
                
                [DATABASEMANAGER insertUserGroups:tempGroupsForDB];
                for (Group *group in tempGroups) {
                    group.groupUsers = [DATABASEMANAGER getGroupMembers:[group.accountName addGroupHostName] forUser:[self getMyJid] ];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self joinChatRoomName:group.accountName users:group.groupUsers];
                    });
                }
                [self updateBuddyListXmpp:tempGroups needRemove:NO];
            }
            
            NSMutableArray *userGroups = [DATABASEMANAGER getAllGroupsOfUser:[self.xmppStream myJID].bare ];
            for (NSMutableDictionary *dict1 in userGroups) {
                
                BOOL isFound = NO;
                for (NSDictionary *objGroup in groups) {
                    
                    if ([dict1[@"groupJId"] isEqualToString:[objGroup[@"group_id"] addGroupHostName]]) {
                        isFound = YES;
                        break;
                    }
                }
                if (!isFound) {
                    [dict1 setValue:@1 forKey:@"isDeleted"];
                    [DATABASEMANAGER updateGroup:dict1 ];
                    
                    NSMutableArray *members = [DATABASEMANAGER getGroupMembers:dict1[@"groupJId"] forUser:[self.xmppStream myJID].bare ];
                    for (NSMutableDictionary *dict in members) {
                        [dict setValue:@1 forKey:@"isDeleted"];
                        [DATABASEMANAGER updateGroupMember:dict ];
                    }
                    
                    XMPPJID *roomJID = [XMPPJID jidWithString:dict1[@"groupJId"]];
                    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJID];
                    [self.xmppRoom activate:self.xmppStream];
                    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
                    [self.xmppRoom leaveRoom:roomJID];
                }
            }
        }
    }];
}

- (void)addGroup:(NSString *)groupName withBuddies:(NSArray *)buddies {
    
    if(![CHATMANAGER isConnected])   // in case open fire is not connected
        return;
    
    NSMutableArray *tempBuddies = [[NSMutableArray alloc] init];
    for (Buddy *objBuddy in buddies) {
        
        NSDictionary *dict = @{@"name" : [objBuddy.accountName addHostName],
                               @"is_admin" : @0};
        [tempBuddies addObject:dict];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_name" :   groupName,
                                                                                  @"admin"      :   [self.xmppStream myJID].bare,
                                                                                  @"members"    :   tempBuddies
                                                                                  }];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"add_group"];
    
    //NSLog(@"params = %@", params);
    [self showLoader];
    
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        NSLog(@"success = %d && responseData = %@", success, responseData);
        
        
        if (success) {
            
            NSString *groupNameS = responseData[@"group_id"];
            XMPPJID *roomJid = [XMPPJID jidWithString:groupNameS];
            
            if (roomJid != nil) {
                Group *group = [[Group alloc] init];
                group.type = kBaseTypeGroup;
                group.displayName = groupName;
                group.accountName = groupNameS;
                group.roomJID = roomJid;
                NSDictionary *dict = @{@"name" : [self.xmppStream myJID].bare,
                                       @"is_admin" : @1};
                [tempBuddies addObject:dict];
                group.groupUsers = tempBuddies;
                
                [DATABASEMANAGER insertUserGroups:@[@{@"displayName" : (group.displayName == nil ? @"" : group.displayName),
                                                      @"groupAvatarPath" : @"",
                                                      @"members" : group.groupUsers,
                                                      @"groupJId" : [groupNameS addGroupHostName],
                                                      @"userJId" : [self getMyJid],
                                                      @"isDeleted" : @0}]];
                
                group.groupUsers = [DATABASEMANAGER getGroupMembers:[group.accountName addGroupHostName] forUser:[self getMyJid]];
                [self updateBuddyListXmpp:@[group] needRemove:NO];
                
                [self joinChatRoomName:groupNameS users:group.groupUsers];
                //                [self hideLoader];
            }else{
                [self hideLoader];
            }
        }
    }];
}

- (void)inviteUsers:(NSArray *)users forGroup:(NSString *)group {
    
    if(![CHATMANAGER isConnected])   // in case open fire is not connected
        return;
    
    NSMutableArray *tempBuddies = [[NSMutableArray alloc] init];
    for (Buddy *objBuddy in users) {
        
        NSDictionary *dict = @{@"name" : [objBuddy.accountName addHostName],
                               @"is_admin" : @0};
        [tempBuddies addObject:dict];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_id" : group,
                                                                                  @"members" : tempBuddies}];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"add_members"];
    //NSLog(@"params = %@", params);
    [self showLoader];
    
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        NSLog(@"success = %d && responseData = %@", success, responseData);
        
        NSMutableArray *groupMembers = [NSMutableArray array];
        if (success && [responseData[@"status"] boolValue]) {
            
            XMPPJID *roomJid = [XMPPJID jidWithString:[group addGroupHostName]];
            self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJid];
            [self.xmppRoom activate:self.xmppStream];
            [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
            
            for (NSDictionary *buddy in tempBuddies) {
                
                XMPPJID *user = [XMPPJID jidWithString:buddy[@"name"]];
                [self.xmppRoom inviteUser:user withMessage:@"Hi from Xplor"];
                BasicType *obj = [[BasicType alloc] init];
                obj.accountName = group;
                [self sendMessage:[NSString stringWithFormat:@"%@%@", CODE_FOR_MEMBER_ADDED, buddy[@"name"]] toGroup:obj];
                
                NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[obj.accountName addGroupHostName] forUser:[self.xmppStream myJID].bare member:buddy[@"name"]];
                if (dict && dict.count > 0) {
                    [dict setValue:@0 forKey:@"isDeleted"];
                    [dict setValue:[buddy[@"name"] removeHostName] forKey:@"memberDisplayName"];
                    [DATABASEMANAGER updateGroupMember:dict];
                    [groupMembers addObject:dict];
                } else {
                    NSMutableDictionary *d = [NSMutableDictionary dictionary];
                    [d setValue:[buddy[@"name"] removeHostName] forKey:@"memberDisplayName"];
                    [d setValue:buddy[@"name"] forKey:@"memberJId"];
                    [d setValue:@0 forKey:@"isAdmin"];
                    [d setValue:[obj.accountName addGroupHostName] forKey:@"groupJId"];
                    [d setValue:[self.xmppStream myJID].bare forKey:@"userJId"];
                    [d setValue:@0 forKey:@"isDeleted"];
                    [DATABASEMANAGER insertUserGroupMembers:@[d] group:[obj.accountName addGroupHostName] user:[self.xmppStream myJID].bare ];
                    [groupMembers addObject:d];
                }
            }
            [self hideLoader];
        }else{
            [self hideLoader];
        }
        if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(buddyAddedToGroup:users:)]) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", group];
            NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
            Group *group = nil;
            if (results.count > 0){
                group= (Group *)results[0];
                [group.groupUsers addObjectsFromArray:groupMembers];
            }
            
            [self.multicastDelegate buddyAddedToGroup:[responseData[@"status"] boolValue] users:groupMembers];
        }
    }];
}

- (void)joinChatRoomName:(NSString *)groupName users:(NSArray *)groupUsers {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", groupName];
    NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
    Group *group = nil;
    if (results.count > 0) {
        group= (Group *)results[0];
        //NSLog(@"group name = %@ isJoined = %d deleted = %d", group.accountName, group.isJoined, group.deleted);
        if (!group.deleted && !group.isJoined) {
            XMPPJID *roomJID = [XMPPJID jidWithString:[groupName addGroupHostName]];
            if (roomJID == nil) return;
            self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJID];
            if (groupUsers) {
                self.xmppRoom.roomeUsers = groupUsers;
            }
            
            [self.xmppRoom activate:self.xmppStream];
            [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
            
            NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
            [history addAttributeWithName:@"maxchars" stringValue:@"0"];
            [self.xmppRoom joinRoomUsingNickname:[self getMyJid] history:history password:nil];
        }
    }
}

- (void)leaveChatRoom:(NSString *)groupName user:(NSString *)userName {
    
    if(![CHATMANAGER isConnected])   // in case open fire is not connected
        return;
    
    [self showLoader];
    
    NSArray *tempBuddies = @[@{@"name" : [[XMPPJID jidWithString:userName] bare]}];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_id" : groupName,
                                                                                  @"members" : tempBuddies
                                                                                  }];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"remove_members"];
    
    //Remove user from group web service here.
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        [self hideLoader];
        NSLog(@"success = %d && responseData = %@", success, responseData);
        
        if (success && [responseData[@"status"] boolValue]) {
            
            NSString *message = @"";
            if ([[userName removeHostName] isEqualToString:[[self.xmppStream myJID].user removeHostName]]) {
                message = [NSString stringWithFormat:@"%@%@##left", CODE_FOR_MEMBER_REMOVED, userName];
            } else {
                message = [NSString stringWithFormat:@"%@%@##remove", CODE_FOR_MEMBER_REMOVED, userName];
            }
            
            BasicType *obj = [[BasicType alloc] init];
            obj.accountName = [groupName removeHostName];
            [self sendMessage:message toGroup:obj];
            
            
            NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[obj.accountName addGroupHostName] forUser:[self.xmppStream myJID].bare member:userName ];
            [dict setValue:@1 forKey:@"isDeleted"];
            [DATABASEMANAGER updateGroupMember:dict ];
            
            //            NSMutableArray *members = [DATABASEMANAGER getGroupMembers:[obj.accountName addGroupHostName] forUser:[self.xmppStream myJID].bare];
            //            for (NSMutableDictionary *dict in members) {
            //                [dict setValue:@1 forKey:@"isDeleted"];
            //                [DATABASEMANAGER updateGroupMember:dict];
            //            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [groupName removeHostName]];
            NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
            Group *group;
            if (results.count>0)
                group= (Group *)results[0];
            
            for (int loopIndex = 0; loopIndex < group.groupUsers.count; loopIndex++) {
                
                NSDictionary *userInfo = group.groupUsers[loopIndex];
                if ([userInfo[@"memberJId"] isEqualToString:userName]) {
                    [group.groupUsers removeObjectAtIndex:loopIndex];
                    break;
                }
            }
        }
        
        if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(buddyRemovedFromGroup:users:)]) {
            [self.multicastDelegate buddyRemovedFromGroup:[responseData[@"status"] boolValue] users:tempBuddies];
        }
    }];
}

- (void)handleGroupInvitations:(XMPPMessage *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        NSXMLElement *queryElement = [message elementForName:@"x" xmlns:@"jabber:x:conference"];
        if (queryElement) {
            
            NSXMLElement *xElement = [message elementForName: @"x" xmlns: XMPPMUCUserNamespace];
            if (xElement) {
                
                NSXMLElement *invite = [xElement elementForName:@"invite"];
                if (invite) {
                    if(![CHATMANAGER isConnected])   // in case open fire is not connected
                        return;
                    //NSString *from = [[invite attributeForName:@"from"] stringValue];
                    //NSString *reason = [[invite elementForName:@"reason"] stringValue];
                    //NSString *title = [NSString stringWithFormat:@"Invitation received from %@ for group %@", [from removeHostName], [[message fromStr] removeHostName]];
                    
                    //                    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:title message:reason delegate:self cancelButtonTitle:@"Deny" otherButtonTitles:@"Accept", nil];
                    //                    alert.dataDetails = message;
                    //                    alert.tag = kAlertViewTagGroupInvitation;
                    //                    [alert show];
                    
                    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_id" : [[[message attributeForName:@"from"] stringValue] removeHostName]}];
                    //NSLog(@"params = %@", params);
                    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_group_detail"];
                    
                    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
                        
                        NSLog(@"success = %d && responseData = %@", success, responseData);
                        
                        if (success && [responseData[@"status"] boolValue]) {
                            
                            XMPPJID *roomJid = [XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]];
                            if (roomJid != nil) {
                                Group *group = [[Group alloc] init];
                                group.type = kBaseTypeGroup;
                                group.displayName = responseData[@"group_name"];
                                group.accountName = responseData[@"group_id"];
                                group.roomJID = roomJid;
                                group.deleted = NO;
                                group.groupUsers = [NSMutableArray arrayWithArray:responseData[@"members"]];
                                
                                [DATABASEMANAGER insertUserGroups:@[@{@"displayName" : (group.displayName == nil ? @"" : group.displayName),
                                                                      @"groupAvatarPath" : @"",
                                                                      @"members" : group.groupUsers,
                                                                      @"groupJId" : [responseData[@"group_id"] addGroupHostName],
                                                                      @"userJId" : [self getMyJid],
                                                                      @"isDeleted" : @0}]];
                                
                                NSMutableArray *members = [DATABASEMANAGER getGroupMembers:[responseData[@"group_id"] addGroupHostName] forUser:[self.xmppStream myJID].bare ];
                                for (NSMutableDictionary *dict in members) {
                                    [dict setValue:@1 forKey:@"isDeleted"];
                                    [DATABASEMANAGER updateGroupMember:dict ];
                                }
                                
                                for (NSDictionary *d in group.groupUsers) {
                                    
                                    NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[group.accountName addGroupHostName] forUser:[self.xmppStream myJID].bare member:d[@"name"] ];
                                    if (dict == nil || dict.count == 0) {
                                        [DATABASEMANAGER insertUserGroupMembers:@[d] group:[group.accountName addGroupHostName] user:[self.xmppStream myJID].bare ];
                                    } else {
                                        [dict setValue:@0 forKey:@"isDeleted"];
                                        [DATABASEMANAGER updateGroupMember:dict ];
                                    }
                                }
                                
                                group.groupUsers = [DATABASEMANAGER getGroupMembers:[group.accountName addGroupHostName] forUser:[self getMyJid] ];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self joinChatRoomName:group.accountName users:group.groupUsers];
                                });
                                
                                [self updateBuddyListXmpp:@[group] needRemove:NO];
                                if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(updateBuddyInChatController:)]) {
                                    [self.multicastDelegate updateBuddyInChatController:group];
                                }
                            }
                        }
                    }];
                    
                    return ;
                }
                NSXMLElement *decline = [xElement elementForName:@"decline"];
                if (decline) {
                    
                    if(![CHATMANAGER isConnected])   // in case open fire is not connected
                        return;
                    NSString *groupName = [[queryElement attributeForName:@"jid"] stringValue];
                    NSArray *tempBuddies = @[@{@"name" : [[XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]] bare]}];
                    
                    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_id" : groupName,
                                                                                                  @"members" : tempBuddies
                                                                                                  }];
                    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"remove_members"];
                    
                    
                    
                    //Remove user from group web service here.
                    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData){
                        
                        NSLog(@"success = %d && responseData = %@", success, responseData);
                        
                        if (success) {
                            showAlertWithTitleWithoutAction(@"Declined", [NSString stringWithFormat:@"%@ declined invitation of group %@.", [[[XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]] bare] removeHostName], groupName], ALERT_BUTTON_TITLE_OK);
                        }
                    }];
                }
            }
        }
    });
}

- (void)sendMessage:(NSString *)messageStr toGroup:(BasicType *)group {
    
    //<message type="groupchat" to="chatroom1@muc.chat.quickblox.com"><body>test message</body><subject>GroupNameSubject</subject></message>
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"groupchat"];
    [message addAttributeWithName:@"id" stringValue:[[[self.xmppStream generateUUID] substringToIndex:8] lowercaseString]];
    [message addAttributeWithName:@"to" stringValue:[group.accountName addGroupHostName]];
    [message addAttributeWithName:@"from" stringValue:[[self getMyJid] stringByAppendingPathComponent:[[self.xmppStream myJID] resource]]];
    //    [message addAttributeWithName:@"center_id" stringValue:[Utility getCenterId]];
    

    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];
    [message addChild:body];
    
    XMPPMessage *msg = [XMPPMessage messageFromElement:message];
    [msg addBody:[[self.xmppStream myJID] resource] withLanguage:@"resource"];
    
    [self.xmppStream sendElement:msg];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    [messageDict setValue:@1 forKey:@"isFromMe"];
    [messageDict setValue:@0 forKey:@"messageStatus"];
    [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
    [messageDict setValue:[body stringValue] forKey:@"message"];
    [messageDict setValue:[[message attributeForName:@"id"] stringValue] forKey:@"packetId"];
    [messageDict setValue:[message description] forKey:@"messageStanza"];
    [messageDict setValue:@1 forKey:@"isGroupMessage"];
    [messageDict setValue:[[message attributeForName:@"to"] stringValue] forKey:@"groupJId"];
    [messageDict setValue:[[[message attributeForName:@"from"] stringValue] removeLastPathComponent] forKey:@"bareJId"];
    [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
    [DATABASEMANAGER insertMessage:messageDict ];
    
    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    [recentMessageDict setValue:[self recentMessageForMessage:messageDict] forKey:@"recentMessage"];
    [recentMessageDict setValue:messageDict[@"groupJId"] forKey:@"bareJId"];
    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
}

- (void)sendMessage:(NSString *)messageStr ToUser:(NSString *)toUser {
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:[[[self.xmppStream generateUUID] substringToIndex:8] lowercaseString]];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[toUser addHostName]];
    //    [message addAttributeWithName:@"center_id" stringValue:[Utility getCenterId]];
    
    // using this code to add center_id to make it same as android
//    NSXMLElement *center_id_body = [NSXMLElement elementWithName:@"center_id"];
//    [center_id_body setStringValue:[Utility getCenterId]];
//    NSXMLElement *centerId = [NSXMLElement elementWithName:@"center_id" URI:@"urn:xmpp:center_id"];
//    [centerId addChild:center_id_body];
//    [message addChild:centerId];
//    
//    [message addChild:body];
    [self.xmppStream sendElement:message];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    [messageDict setValue:@1 forKey:@"isFromMe"];
    [messageDict setValue:@0 forKey:@"messageStatus"];
    [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
    [messageDict setValue:[body stringValue] forKey:@"message"];
    [messageDict setValue:[[message attributeForName:@"id"] stringValue] forKey:@"packetId"];
    [messageDict setValue:[message description] forKey:@"messageStanza"];
    [messageDict setValue:@0 forKey:@"isGroupMessage"];
    [messageDict setValue:@"" forKey:@"groupJId"];
    [messageDict setValue:[toUser addHostName] forKey:@"bareJId"];
    [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
    [DATABASEMANAGER insertMessage:messageDict ];
    
    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    [recentMessageDict setValue:messageDict[@"bareJId"] forKey:@"bareJId"];
    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
}

- (void)sendPendingMessage:(NSDictionary *)messageDic toGroup:(NSString *)groupJID{
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"groupchat"];
    [message addAttributeWithName:@"id" stringValue:[messageDic objectForKey:@"_id"]];
    [message addAttributeWithName:@"to" stringValue:groupJID];
    [message addAttributeWithName:@"resource" stringValue:[[self.xmppStream myJID] resource]];
    [message addAttributeWithName:@"from" stringValue:[[self getMyJid] stringByAppendingPathComponent:[[self.xmppStream myJID] resource]]];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:[messageDic objectForKey:@"body"]];
    [message addChild:body];
    
    [self.xmppStream sendElement:message];
}

- (void)sendPendingMessage:(NSDictionary *)messageDic ToUser:(NSString *)toUser{
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:[messageDic objectForKey:@"body"]];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:[messageDic objectForKey:@"_id"]];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:toUser];
    [message addChild:body];
    [self.xmppStream sendElement:message];
    
}

- (void)sendMessagePN:(NSString *)messageStr toUser:(NSString *)toUser fromUser:(NSString *)fromUser{
    
    //service call for getting group members
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"username" : toUser,
                                                                                  @"from_username" : fromUser,
                                                                                  @"message" : messageStr}];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"send_offline_notification"];
    
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        NSLog(@"success = %d && responseData = %@", success, responseData);
        
        if (success) {
            
        }
    }];
}

-(void)sendImage:(UIImage *)image Url:(NSString *)strUrl ToUser:(NSString *)toUser {
    
    NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
    [mediaDict setValue:@1 forKey:@"mediaType"];
    
    NSLog(@"------------------------Image send to - %@ ******",toUser);
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:CODE_FOR_IMAGE_IN_MESSAGE];
    
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:[[[self.xmppStream generateUUID] substringToIndex:8] lowercaseString]];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[toUser addHostName]];
    [message addChild:body];
    
    XMPPMessage *msg = [XMPPMessage messageFromElement:message];
    if (image) {
        
        NSData *dataPic =  UIImagePNGRepresentation(image);
        NSString *base64String = [dataPic base64EncodedStringWithOptions:0];
        [msg addBody:base64String withLanguage:@"attachment"];
        [msg addBody:strUrl withLanguage:@"imageUrl"];
        
        [mediaDict setValue:base64String forKey:@"mediaThumbPath"];
        
        NSString *localPath = [[ImageCache sharedImageCache] pathForName:strUrl];
        [mediaDict setValue:localPath forKey:@"mediaLocalPath"];
        [mediaDict setValue:strUrl forKey:@"mediaServerPath"];
        [mediaDict setValue:[NSNumber numberWithDouble:[dataPic length]] forKey:@"mediaSize"];
        NSString *mediaName = getUniqueMediaName();
        [mediaDict setValue:mediaName forKey:@"mediaName"];
    }
    NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
    
    [self.xmppStream sendElement:msg];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    
    if (mediaId>0)
        [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
    [messageDict setValue:@1 forKey:@"isFromMe"];
    [messageDict setValue:@0 forKey:@"messageStatus"];
    [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
    [messageDict setValue:[body stringValue] forKey:@"message"];
    [messageDict setValue:[[message attributeForName:@"id"] stringValue] forKey:@"packetId"];
    [messageDict setValue:[message description] forKey:@"messageStanza"];
    [messageDict setValue:@0 forKey:@"isGroupMessage"];
    [messageDict setValue:@"" forKey:@"groupJId"];
    [messageDict setValue:[toUser addHostName] forKey:@"bareJId"];
    [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
    [DATABASEMANAGER insertMessage:messageDict ];
    
    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    [recentMessageDict setValue:messageDict[@"bareJId"] forKey:@"bareJId"];
    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
}

-(void)sendImage:(UIImage *)image Url:(NSString *)strUrl ToGroup:(BasicType *)group {
    
    NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
    [mediaDict setValue:@1 forKey:@"mediaType"];
    
    NSLog(@"------------------------Image send to - %@ ******",group.accountName);
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:CODE_FOR_IMAGE_IN_MESSAGE];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"groupchat"];
    [message addAttributeWithName:@"id" stringValue:[[[self.xmppStream generateUUID] substringToIndex:8] lowercaseString]];
    [message addAttributeWithName:@"to" stringValue:[group.accountName addGroupHostName]];
    //    [message addAttributeWithName:@"resource" stringValue:[[self.xmppStream myJID] resource]];
    [message addAttributeWithName:@"from" stringValue:[self getMyJid]];
    [message addChild:body];
    
    XMPPMessage *msg = [XMPPMessage messageFromElement:message];
    
    if (image) {
        
        NSData *dataPic =  UIImagePNGRepresentation(image);
        NSString *base64String = [dataPic base64EncodedStringWithOptions:0];
        [msg addBody:base64String withLanguage:@"attachment"];
        [msg addBody:strUrl withLanguage:@"imageUrl"];
        [mediaDict setValue:base64String forKey:@"mediaThumbPath"];
        NSString *localPath = [[ImageCache sharedImageCache] pathForName:strUrl];
        [mediaDict setValue:localPath forKey:@"mediaLocalPath"];
        [mediaDict setValue:strUrl forKey:@"mediaServerPath"];
        [mediaDict setValue:[NSNumber numberWithDouble:[dataPic length]] forKey:@"mediaSize"];
        NSString *mediaName = getUniqueMediaName();
        [mediaDict setValue:mediaName forKey:@"mediaName"];
    }
    [msg addBody:[[self.xmppStream myJID] resource] withLanguage:@"resource"];
    
    NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
    
    [self.xmppStream sendElement:msg];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    if (mediaId>0)
        [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
    [messageDict setValue:@1 forKey:@"isFromMe"];
    [messageDict setValue:@0 forKey:@"messageStatus"];
    [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
    [messageDict setValue:[body stringValue] forKey:@"message"];
    [messageDict setValue:[[message attributeForName:@"id"] stringValue] forKey:@"packetId"];
    [messageDict setValue:[message description] forKey:@"messageStanza"];
    [messageDict setValue:@1 forKey:@"isGroupMessage"];
    [messageDict setValue:[[message attributeForName:@"to"] stringValue] forKey:@"groupJId"];
    [messageDict setValue:[[[message attributeForName:@"from"] stringValue] removeLastPathComponent] forKey:@"bareJId"];
    [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
    [DATABASEMANAGER insertMessage:messageDict ];
    
    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    [recentMessageDict setValue:messageDict[@"groupJId"] forKey:@"bareJId"];
    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
}

// used for sending image in group only
-(void)sendImage:(UIImage *)image Url:(NSString *)strUrl MessageId:(NSString *)packetId ToGroup:(BasicType *)group {
    
    NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
    [mediaDict setValue:@1 forKey:@"mediaType"];
    
    NSLog(@"------------------------Image send to - %@ ******",group.accountName);
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:CODE_FOR_IMAGE_IN_MESSAGE];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"groupchat"];
    [message addAttributeWithName:@"id" stringValue:packetId];
    [message addAttributeWithName:@"to" stringValue:[group.accountName addGroupHostName]];
    //    [message addAttributeWithName:@"resource" stringValue:[[self.xmppStream myJID] resource]];
    [message addAttributeWithName:@"from" stringValue:[self getMyJid]];
    [message addChild:body];
    
    XMPPMessage *msg = [XMPPMessage messageFromElement:message];
    
    if (image) {
        
        NSData *dataPic =  UIImagePNGRepresentation(image);
        NSString *base64String = [dataPic base64EncodedStringWithOptions:0];
        [msg addBody:base64String withLanguage:@"attachment"];
        [msg addBody:strUrl withLanguage:@"imageUrl"];
        [mediaDict setValue:base64String forKey:@"mediaThumbPath"];
        NSString *localPath = [[ImageCache sharedImageCache] pathForName:strUrl];
        [mediaDict setValue:localPath forKey:@"mediaLocalPath"];
        [mediaDict setValue:strUrl forKey:@"mediaServerPath"];
        [mediaDict setValue:[NSNumber numberWithDouble:[dataPic length]] forKey:@"mediaSize"];
        NSString *mediaName = getUniqueMediaName();
        [mediaDict setValue:mediaName forKey:@"mediaName"];
    }
    [msg addBody:[[self.xmppStream myJID] resource] withLanguage:@"resource"];
    
    NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
    
    [self.xmppStream sendElement:msg];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    if (mediaId>0)
        [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
    [messageDict setValue:@1 forKey:@"isFromMe"];
    [messageDict setValue:@0 forKey:@"messageStatus"];
    [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
    [messageDict setValue:[body stringValue] forKey:@"message"];
    [messageDict setValue:[[message attributeForName:@"id"] stringValue] forKey:@"packetId"];
    [messageDict setValue:[message description] forKey:@"messageStanza"];
    [messageDict setValue:@1 forKey:@"isGroupMessage"];
    [messageDict setValue:[[message attributeForName:@"to"] stringValue] forKey:@"groupJId"];
    [messageDict setValue:[[[message attributeForName:@"from"] stringValue] removeLastPathComponent] forKey:@"bareJId"];
    [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
    [DATABASEMANAGER insertMessage:messageDict ];
    
    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    [recentMessageDict setValue:messageDict[@"groupJId"] forKey:@"bareJId"];
    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
}


- (NSInteger)unreadMessageCountForBuddy:(NSString *)buddy lastSeen:(double)lastSeen isGroup:(BOOL)isGroup {
    
    NSInteger messageCount;
    if (isGroup) {
        messageCount = [DATABASEMANAGER getGroupMessagesCount:lastSeen :[buddy addGroupHostName] loggedinUser:[self.xmppStream myJID].bare ];
    } else {
        messageCount = [DATABASEMANAGER getUserMessagesCount:lastSeen :[buddy addHostName] loggedinUser:[self.xmppStream myJID].bare ];
    }
    
    return messageCount;
}

-(void)print:(NSMutableArray*)messages{
    
    @autoreleasepool {
        
        for (XMPPMessageArchiving_Message_CoreDataObject *message in messages) {
            
            NSLog(@"messageStr param is %@",message.messageStr);
            NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:message.messageStr error:nil];
            NSLog(@"to param is %@",[element attributeStringValueForName:@"to"]);
            NSLog(@"NSCore object id param is %@",message.objectID);
            NSLog(@"bareJid param is %@",message.bareJid);
            NSLog(@"bareJidStr param is %@",message.bareJidStr);
            NSLog(@"body param is %@",message.body);
            NSLog(@"timestamp param is %@",message.timestamp);
            NSLog(@"outgoing param is %d",[message.outgoing intValue]);
        }
    }
}

- (void)updateBuddyLastSeen:(BasicType *)obj {
    
    NSMutableDictionary *dict = nil;
    if (obj.type == kBaseTypeGroup) {
        dict = [DATABASEMANAGER getRecentMessageOf:[obj.accountName addGroupHostName] andUser:[self.xmppStream myJID].bare ];
    } else {
        dict = [DATABASEMANAGER getRecentMessageOf:[obj.accountName addHostName] andUser:[self.xmppStream myJID].bare ];
    }
    
    [dict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"lastSeenTimestamp"];
    [DATABASEMANAGER updateRecentMessage:dict ];
}

- (void)updateBuddyListWithRecentMessage:(NSArray *)buddies {
    
    for (BasicType *objBuddy in buddies) {
        NSDictionary *dict = nil;
        if (objBuddy.type == kBaseTypeGroup) {
            dict = [DATABASEMANAGER getRecentMessageOf:[objBuddy.accountName addGroupHostName] andUser:[self.xmppStream myJID].bare ];
        } else {
            dict = [DATABASEMANAGER getRecentMessageOf:[objBuddy.accountName addHostName] andUser:[self.xmppStream myJID].bare ];
        }
        if (dict && dict.count > 0) {
            objBuddy.recentMessage = dict[@"recentMessage"];
            objBuddy.recentMessageOutgoing = [dict[@"recentMessageOutgoing"] boolValue];
            objBuddy.recentMessageTimestamp = [NSDate dateWithTimeIntervalSince1970:[dict[@"recentMessageTimestamp"] floatValue]];
            objBuddy.lastSeenTimeStamp = [NSDate dateWithTimeIntervalSince1970:[dict[@"lastSeenTimestamp"] floatValue]];
            objBuddy.unreadMessageCount = [self unreadMessageCountForBuddy:objBuddy.accountName lastSeen:[dict[@"lastSeenTimestamp"] doubleValue] isGroup:(objBuddy.type == kBaseTypeGroup ? YES : NO)];
            
        }else if (objBuddy.type == kBaseTypeGroup)
        {
            objBuddy.recentMessage = @"";
            objBuddy.recentMessageOutgoing = NO;
            objBuddy.recentMessageTimestamp = nil;
            objBuddy.lastSeenTimeStamp = nil;
            objBuddy.unreadMessageCount = 0;
        }
    }
}


- (int)getTotalAUnreadMessageCount:(NSArray *)buddies {
    
    int count   =   0;
    
    for (BasicType *objBuddy in buddies) {
        NSDictionary *dict = nil;
        if (objBuddy.type == kBaseTypeGroup) {
            dict = [DATABASEMANAGER getRecentMessageOf:[objBuddy.accountName addGroupHostName] andUser:[self.xmppStream myJID].bare ];
        } else {
            dict = [DATABASEMANAGER getRecentMessageOf:[objBuddy.accountName addHostName] andUser:[self.xmppStream myJID].bare ];
        }
        if (dict && dict.count > 0) {
            count   =   count   + (int)[self unreadMessageCountForBuddy:objBuddy.accountName lastSeen:[dict[@"lastSeenTimestamp"] doubleValue] isGroup:(objBuddy.type == kBaseTypeGroup ? YES : NO)];
        }
    }
    return count;
}


- (NSString *)getTimeForLastRecivedMessageFromUser:(BasicType *)from {
    
    NSDictionary *dict = nil;
    if (from.type == kBaseTypeGroup) {
        dict = [DATABASEMANAGER getRecentMessageOf:[from.accountName addGroupHostName] andUser:[self getMyJid] ];
    } else {
        dict = [DATABASEMANAGER getRecentMessageOf:[from.accountName addHostName] andUser:[self getMyJid] ];
    }
    
    NSString *time = [[NSDate dateWithTimeIntervalSince1970:[dict[@"recentMessageTimestamp"] floatValue]] composeMessageDate];
    return time;
}

- (NSArray *)loadChatHistoryWithGroup:(BasicType *)buddy {
    
    NSString *groupJid = [buddy.accountName addGroupHostName];
    NSArray *messages = [DATABASEMANAGER getMessagesOfGroup:groupJid loggedinUser:[self getMyJid] ];
    
    NSMutableArray *arrMsg = [NSMutableArray array];
    
    for (NSDictionary *message in messages) {
        
        NSString *messageBody = message[@"message"];
        if (messageBody == nil) continue;
        NSString *packetId = message[@"packetId"];
        NSString *groupJId = message[@"groupJId"];
        NSString *bareJId = message[@"bareJId"];
        NSString *streamBareJId = message[@"streamBareJId"];
        BOOL isFromMe = [message[@"isFromMe"] boolValue];
        NSString *messageStanza = message[@"messageStanza"];
        NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:[message[@"messageDate"] floatValue]];
        int messageType = [message[@"messageType"] intValue];
        NSInteger messageStatus = [message[@"messageStatus"] integerValue];
        NSString *timeStamp = message[@"messageDate"];
        NSString *senderName = @"";
        if (isFromMe) {
            senderName = [streamBareJId removeHostName];
        } else {
            senderName = [bareJId removeHostName];
        }
        NSDictionary * dicMsg = nil;
        NSString *imgUrl = @"";
        UIImage *imgThumb = nil;
        
        if ([messageBody isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
            //NSLog(@"%@",message.messageStr);
            NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
            [mediaDict setValue:@1 forKey:@"mediaType"];
            NSString *srt = [messageStanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
            
            NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:srt error:nil] ;
            NSArray *itemElements = [xml elementsForName: @"body"];
            
            for (NSXMLElement *element in itemElements) {
                if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                    
                    NSString *strImg = [element stringValue];
                    imgThumb = [strImg decodeBase64ToImage];
                    [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                    
                } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                    
                    imgUrl = [element stringValue];
                    [mediaDict setValue:imgUrl forKey:@"mediaServerPath"];
                }
            }
            
            if (imgThumb == nil) {
                dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                                KEY_MESSAGE     :  messageBody,
                                KEY_SENDER_NAME  :  senderName,
                                KEY_TIME    :  [messageDate composeMessageDate],
                                KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                                KEY_GROUP_NAME : groupJId,
                                KEY_TIME_STAMP : timeStamp
                                };
            } else {
                dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                                KEY_MESSAGE     :  messageBody,
                                KEY_SENDER_NAME  :  senderName,
                                KEY_TIME    :  [messageDate composeMessageDate],
                                KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                                KEY_THUMB_IMAGE    :  imgThumb,
                                KEY_IMAGE_URL    :  imgUrl,
                                KEY_GROUP_NAME : groupJId,
                                KEY_TIME_STAMP : timeStamp
                                };
            }
            
        } else {
            dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                            KEY_MESSAGE     :  messageBody,
                            KEY_SENDER_NAME  :  senderName,
                            KEY_TIME    :  [messageDate composeMessageDate],
                            KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                            KEY_GROUP_NAME : groupJId,
                            KEY_STATUS : [NSNumber numberWithInteger:messageStatus],
                            KEY_MSG_STANZA : messageStanza,
                            KEY_TIME_STAMP : timeStamp
                            };
        }
        
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicMsg];
        [arrMsg addObject:mDic];
    }
    
    
    NSArray *arrLocalHistory = [DATABASEMANAGER getPendingMessagesOfSender:[self getMyJid] andReciver:groupJid ];
    for (NSDictionary *obj in arrLocalHistory) {
        
        UIImage *imgThumb = [obj[@"msg"] decodeBase64ToImage];
        
        
        BOOL msgProcessState = [[RequestQueue mainQueue] isRequestInProgressForId:obj[@"msgId"]];
        NSNumber *num = [NSNumber numberWithBool:msgProcessState];
        NSDictionary *dicMsg = @{   KEY_MESSAGE         :  obj[@"msg"],
                                    KEY_SENDER_NAME     :  [obj[@"senderName"] removeHostName],
                                    KEY_TIME            :  obj[@"timeStamp"],
                                    KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:MESSAGE_IMAGE],
                                    KEY_THUMB_IMAGE     :  imgThumb,
                                    KEY_IMAGE_URL       :  obj[@"imagePath"],
                                    KEY_PENDING_MSG_ID    :  obj[@"msgId"],
                                    KEY_IS_MSG_UPLOAD_IN_PROGRESS    :  num
                                    };
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicMsg];
        
        [arrMsg addObject:mDic];
    }
    
    if (arrLocalHistory.count > 0) {
        NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:KEY_TIME ascending:YES];
        NSArray *brrMsg = [arrMsg sortedArrayUsingDescriptors:@[descriptor]];
        [arrMsg removeAllObjects];
        [arrMsg addObjectsFromArray:brrMsg];
    }
    return arrMsg;
}

- (NSArray *)loadChatHistoryWithUserName:(BasicType *)buddy min:(NSInteger)min max:(NSInteger)max {
    
    NSString *userJid = [buddy.accountName addHostName];
    NSArray *messages = [DATABASEMANAGER getMessagesOfUser:userJid loggedinUser:[self getMyJid] min:min max:max ];
    
    NSMutableArray *arrMsg = [NSMutableArray array];
    
    for (NSDictionary *message in messages) {
        
        NSString *messageBody = message[@"message"];
        if (messageBody == nil) continue;
        
        NSString *packetId = message[@"packetId"];
        NSString *bareJId = message[@"bareJId"];
        NSString *streamBareJId = message[@"streamBareJId"];
        BOOL isFromMe = [message[@"isFromMe"] boolValue];
        NSString *messageStanza = message[@"messageStanza"];
        NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:[message[@"messageDate"] floatValue]];
        int messageType = [message[@"messageType"] intValue];
        NSInteger messageStatus = [message[@"messageStatus"] integerValue];
        NSString *timeStamp = message[@"messageDate"];
        
        NSString *senderName = @"";
        NSString *displayName = @"";
        if (isFromMe) {
            senderName = [streamBareJId removeHostName];
            displayName = [streamBareJId removeHostName];
        } else {
            senderName = [bareJId removeHostName];
            displayName = buddy.displayName;
        }
        
        NSDictionary * dicMsg = nil;
        NSString *imgUrl = @"";
        UIImage *imgThumb = nil;
        
        if ([messageBody isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
            
            NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
            [mediaDict setValue:@1 forKey:@"mediaType"];
            
            NSString *srt = [messageStanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
            
            NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:srt error:nil] ;
            NSArray *itemElements = [xml elementsForName: @"body"];
            
            for (NSXMLElement *element in itemElements) {
                if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                    
                    NSString *strImg = [element stringValue];
                    imgThumb = [strImg decodeBase64ToImage];
                    [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                    
                } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                    
                    imgUrl = [element stringValue];
                    [mediaDict setValue:imgUrl forKey:@"mediaThumbPath"];
                }
            }
            if (imgThumb == nil) {
                dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                                KEY_MESSAGE     :  messageBody,
                                KEY_SENDER_NAME  :  senderName,
                                KEY_TIME    :  [messageDate composeMessageDate],
                                KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                                KEY_DISPLAYNAME : displayName,
                                KEY_TIME_STAMP : timeStamp
                                };
            } else {
                dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                                KEY_MESSAGE     :  messageBody,
                                KEY_SENDER_NAME  :  senderName,
                                KEY_TIME    :  [messageDate composeMessageDate],
                                KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                                KEY_THUMB_IMAGE    :  imgThumb,
                                KEY_IMAGE_URL    :  imgUrl,
                                KEY_DISPLAYNAME : displayName,
                                KEY_TIME_STAMP : timeStamp
                                };
            }
            
        } else {
            dicMsg =   @{   KEY_PACKET_ID   :   packetId,
                            KEY_MESSAGE     :  messageBody,
                            KEY_SENDER_NAME  :  senderName,
                            KEY_TIME    :  [messageDate composeMessageDate],
                            KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:messageType],
                            KEY_STATUS : [NSNumber numberWithInteger:messageStatus],
                            KEY_MSG_STANZA : messageStanza,
                            KEY_DISPLAYNAME : displayName,
                            KEY_TIME_STAMP : timeStamp
                            };
        }
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicMsg];
        [arrMsg addObject:mDic];
    }
    
    
    NSArray *arrLocalHistory = [DATABASEMANAGER getPendingMessagesOfSender:[self getMyJid] andReciver:userJid ];
    for (NSDictionary *obj in arrLocalHistory) {
        
        UIImage *imgThumb = [obj[@"msg"] decodeBase64ToImage];
        
        
        BOOL msgProcessState = [[RequestQueue mainQueue] isRequestInProgressForId:obj[@"msgId"]];
        NSNumber *num = [NSNumber numberWithBool:msgProcessState];
        NSDictionary *dicMsg = @{   KEY_MESSAGE     :  obj[@"msg"],
                                    KEY_SENDER_NAME  :  [obj[@"senderName"] removeHostName],
                                    KEY_TIME    :  obj[@"timeStamp"],
                                    KEY_MESSAGE_TYPE    :  [NSNumber numberWithInt:MESSAGE_IMAGE],
                                    KEY_THUMB_IMAGE    :  imgThumb,
                                    KEY_IMAGE_URL    :  obj[@"imagePath"],
                                    KEY_PENDING_MSG_ID    :  obj[@"msgId"],
                                    KEY_IS_MSG_UPLOAD_IN_PROGRESS    :  num
                                    };
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicMsg];
        
        [arrMsg addObject:mDic];
    }
    
    if (arrLocalHistory.count > 0) {
        
        NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:KEY_TIME ascending:YES];
        NSArray *brrMsg = [arrMsg sortedArrayUsingDescriptors:@[descriptor]];
        [arrMsg removeAllObjects];
        [arrMsg addObjectsFromArray:brrMsg];
    }
    
    return arrMsg;
}

- (void)processPendingMessageHistory {
    
    NSArray *messages = [DATABASEMANAGER getPendingMessagesOfUser:[self getMyJid] ];
    
    for (NSDictionary *message in messages) {
        
        NSString *messageBody = message[@"message"];
        
        if (![messageBody isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]){
            
            BOOL isGroupMsg = [message[@"isGroupMessage"] boolValue];
            if(isGroupMsg){
                NSString *groupJId = message[@"groupJId"];
                NSString *msgStanza = message[@"messageStanza"];
                NSDictionary *MsgDic = [[XMLDictionaryParser sharedInstance] dictionaryWithString:msgStanza];
                [self sendPendingMessage:MsgDic toGroup:groupJId];
                
            }else{
                
                NSString *bareJId = message[@"bareJId"];
                NSString *msgStanza = message[@"messageStanza"];
                NSDictionary *MsgDic = [[XMLDictionaryParser sharedInstance] dictionaryWithString:msgStanza];
                [self sendPendingMessage:MsgDic ToUser:bareJId];
            }
            
        }
    }
    
}
- (void)getPendingMessagesForUser:(NSString *)userId {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSString *predicateFrmt = @"reciverName == %@ AND senderName == %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFrmt, userId, [self getMyJid]];
    request.predicate = predicate;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    for (NSManagedObject *obj in messages) {
        NSLog(@"%@",obj);
    }
}

- (void)savePendingMessage {
    
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_PendingMessage_CoreDataObject" inManagedObjectContext:moc];
    
    // Initialize Record
    XMPPMessageArchiving_PendingMessage_CoreDataObject *pendingMsgRecord = [[XMPPMessageArchiving_PendingMessage_CoreDataObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    pendingMsgRecord.msgId = @"1";
    pendingMsgRecord.reciverName = @"aaaaa";
    pendingMsgRecord.senderName = @"nnnn";
    pendingMsgRecord.timestamp = [NSDate date];
    NSError *error = nil;
    
    if ([moc save:&error]) {
    } else {
        
        if (error) {
            NSLog(@"%@",error.description);
        }
    }
}

#pragma mark XMPP Delegates

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    
    NSLog(@"CONNECTTED");
    NSError *error = nil;
    if (self.requestType == kTagXmppRequestLogin) {
        
        [[self xmppStream] authenticateWithPassword:self.password error:&error];
    } else if (self.requestType == kTagXmppRequestRegister) {
        
        if (self.xmppStream.supportsInBandRegistration) {
            
            if (![self.xmppStream registerWithElements:self.registerElements error:&error]) {
                NSLog(@"Oops, I forgot something: %@", error);
            } else {
                NSLog(@"No Error");
            }
        }
    }else{
        // in case of internet connection reconnect
        [[self xmppStream] authenticateWithPassword:self.password error:&error];
    }
    
    self.requestType = kTagXmppRequestNone;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
    NSLog(@"ERROR : %@",[error description]);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"DISCONNECT");
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    [self hideLoader];
    
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(registerResult:withError:)]) {
        [self.multicastDelegate registerResult:YES withError:nil];
    }
    self.registerElements = nil;
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error {
    [self hideLoader];
    
    DDXMLElement *errorXML = [error elementForName:@"error"];
    NSString *errorCode  = [[errorXML attributeForName:@"code"] stringValue];
    
    NSString *regError = [NSString stringWithFormat:@"ERROR :- %@",error.description];
    
    if([errorCode isEqualToString:@"409"]){
        
        regError = @"Username Already Exists!";
    }
    
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(registerResult:withError:)]) {
        [self.multicastDelegate registerResult:NO withError:regError];
    }
    self.registerElements = nil;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    // authentication successful
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(loginResult:)]) {
        [self.multicastDelegate loginResult:YES];
        [self goOnline];
        [self loadBuddyListFromDatabase:YES];
        [self loadGroupListFromDatabase:YES];
        [self processPendingMessageHistory];
        self.sendPresenceTimer = [NSTimer scheduledTimerWithTimeInterval:10 target: self selector: @selector(goOnline) userInfo: nil repeats: YES];
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
    
    NSLog(@"error %@", error);
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(loginResult:)]) {
        [self.multicastDelegate loginResult:NO];
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    
    NSLog(@"%s %@", __PRETTY_FUNCTION__, message);
    
    NSString *idVal = [[message attributeForName:@"id"] stringValue];
    if ([[message type] isEqualToString:@"chat"]) {
        [DATABASEMANAGER updateMessageDeliveryStatusForUser:1 idVal:idVal forUser:self.xmppStream.myJID.bare sender:[message toStr] ];
    } else if ([[message type] isEqualToString:@"groupchat"]) {
        [DATABASEMANAGER updateMessageDeliveryStatusForGroup:1 idVal:idVal forUser:self.xmppStream.myJID.bare sender:[message toStr] ];
        
        if ([[message body] rangeOfString:CODE_FOR_MEMBER_REMOVED].length > 0) {
            
            NSArray *splitMessage = [[message body] componentsSeparatedByString:@"##"];
            if ([[splitMessage[1] removeHostName] isEqualToString:GETUSERID]) {
                
                XMPPJID *roomJID = [XMPPJID jidWithString:[message toStr]];
                self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJID];
                [self.xmppRoom activate:self.xmppStream];
                [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
                [self.xmppRoom leaveRoom:roomJID];
            }
        }
    } else if ([[message type] isEqualToString:@"error"] && [message elementForName:@"received" xmlns:@"urn:xmpp:receipts"]) {
        [DATABASEMANAGER updateMessageDeliveryStatusForUser:0 idVal:idVal forUser:self.xmppStream.myJID.bare sender:[message toStr] ];
    }
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    
    NSLog(@"%s %@ ERROR: = %@", __PRETTY_FUNCTION__, message, error);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    
    NSLog(@"message = %@", message);
    [self goOnline];
    //Handle Group Chat Messages
    NSString *chatType = [message type];
    
    if ([chatType isEqualToString:@"error"]) {
        return;
    }
    if ([chatType isEqualToString:@"groupchat"]) {
        
        NSString *idVal = [[message attributeForName:@"id"] stringValue];
        NSString *groupName = [[message fromStr] removeLastPathComponent];
        NSString *fromUser = [[[message fromStr] lastPathComponent] addHostName];
        NSString *toUser = [message toStr];
        NSString *currentUser = [self getMyJid];
        NSString *currentUserWithResource = [currentUser stringByAppendingPathComponent:[[self.xmppStream myJID] resource]];
        NSString *messageBody = message.body;
        NSString *fromUserWithResource = nil;
        NSArray *itemElements = [message elementsForName: @"body"];
        for (NSXMLElement *element in itemElements) {
            if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"resource"]) {
                fromUserWithResource = [fromUser stringByAppendingPathComponent:[element stringValue]];
            }
        }
        
        NSDictionary *dict = [DATABASEMANAGER getMessageWithMessageId:idVal forGroup:groupName member:[fromUser removeLastPathComponent] toUser:[toUser removeLastPathComponent] ];
        if (dict && dict.count > 0) {
            NSLog(@"BHAGOOOO");
            return;
        }
        
        if ([fromUserWithResource isEqualToString:currentUserWithResource]) {
            
            if (([messageBody rangeOfString:CODE_FOR_MEMBER_ADDED].length > 0) || ([messageBody rangeOfString:CODE_FOR_CHANGE_GROUPNAME].length > 0) || ([messageBody rangeOfString:CODE_FOR_MEMBER_REMOVED].length > 0)|| ([messageBody rangeOfString:CODE_FOR_CHANGE_GROUPPHOTO].length > 0))
            {
                
            } else {
                return;
            }
        }
        
        NSString *msg = [messageBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (msg != nil) {
            
            NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
            [messageDict setValue:msg forKey:@"message"];
            [messageDict setValue:idVal forKey:@"packetId"];
            [messageDict setValue:[message description] forKey:@"messageStanza"];
            [messageDict setValue:@1 forKey:@"isGroupMessage"];
            
            NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
            [m setObject:msg forKey:KEY_MESSAGE];
            [m setObject:fromUser forKey:KEY_SENDER_NAME];
            [m setObject:[groupName removeHostName] forKey:KEY_GROUP_NAME];
            [m setObject:[NSNumber numberWithInt:MESSAGE_TEXT] forKey:KEY_MESSAGE_TYPE];
            [m setObject:[toUser removeHostName] forKey:KEY_RECEIVER_NAME];
            [m setObject:[NSNumber numberWithBool:[[fromUser removeHostName] isEqualToString:GETUSERID]] forKey:KEY_ISMESSAGEINCOMING];
            [messageDict setValue:[m objectForKey:KEY_ISMESSAGEINCOMING] forKey:@"isFromMe"];
            [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
            [messageDict setValue:groupName forKey:@"groupJId"];
            
            if ([[fromUser removeHostName] isEqualToString:GETUSERID]) {
                [messageDict setValue:@1 forKey:@"messageStatus"];
                [messageDict setValue:fromUser forKey:@"streamBareJId"];
                [messageDict setValue:[toUser removeLastPathComponent] forKey:@"bareJId"];
            } else {
                [messageDict setValue:[NSNumber numberWithInt:-1] forKey:@"messageStatus"];
                [messageDict setValue:[toUser removeLastPathComponent] forKey:@"streamBareJId"];
                [messageDict setValue:fromUser forKey:@"bareJId"];
            }
            if ([msg isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
                
                NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
                [mediaDict setValue:@1 forKey:@"mediaType"];
                
                NSArray *itemElements = [message elementsForName: @"body"];
                
                for (NSXMLElement *element in itemElements) {
                    if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                        
                        NSString *strImg = [element stringValue];
                        UIImage *imgThumb = [strImg decodeBase64ToImage];
                        [m setObject:imgThumb forKey:KEY_THUMB_IMAGE];
                        [m setObject:[NSNumber numberWithInt:MESSAGE_IMAGE] forKey:KEY_MESSAGE_TYPE];
                        
                        [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                        
                    } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                        
                        NSString *imgUrl = [element stringValue];
                        [m setObject:imgUrl forKey:KEY_IMAGE_URL];
                        [mediaDict setValue:imgUrl forKey:@"mediaServerPath"];
                        
                    }
                }
                
                NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
                if (mediaId>0)
                    [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
                
                [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
                
            } else if ([msg rangeOfString:CODE_FOR_MEMBER_ADDED].length > 0)
            {
                if(![CHATMANAGER isConnected])   // in case open fire is not connected
                    return;
                
                //service call for getting group members
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"group_id" : [groupName removeHostName],
                                                                                              @"action" : @"get_group_detail"}];
                [[RequestHandler sharedHandler] sendRequestWithParams:params handler:^(BOOL success, NSDictionary *responseData) {
                    
                    NSLog(@"success = %d && responseData = %@", success, responseData);
                    
                    if (success && [responseData[@"status"] boolValue]) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", params[@"group_id"]];
                        NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
                        Group *group = (Group *)results[0];
                        
                        if(group){
                            
                            group.groupUsers = [NSMutableArray arrayWithArray:responseData[@"members"]];
                            
                            for (NSDictionary *d in group.groupUsers) {
                                NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[group.accountName addGroupHostName] forUser:[self.xmppStream myJID].bare member:d[@"name"] ];
                                if (dict == nil || dict.count == 0) {
                                    [DATABASEMANAGER insertUserGroupMembers:@[d] group:[group.accountName addGroupHostName] user:[self.xmppStream myJID].bare ];
                                } else {
                                    [dict setValue:@0 forKey:@"isDeleted"];
                                    [DATABASEMANAGER updateGroupMember:dict ];
                                }
                            }
                            
                            group.groupUsers = [DATABASEMANAGER getGroupMembers:[group.accountName addGroupHostName] forUser:[self getMyJid] ];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateGroupListMembers object:nil userInfo:@{@"members" : group.groupUsers}];
                        }
                        
                    }
                }];
            } else if ([msg rangeOfString:CODE_FOR_MEMBER_REMOVED].length > 0) {
                
                NSArray *splitMessage = [msg componentsSeparatedByString:@"##"];
                if ([[splitMessage[1] removeHostName] isEqualToString:GETUSERID]) {
                    
                    XMPPJID *roomJID = [XMPPJID jidWithString:groupName];
                    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJID];
                    [self.xmppRoom activate:self.xmppStream];
                    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
                    [self.xmppRoom leaveRoom:roomJID];
                }
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [groupName removeHostName]];
                NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
                Group *group;
                if (results.count>0)
                    group= (Group *)results[0];
                
                if(group){
                    
                    NSMutableDictionary *dict = [DATABASEMANAGER getGroupMember:[group.accountName addGroupHostName] forUser:currentUser member:splitMessage[1] ];
                    [dict setValue:@1 forKey:@"isDeleted"];
                    [DATABASEMANAGER updateGroupMember:dict ];
                    
                    NSMutableDictionary *dictG = [DATABASEMANAGER getGroup:[group.accountName addGroupHostName] forUser:self.xmppStream.myJID.bare ];
                    [dictG setValue:@1 forKey:@"isDeleted"];
                    [DATABASEMANAGER updateGroup:dictG ];
                    
                    for (int loopIndex = 0; loopIndex < group.groupUsers.count; loopIndex++) {
                        
                        NSDictionary *userInfo = group.groupUsers[loopIndex];
                        if ([userInfo[@"memberJId"] isEqualToString:splitMessage[1]]) {
                            [group.groupUsers removeObjectAtIndex:loopIndex];
                            break;
                        }
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateGroupListMembers object:nil userInfo:@{@"members" : group.groupUsers}];
                }
                
            } else if ([msg rangeOfString:CODE_FOR_CHANGE_GROUPNAME].length > 0) {
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [groupName removeHostName]];
                NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
                Group *group = nil;
                if (results.count > 0){
                    group= (Group *)results[0];
                    
                    NSString *newGroupName = [msg stringByReplacingOccurrencesOfString:CODE_FOR_CHANGE_GROUPNAME withString:@""];
                    group.displayName = newGroupName;
                    group.recentMessage = msg;
                    
                    NSMutableDictionary *dict = [DATABASEMANAGER getGroup:[group.accountName addGroupHostName] forUser:currentUser ];
                    [dict setValue:(group.displayName == nil ? @"" : group.displayName) forKey:@"displayName"];
                    [DATABASEMANAGER updateGroup:dict ];
                }
            } else if ([msg rangeOfString:CODE_FOR_CHANGE_GROUPPHOTO].length > 0) {
                
            }
            
            NSXMLElement *queryElement = [message elementForName: @"delay"];
            if (queryElement != nil) {
                NSString *d = [[queryElement attributeForName:@"stamp"] stringValue];
                NSString *strTime = [[NSDate composeDateFromSring:d] composeMessageDate];
                [m setObject:strTime forKey:KEY_TIME];
                [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate composeDateFromSring:d] timeIntervalSince1970]] forKey:@"messageDate"];
            } else {
                NSString *strTime = [[NSDate date] composeMessageDate];
                [m setObject:strTime forKey:KEY_TIME];
                [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
            }
            
            [DATABASEMANAGER insertMessage:messageDict ];
            
            NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
            [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
            [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
            [recentMessageDict setValue:[self recentMessageForMessage:messageDict] forKey:@"recentMessage"];
            [recentMessageDict setValue:messageDict[@"groupJId"] forKey:@"bareJId"];
            [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
            [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
            
            if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(newMessageReceived:withBuddyType:)]) {
                [self.multicastDelegate newMessageReceived:m withBuddyType:YES];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
            
            if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && !([m[KEY_MESSAGE] rangeOfString:CODE_FOR_MEMBER_ADDED].length > 0) && !([m[KEY_MESSAGE] rangeOfString:CODE_FOR_MEMBER_REMOVED].length > 0) && !([m[KEY_MESSAGE] rangeOfString:CODE_FOR_CHANGE_GROUPNAME].length > 0) && !([m[KEY_MESSAGE] rangeOfString:CODE_FOR_CHANGE_GROUPPHOTO].length > 0)) {
                
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.fireDate = [NSDate date];
                localNotification.alertAction = @"Reply";
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [groupName removeHostName]];
                NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
                if (results.count > 0) {
                    Group *group = (Group *)results[0];
                    localNotification.alertBody = [NSString stringWithFormat:@"%@ has a new message", [group.displayName removeHostName]];
                } else {
                    
                    NSDictionary *dic = [DATABASEMANAGER getContact:[fromUser addHostName] forUser:[GETUSERID addHostName] ];
                    NSString *senderName = [dic valueForKey:@"displayName"];
                    if(!senderName)
                        senderName = fromUser;
                    localNotification.alertBody = [NSString stringWithFormat:@"%@ sent you a message", [dic valueForKey:@"displayName"]];
                }
                //                localNotification.userInfo = @{@"sender" : [groupName removeHostName]};
                localNotification.userInfo = @{@"sender" :groupName, @"isGroup":@YES};
                //[UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }
        return;
    }
    
    //Handle Group invitations/Decline
    NSXMLElement *xElement = [message elementForName: @"x" xmlns: XMPPMUCUserNamespace];
    if (xElement) {
        [self handleGroupInvitations:message];
        return;
    }
    
    if ([[message type] isEqualToString:@"chat"] && [message elementForName:@"received" xmlns:@"urn:xmpp:receipts"]) {
        
        NSString *idVal = [[[message elementForName:@"received"] attributeForName:@"id"] stringValue];
        [DATABASEMANAGER updateMessageDeliveryStatusForUser:2 idVal:idVal forUser:[[message toStr] removeLastPathComponent] sender:[[message fromStr] removeLastPathComponent] ];
        return;
    }
    
    // message received
    NSString *msg = [[[message elementForName:@"body"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (msg != nil) {
        
        NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
        NSString *idVal = [[message attributeForName:@"id"] stringValue];
        [messageDict setValue:msg forKey:@"message"];
        [messageDict setValue:idVal forKey:@"packetId"];
        [messageDict setValue:[message description] forKey:@"messageStanza"];
        [messageDict setValue:@0 forKey:@"isGroupMessage"];
        [messageDict setValue:@"" forKey:@"groupJId"];
        
        NSString *from = [[message attributeForName:@"from"] stringValue];
        from = [from removeHostName];
        
        NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
        [m setObject:msg forKey:KEY_MESSAGE];
        [m setObject:from forKey:KEY_SENDER_NAME];
        [m setObject:[[message toStr] removeHostName] forKey:KEY_RECEIVER_NAME];
        [m setObject:[NSNumber numberWithInt:MESSAGE_TEXT] forKey:KEY_MESSAGE_TYPE];
        [m setObject:[NSNumber numberWithBool:[from isEqualToString:GETUSERID]] forKey:KEY_ISMESSAGEINCOMING];
        
        [messageDict setValue:[m objectForKey:KEY_ISMESSAGEINCOMING] forKey:@"isFromMe"];
        
        if ([from isEqualToString:GETUSERID]) {
            [messageDict setValue:@2 forKey:@"messageStatus"];
            [messageDict setValue:[[message fromStr] removeLastPathComponent] forKey:@"streamBareJId"];
            [messageDict setValue:[[message toStr] removeLastPathComponent] forKey:@"bareJId"];
        } else {
            [messageDict setValue:[NSNumber numberWithInt:-1] forKey:@"messageStatus"];
            [messageDict setValue:[[message toStr] removeLastPathComponent] forKey:@"streamBareJId"];
            [messageDict setValue:[[message fromStr] removeLastPathComponent] forKey:@"bareJId"];
        }
        
        if ([msg isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
            NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
            [mediaDict setValue:@1 forKey:@"mediaType"];
            
            NSArray *itemElements = [message elementsForName: @"body"];
            
            for (NSXMLElement *element in itemElements) {
                if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                    
                    NSString *strImg = [element stringValue];
                    UIImage *imgThumb = [strImg decodeBase64ToImage];
                    [m setObject:imgThumb forKey:KEY_THUMB_IMAGE];
                    [m setObject:[NSNumber numberWithInt:MESSAGE_IMAGE] forKey:KEY_MESSAGE_TYPE];
                    [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                    
                } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                    
                    NSString *imgUrl = [element stringValue];
                    [m setObject:imgUrl forKey:KEY_IMAGE_URL];
                    [mediaDict setValue:imgUrl forKey:@"mediaServerPath"];
                    
                }
            }
            
            NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
            if (mediaId>0)
                [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
            
            [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
        } else {
            [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
        }
        
        NSXMLElement *queryElement = [message elementForName: @"delay"];
        if (queryElement != nil) {
            NSString *d = [[queryElement attributeForName:@"stamp"] stringValue];
            NSString *strTime = [[NSDate composeDateFromSring:d] composeMessageDate];
            [m setObject:strTime forKey:KEY_TIME];
            [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate composeDateFromSring:d] timeIntervalSince1970]] forKey:@"messageDate"];
        } else {
            NSString *strTime = [[NSDate date] composeMessageDate];
            [m setObject:strTime forKey:KEY_TIME];
            [messageDict setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"messageDate"];
        }
        
        [DATABASEMANAGER insertMessage:messageDict ];
        
        NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
        [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
        [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
        [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
        [recentMessageDict setValue:messageDict[@"bareJId"] forKey:@"bareJId"];
        [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
        [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
        
        
        if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(newMessageReceived:withBuddyType:)]) {
            [self.multicastDelegate newMessageReceived:m withBuddyType:NO];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
        
        if (![[m objectForKey:KEY_ISMESSAGEINCOMING] boolValue] && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.fireDate = [NSDate date];
            localNotification.alertAction = @"Reply";
            NSDictionary *dic = [DATABASEMANAGER getContact:[m[KEY_SENDER_NAME] addHostName] forUser:[GETUSERID addHostName] ];
            
            localNotification.alertBody = [NSString stringWithFormat:@"%@ sent you a message", [dic valueForKey:@"displayName"]];
            localNotification.userInfo = @{@"sender" : [m[KEY_SENDER_NAME] addHostName]};
            //[UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    
    // a buddy went offline/online
    NSString *presenceType = [presence type]; // online/offline
    NSString *myUsername = [[sender myJID] user];
    NSString *presenceFromUser = [[presence from] user];
    
    [self updateBuddyListWithReceivePresenceType:presenceType myUsername:myUsername presenceFromUser:presenceFromUser];
    
    NSLog(@"presenceType = %@, myUsername = %@, presenceFromUser = %@", presenceType, myUsername, presenceFromUser);
    
    if (![presenceFromUser isEqualToString:myUsername]) {
        
        if ([presenceType isEqualToString:@"available"]) {
            
            if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(newBuddyOnline:)]) {
                [self.multicastDelegate newBuddyOnline:[NSString stringWithFormat:@"%@", presenceFromUser]];
            }
        } else if ([presenceType isEqualToString:@"unavailable"]) {
            
            if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(buddyWentOffline:)]) {
                [self.multicastDelegate buddyWentOffline:[NSString stringWithFormat:@"%@", presenceFromUser]];
            }
        } else if ([presenceType isEqualToString:@"subscribe"]) {
            
            //            if (![[NSUserDefaults standardUserDefaults] boolForKey:presenceFromUser]) {
            //
            //                dispatch_async(dispatch_get_main_queue(), ^(void) {
            //
            //                    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"New request From:" message:presenceFromUser delegate:self cancelButtonTitle:@"Deny" otherButtonTitles:@"Accept", nil];
            //                    alert.dataDetails = presence.from;
            //                    [alert show];
            //                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:presenceFromUser];
            //                    [[NSUserDefaults standardUserDefaults] synchronize];
            //                });
            //            }
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
        } else if ([presenceType isEqualToString:@"unsubscribe"]) {
            
            [self.xmppRoster unsubscribePresenceFromUser:[presence from]];
        } else if ([presenceType isEqualToString:@"subscribed"]) {
            
            //NSLog(@"subscribed");
        } else if ([presenceType isEqualToString:@"unsubscribed"]) {
            
            if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(removedBuddy:)]) {
                [self.multicastDelegate removedBuddy:[NSString stringWithFormat:@"%@", presenceFromUser]];
            }
            
            BasicType *obj = [[BasicType alloc] init];
            obj.accountName = [NSString stringWithFormat:@"%@", [presenceFromUser removeHostName]];
            [self updateBuddyListXmpp:@[obj] needRemove:YES];
            
            //NSLog(@"unsubscribed");
        }
    }
}

- (NSString *)recentMessageForMessage:(NSDictionary*)dicMsg{
    
    NSString *finalMessage;
    NSString *sender_name   =   @"";
    
    if ([[[dicMsg valueForKey:@"bareJId"] addHostName] isEqualToString:[GETUSERID addHostName]])
    {
        sender_name =   @"You";
    }else
    {
        sender_name = [dicMsg valueForKey:@"bareJId"];
        NSDictionary *dic = [DATABASEMANAGER getContact:[[dicMsg valueForKey:@"bareJId"] addHostName] forUser:[GETUSERID addHostName] ];
        if(dic)
            sender_name =   [dic valueForKey:@"displayName"];
    }
    
    if ([[dicMsg valueForKey:@"message"] rangeOfString:CODE_FOR_MEMBER_ADDED].length > 0)
    {
        NSString *member_account_name = [[dicMsg valueForKey:@"message"] stringByReplacingOccurrencesOfString:CODE_FOR_MEMBER_ADDED withString:@""];
        NSDictionary *dic = [DATABASEMANAGER getContact:member_account_name forUser:[GETUSERID addHostName] ];
        NSString *memberName = [dic[@"contactJId"] removeHostName];
        if(dic)
            memberName = [dic valueForKey:@"displayName"];
        else{
            memberName = [member_account_name removeHostName];
        }
        if ([[memberName removeHostName] isEqualToString:GETUSERID])
        {
            finalMessage = [NSString stringWithFormat:@"You added new member: %@", [memberName removeHostName]];
        } else
        {
            finalMessage = [NSString stringWithFormat:@"%@ added %@", sender_name, memberName];
        }
    }
    
    else if ([[dicMsg valueForKey:@"message"] rangeOfString:CODE_FOR_MEMBER_REMOVED].length > 0)
    {
        NSArray *splitMessage = [[dicMsg valueForKey:@"message"] componentsSeparatedByString:@"##"];
        
        NSDictionary *dic = [DATABASEMANAGER getContact:splitMessage[1] forUser:[GETUSERID addHostName] ];
        NSString *memberName = [dic[@"contactJId"] removeHostName];
        if(dic)
            memberName = [dic valueForKey:@"displayName"];
        else{
            memberName = [splitMessage[1] removeHostName];
        }
        
        if ([splitMessage[2] isEqualToString:@"left"]) {
            if ([[splitMessage[1] removeHostName] isEqualToString:GETUSERID]) {
                
                finalMessage = [NSString stringWithFormat:@"You Left group"];
            } else
            {
                finalMessage = [NSString stringWithFormat:@"%@ Left group", memberName];
            }
        } else {
            
            if ([[splitMessage[1] removeHostName] isEqualToString:GETUSERID]) {
                
                finalMessage= [NSString stringWithFormat:@"%@ removed you", sender_name];
            } else
            {
                finalMessage = [NSString stringWithFormat:@"%@ removed %@", sender_name, memberName];
            }
        }
    }
    
    else if ([[dicMsg valueForKey:@"message"] rangeOfString:CODE_FOR_CHANGE_GROUPNAME].length > 0)
    {
        NSString *newGroupName = [[dicMsg valueForKey:@"message"] stringByReplacingOccurrencesOfString:CODE_FOR_CHANGE_GROUPNAME withString:@""];
        
        finalMessage = [NSString stringWithFormat:@"%@ changed group name: %@",sender_name, newGroupName];
        
    }
    
    else if ([[dicMsg valueForKey:@"message"] rangeOfString:CODE_FOR_CHANGE_GROUPPHOTO].length > 0)
    {
        finalMessage = [NSString stringWithFormat:@"%@ changed group photo", sender_name];
    }
    
    else
    {
        finalMessage = [dicMsg valueForKey:@"message"];
        
    }
    
    
    return finalMessage;
}

- (void)updateBuddyListWithReceivePresenceType:(NSString *)presenceType myUsername:(NSString *)myUsername presenceFromUser:(NSString *)presenceFromUser {
    
    for (BasicType *objBuddy in self.buddyList) {
        
        if (objBuddy.type == kBaseTypeBuddy) {
            
            Buddy *objBuddyType= (Buddy*)objBuddy;
            if ([objBuddyType.accountName isEqualToString:presenceFromUser]) {
                if ([presenceType isEqualToString:@"available"]) {
                    objBuddyType.status = kBuddyStatusAvailable;
                }else{
                    objBuddyType.status = kBuddyStatusOffline;
                }
            }
        }
    }
    
    NSDictionary* infoDict = [NSDictionary dictionaryWithObject:self.buddyList forKey:@"buddyList"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyPresence object:nil userInfo:infoDict];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
    
    NSLog(@"print iq=====%@",[iq elementID]);
    //    if ([[iq elementID] isEqualToString:@"pk1"]) {
    //        NSLog(@"message iq=====%@",iq);
    //
    //        // received chat listing
    //        NSArray *chats = [[iq elementForName:@"list"] elementsForName:@"chat"];
    //
    //        for (NSXMLElement *e in chats) {
    //
    //            NSString *userId = [[e attributeForName:@"with"] stringValue];
    //            if(![userId containsString:@"conference"]){
    //
    //                NSXMLElement *iq1 = [NSXMLElement elementWithName:@"iq"];
    //                [iq1 addAttributeWithName:@"type" stringValue:@"get"];
    //                [iq1 addAttributeWithName:@"id" stringValue:@"pk1"];
    //
    //                NSXMLElement *retrieve = [NSXMLElement elementWithName:@"retrieve" xmlns:@"urn:xmpp:archive"];
    //                [retrieve addAttributeWithName:@"with" stringValue:[[e attributeForName:@"with"] stringValue]];
    //                [retrieve addAttributeWithName:@"start" stringValue:[[e attributeForName:@"start"] stringValue]];
    //
    //
    //                NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
    //                NSXMLElement *max = [NSXMLElement elementWithName:@"max" stringValue:@"100"];
    //
    //                [iq1 addChild:retrieve];
    //                [retrieve addChild:set];
    //                [set addChild:max];
    //                [[self xmppStream] sendElement:iq1];
    //            }
    //
    //        }
    //    }
    //
    //    // retrieving chat conversation for one-one only
    //    NSLog(@"message iq=====%@",iq);
    //    NSXMLElement *chatSet = [[iq elementsForName:@"chat"] lastObject];
    //
    //    if(chatSet){
    //
    //        BOOL isGroup;
    //
    //        NSString *userId = [[chatSet attributeForName:@"with"] stringValue];
    //
    //        if([userId containsString:@"conference"]){
    //            isGroup = YES;
    //        }else{
    //            isGroup = NO;
    //        }
    //
    //        if(!isGroup){
    //
    //            NSString *time = [[chatSet attributeForName:@"start"] stringValue];
    //            NSArray *sentMessages = [chatSet elementsForName:@"to"];
    //            NSArray *receivedMsgs = [chatSet elementsForName:@"from"];
    //            NSLog(@"history item =====%@",chatSet);
    //        }
    //
    //    }
    
    
    //Fetch friends List
    //    NSXMLElement *queryElement = [iq elementForName: @"query" xmlns: @"jabber:iq:roster"];
    //    if (queryElement) {
    //        NSArray *itemElements = [queryElement elementsForName: @"item"];
    //        //NSLog(@"didReceiveIQ, = %@", itemElements);
    //
    //        NSMutableArray *buddies = [[NSMutableArray alloc] init];
    //        NSMutableArray *tempBuddies = [[NSMutableArray alloc] init];
    //        for (int i = 0; i < [itemElements count]; i++) {
    //
    //            if ([[[itemElements[i] attributeForName:@"subscription"] stringValue] isEqualToString:@"none"]) {
    //                continue;
    //            }
    //
    //            Buddy *objBuddy = [[Buddy alloc] init];
    //            objBuddy.type = kBaseTypeBuddy;
    //            objBuddy.displayName = [[[itemElements[i] attributeForName:@"name"] stringValue] removeHostName];
    //            objBuddy.accountName = [[[itemElements[i] attributeForName:@"jid"] stringValue] removeHostName];
    //            objBuddy.subscriptionType = [[itemElements[i] attributeForName:@"subscription"] stringValue];
    //            objBuddy.user = [XMPPJID jidWithString:[[itemElements[i] attributeForName:@"jid"] stringValue]];
    //            //            objBuddy.profileImageURL = [self getAvatarForUser:objBuddy.accountName];
    //            [buddies addObject:objBuddy];
    //
    //            [tempBuddies addObject:@{@"displayName" : (objBuddy.displayName == nil ? @"" : objBuddy.displayName),
    //                                     @"avatarPath" : @"",
    //                                     @"contactJId" : [[itemElements[i] attributeForName:@"jid"] stringValue],
    //                                     @"userJId" : [self getMyJid],
    //                                     @"status" : @"",
    //                                     @"subscriptionType" : [[itemElements[i] attributeForName:@"subscription"] stringValue],
    //                                     @"isDeleted" : @0}];
    //        }
    //        if (buddies.count > 0) {
    //            [DATABASEMANAGER insertContacts:tempBuddies];
    //            [self updateBuddyListXmpp:buddies needRemove:NO];
    //        }
    //    }
    
    return NO;
}

- (void)retrieveChatHistoryFromXMPPServer{
    
    NSMutableArray *myContacts =  [DATABASEMANAGER getAllContactsForUser:[self getMyJid] ];
    
    for (NSDictionary *buddy in myContacts) {
        
        NSXMLElement *iq1 = [NSXMLElement elementWithName:@"iq"];
        [iq1 addAttributeWithName:@"type" stringValue:@"get"];
        [iq1 addAttributeWithName:@"id" stringValue:@"pk1"];
        
        NSXMLElement *retrieve = [NSXMLElement elementWithName:@"list" xmlns:@"urn:xmpp:archive"];
        [retrieve addAttributeWithName:@"with" stringValue:[buddy objectForKey:@"contactJId"]];
        //      [retrieve addAttributeWithName:@"start" stringValue:@"2016-12-09T08:55:03Z"];
        
        NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
        NSXMLElement *max = [NSXMLElement elementWithName:@"max" stringValue:@"100"];
        
        [iq1 addChild:retrieve];
        [retrieve addChild:set];
        [set addChild:max];
        [[self xmppStream] sendElement:iq1];
    }
    
}


- (void)passwordChangeSuccessful:(XMPPRegistration *)sender{
    [self showLoader];
    [sender deactivate];
    [sender removeDelegate:self];
    sender = nil;
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(passwordChangeResult:withError:)]) {
        [self.multicastDelegate passwordChangeResult:YES withError:nil];
    }
}
- (void)passwordChangeFailed:(XMPPRegistration *)sender withError:(NSError* )error{
    [self hideLoader];
    [sender deactivate];
    [sender removeDelegate:self];
    sender = nil;
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(passwordChangeResult:withError:)]) {
        [self.multicastDelegate passwordChangeResult:NO withError:nil];
    }
}

#pragma mark XMPPROSTER Delegates

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
    
    //NSLog(@"didReceiveRosterItem = %@", item);
    NSString *subscription = [[item attributeForName:@"subscription"] stringValue];
    if ([subscription isEqualToString:@"remove"]) {
        
        BasicType *obj = [[BasicType alloc] init];
        obj.accountName = [NSString stringWithFormat:@"%@", [[[item attributeForName:@"jid"] stringValue] removeHostName]];
        [self updateBuddyListXmpp:@[obj] needRemove:YES];
    } else if ([subscription isEqualToString:@"both"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:[[[item attributeForName:@"jid"] stringValue] removeHostName]]) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[[[item attributeForName:@"jid"] stringValue] removeHostName]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

#pragma mark XMPPROOM Delegates

//Check if room is successfully created
- (void)xmppRoomDidCreate:(XMPPRoom *)sender {
    
    [self hideLoader];
    [sender fetchConfigurationForm];
    
    for (NSDictionary *buddy in sender.roomeUsers) {
        XMPPJID *user = [XMPPJID jidWithString:buddy[@"memberJId"]];
        [sender inviteUser:user withMessage:@"Hi from ***"];
    }
    NSString *roomJID = [sender.roomJID full];
    if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(groupCreated:withRoomJID:)]) {
        [self.multicastDelegate groupCreated:YES withRoomJID:roomJID];
    }
}

//Check if you've joined the room
- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [sender.roomJID.user removeHostName]];
    NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
    Group *group = nil;
    if (results.count > 0) {
        group= (Group *)results[0];
        group.isJoined = YES;
        NSLog(@"xmppRoomDidJoin = %@ ^^ group.isJoined = %d", group.accountName, group.isJoined);
    }
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender {
    
    NSLog(@"xmppRoomDidLeave = %@", sender.roomJID.user);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == [c] %@", [sender.roomJID.user removeHostName]];
    NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
    Group *group = nil;
    if (results.count > 0) {
        group= (Group *)results[0];
        group.isJoined = NO;
    }
    [sender deactivate];
    [sender removeDelegate:self];
}

/**
 * Necessary to prevent this message:
 * "This room is locked from entry until configuration is confirmed."
 */

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    NSXMLElement *newConfig = [configForm copy];
    NSArray *fields = [newConfig elementsForName:@"field"];
    
    for (NSXMLElement *field in fields)
    {
        NSString *var = [field attributeStringValueForName:@"var"];
        // Make Room Persistent
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    
    [sender configureRoomUsingOptions:newConfig];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence {
    //    NSLog(@"occupantDidJoin: %@ withPresence = %@",occupantJID, presence);
    
    // a buddy went offline/online
    NSString *presenceType = [presence type]; // online/offline
    NSString *myUsername = [occupantJID full];
    NSString *presenceFromUser = [[presence from] full];
    
    [self updateBuddyListWithReceivePresenceType:presenceType myUsername:myUsername presenceFromUser:presenceFromUser];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence {
    //    NSLog(@"occupantDidLeave: %@ withPresence = %@",occupantJID, presence);
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence {
    //    NSLog(@"occupantDidUpdate: %@ withPresence = %@",occupantJID, presence);
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender {
    //    NSLog(@"xmppRoomDidDestroy = %@", sender);
}

- (void)xmppRoom:(XMPPRoom *)sender didFailToDestroy:(XMPPIQ *)iqError {
    //    NSLog(@"xmppRoomdidFailToDestroy = %@", iqError);
}

#pragma mark XMPPReconnect Delegates

- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags {
    NSLog(@"didDetectAccidentalDisconnect:%u",connectionFlags);
    [self goOffline];
    [self setAllOffline];
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags {
    NSLog(@"shouldAttemptAutoReconnect:%u",reachabilityFlags);
    return YES;
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
    //    NSLog(@"socketDidConnect:%@",socket);
    
    [socket performBlock:^{
        [socket enableBackgroundingOnSocket];
    }];
}
#pragma mark XMPPMessageCarbons Delegates
- (void)xmppMessageCarbons:(XMPPMessageCarbons *)xmppMessageCarbons didReceiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing {
    
    //NSLog(@"xmppMessageCarbons:%@ isOutgoing = %d", message, isOutgoing);
    [self xmppStream:self.xmppStream didReceiveMessage:message];
}

/*
 #pragma mark XMPPvCardTempModuleDelegate Delegates
 
 - (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule {
 [APPDELEGATE stopLoading];
 [vCardTempModule deactivate];
 [vCardTempModule removeDelegate:self];
 }
 - (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error {
 [APPDELEGATE stopLoading];
 [vCardTempModule deactivate];
 [vCardTempModule removeDelegate:self];
 }
 
 - (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid {
 [APPDELEGATE stopLoading];
 UIImage *image = [UIImage imageWithData:vCardTemp.photo];
 NSLog(@"didReceivevCardTemp image = %@", image);
 NSLog(@"jid = %@", jid);
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accountName == %@", [jid user]];
 
 NSArray *results = [self.buddyList filteredArrayUsingPredicate:predicate];
 BasicType *buddy;
 
 if (results.count != 0) {
 buddy = results[0];
 //        buddy.profileImageURL = image;
 }
 NSString *fileName = [NSString stringWithFormat:@"%@_%@",[jid user],[jid domain]];
 
 [[ImageCache sharedImageCache] storeImage:image forUrl:fileName];
 
 if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(updatedAvatarResult:withError:)]) {
 [self.multicastDelegate updatedAvatarResult:image withError:nil];
 }
 [vCardTempModule deactivate];
 [vCardTempModule removeDelegate:self];
 }
 - (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToFetchvCardForJID:(XMPPJID *)jid error:(NSXMLElement*)error {
 [APPDELEGATE stopLoading];
 NSLog(@"failedToFetchvCardForJID error = %@", error);
 NSLog(@"jid = %@", jid);
 
 if ([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(updatedAvatarResult:withError:)]) {
 [self.multicastDelegate updatedAvatarResult:nil withError:nil];
 }
 [vCardTempModule deactivate];
 [vCardTempModule removeDelegate:self];
 }
 */

#pragma mark AlertView Delegates

- (void)alertView:(CustomAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    //NSLog(@"alertView.alertName = %@", alertView.user);
    if (alertView.tag == kAlertViewTagAddBuddy) {
        
        if (buttonIndex == 1) {
            
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:alertView.dataDetails andAddToRoster:YES];
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:[alertView.dataDetails user]]) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[alertView.dataDetails user]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            [self.xmppRoster rejectPresenceSubscriptionRequestFrom:alertView.dataDetails];
        }
    } else if (alertView.tag == kAlertViewTagGroupInvitation) {
        
        XMPPMessage *message = alertView.dataDetails;
        XMPPJID *roomJid = [XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]];
        self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomArchiveStorage jid:roomJid];
        [self.xmppRoom activate:self.xmppStream];
        
        if (buttonIndex == 1) {
            
            [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
            NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
            [history addAttributeWithName:@"maxchars" stringValue:@"0"];
            [self.xmppRoom joinRoomUsingNickname:self.xmppStream.myJID.user history:history password:nil];
        } else {
            
            NSXMLElement *xElement = [message elementForName: @"x" xmlns: XMPPMUCUserNamespace];
            if (xElement) {
                NSXMLElement *invite = [xElement elementForName:@"invite"];
                if (invite) {
                    XMPPJID *inviteeId = [XMPPJID jidWithString:[[invite attributeForName:@"from"] stringValue]];
                    [self.xmppRoom declineGroupRequest:roomJid invitee:inviteeId withMessage:@"No thank you"];
                }
            }
        }
    }
}


// Pul to referesh  :- @"history"
// New message :-   @"recent"

- (void)loadChatHistoryForUser:(BasicType *)buddy withMessageId:(NSString *)messageID orderBY:(NSString *)orderBy{
    
    //    NSDictionary *record = [DATABASEMANAGER getLastMessageIdOfUser:[buddy.accountName addHostName] ];
    NSString *lastMessageId = messageID;
    if(!lastMessageId)
        lastMessageId = @"";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params setValue:[self getMyJid] forKey:@"from_jid"];
    [params setValue:[buddy.accountName addHostName] forKey:@"to_jid"];
    [params setValue:@"chat" forKey:@"chat_type"];
    [params setValue:lastMessageId forKey:@"last_message_id"];
    [params setValue:orderBy forKey:@"orderby"];

    
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_history"];
    
    
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        if (success && [[responseData valueForKey:KEY_STATUS] boolValue]) {
            NSLog(@"%@", responseData);
            
            NSArray *array = [responseData valueForKey:@"all_stanza"];
            NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:@"stamp" ascending:YES];
            array = [array sortedArrayUsingDescriptors:@[descriptor]];
            
            for(NSDictionary *dic in array){
                NSString *stanza = [dic valueForKey:@"messageStanza"];
                stanza = [stanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
                
                NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:stanza error:nil] ;
                NSString *packetId = [[xml attributeForName:@"id"] stringValue];
                
                NSMutableDictionary *messageDict = [NSMutableDictionary dictionaryWithDictionary:dic];
                [messageDict setValue:packetId forKey:@"id"];
                [messageDict setValue:stanza forKey:@"messageStanza"];
                NSDictionary *dict = [DATABASEMANAGER getMessageWithMessageId:[messageDict valueForKey:@"id"] forBuddy:[buddy.accountName addHostName] toUser:[self getMyJid] ];
                if (dict && dict.count > 0) {
                    NSLog(@"BHAGOOOO");
                }
                else{
                    [self processHistoryData:messageDict forUser:buddy];
                }
            }
            NSString *lastMessageIdFromServer = [Utility getValueFromDictionary:responseData Key:@"lastMessageId"];
            [DATABASEMANAGER updateLastMessageId:lastMessageIdFromServer forContact:[buddy.accountName addHostName]];
            
            if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(historyLoaded:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.multicastDelegate historyLoaded:YES];
                });
            }
        }else{
            if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(historyLoaded:)]){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.multicastDelegate historyLoaded:NO];
                });
            }
        }
    }];
    
}

- (void)loadChatHistoryForGroup:(BasicType *)group withMessageId:(NSString *)messageID orderBY:(NSString *)orderBy{
    
    NSString *lastMessageId = messageID;
    if(!lastMessageId)
        lastMessageId = @"";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"from_jid" : [self getMyJid],
                                                                                  @"to_jid" : [group.accountName addGroupHostName],
                                                                                  @"chat_type" : @"groupchat",
                                                                                  @"last_message_id" : lastMessageId,
                                                                                  @"resource_type"  : @"ios",
                                                                                  @"orderby"    :   orderBy
                                                                                  }];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_history"];
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        if (success && [[responseData valueForKey:KEY_STATUS] boolValue]) {
            NSLog(@"%@", responseData);
            
            // sort array to stor recent message in order
            NSArray *array = [responseData valueForKey:@"all_stanza"];
            NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:@"stamp" ascending:YES];
            array = [array sortedArrayUsingDescriptors:@[descriptor]];
            
            for(NSDictionary *dic in array){
                NSString *stanza = [dic valueForKey:@"messageStanza"];
                stanza = [stanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
                
                NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:stanza error:nil] ;
                NSString *packetId = [[xml attributeForName:@"id"] stringValue];
                
                NSMutableDictionary *messageDict = [NSMutableDictionary dictionaryWithDictionary:dic];
                [messageDict setValue:packetId forKey:@"id"];
                [messageDict setValue:stanza forKey:@"messageStanza"];
                NSDictionary *dict = [DATABASEMANAGER getMessageWithMessageId:[messageDict valueForKey:@"id"] forBuddy:[group.accountName addGroupHostName] toUser:[self getMyJid] ];
                if (dict && dict.count > 0) {
                    NSLog(@"BHAGOOOO");
                }
                else{
                    [self processGroupHistoryData:messageDict forUser:group];
                }
                
            }
            NSString *lastMessageIdFromServer = [Utility getValueFromDictionary:responseData Key:@"lastMessageId"];
            [DATABASEMANAGER updateLastMessageId:lastMessageIdFromServer forGroup:[group.accountName addGroupHostName] ];
            
            if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(historyLoaded:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.multicastDelegate historyLoaded:YES];
                });
                
            }
        }else{
            
            if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(historyLoaded:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.multicastDelegate historyLoaded:NO];
                });
            }
        }
    }];
}

- (void)processGroupHistoryData:(NSDictionary *)data forUser:(BasicType *)user{
    
    NSString *msg = [data valueForKey:@"body"];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    NSString *idVal = [data valueForKey:@"id"];
    [messageDict setValue:msg forKey:@"message"];
    [messageDict setValue:idVal forKey:@"packetId"];
    
    [messageDict setValue:[data valueForKey:@"messageStanza"] forKey:@"messageStanza"];
    [messageDict setValue:@1 forKey:@"isGroupMessage"];
    
    NSString *groupJID = [[data valueForKey:@"to"] removeLastPathComponent];
    [messageDict setValue:groupJID forKey:@"groupJId"];
    
    NSString *from = [[data valueForKey:@"from"] removeLastPathComponent];
    from = [from removeHostName];
    
    NSString *toName = [[data valueForKey:@"to"] removeFirstPathComponent];
    toName = [toName removeHostName];
    
    NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
    [m setObject:msg forKey:KEY_MESSAGE];
    [m setObject:from forKey:KEY_SENDER_NAME];
    [m setObject:[toName removeHostName] forKey:KEY_RECEIVER_NAME];
    [m setObject:[NSNumber numberWithInt:MESSAGE_TEXT] forKey:KEY_MESSAGE_TYPE];
    [m setObject:[NSNumber numberWithBool:[from isEqualToString:GETUSERID]] forKey:KEY_ISMESSAGEINCOMING];
    
    [messageDict setValue:[m objectForKey:KEY_ISMESSAGEINCOMING] forKey:@"isFromMe"];
    
    if ([from isEqualToString:GETUSERID]) {
        [messageDict setValue:@2 forKey:@"messageStatus"];
        [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
        [messageDict setValue:[from addHostName] forKey:@"bareJId"];
    } else {
        [messageDict setValue:[NSNumber numberWithInt:-1] forKey:@"messageStatus"];
        [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
        [messageDict setValue:[from addHostName] forKey:@"bareJId"];
    }
    
    if ([msg isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
        
        NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
        [mediaDict setValue:@1 forKey:@"mediaType"];
        
        NSString *stanza = [messageDict valueForKey:@"messageStanza"];
        
        stanza = [stanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
        
        NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:stanza error:nil] ;
        
        NSArray *itemElements = [xml elementsForName: @"body"];
        
        for (NSXMLElement *element in itemElements) {
            if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                
                NSString *strImg = [element stringValue];
                UIImage *imgThumb = [strImg decodeBase64ToImage];
                if(imgThumb == nil)
                    return;
                [m setObject:imgThumb forKey:KEY_THUMB_IMAGE];
                [m setObject:[NSNumber numberWithInt:MESSAGE_IMAGE] forKey:KEY_MESSAGE_TYPE];
                [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                
            } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                
                NSString *imgUrl = [element stringValue];
                [m setObject:imgUrl forKey:KEY_IMAGE_URL];
                [mediaDict setValue:imgUrl forKey:@"mediaServerPath"];
            }
        }
        
        NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
        if (mediaId>0)
            [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
        
        [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
        
    } else {
        [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
    }
    
    NSString *d = [data valueForKey:@"stamp"];
    NSDate *date = [self getLocalDateFromDate:d];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [date timeIntervalSince1970]] forKey:@"messageDate"];
    
    [DATABASEMANAGER insertMessage:messageDict ];
    
    //    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    //    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    //    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    //    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    //    [recentMessageDict setValue:messageDict[@"bareJId"] forKey:@"bareJId"];
    //    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    //    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
}

- (void)processHistoryData:(NSDictionary *)data forUser:(BasicType *)user{
    
    NSString *msg = [data valueForKey:@"body"];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    NSString *idVal = [data valueForKey:@"id"];
    [messageDict setValue:msg forKey:@"message"];
    [messageDict setValue:idVal forKey:@"packetId"];
    
    [messageDict setValue:[data valueForKey:@"messageStanza"] forKey:@"messageStanza"];
    [messageDict setValue:@0 forKey:@"isGroupMessage"];
    [messageDict setValue:@"" forKey:@"groupJId"];
    
    NSString *from = [[data valueForKey:@"from"] removeLastPathComponent];
    from = [from removeHostName];
    
    NSString *toName = [[data valueForKey:@"to"] removeLastPathComponent];
    toName = [toName removeHostName];
    
    NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
    [m setObject:msg forKey:KEY_MESSAGE];
    [m setObject:from forKey:KEY_SENDER_NAME];
    [m setObject:[toName removeHostName] forKey:KEY_RECEIVER_NAME];
    [m setObject:[NSNumber numberWithInt:MESSAGE_TEXT] forKey:KEY_MESSAGE_TYPE];
    [m setObject:[NSNumber numberWithBool:[from isEqualToString:GETUSERID]] forKey:KEY_ISMESSAGEINCOMING];
    
    [messageDict setValue:[m objectForKey:KEY_ISMESSAGEINCOMING] forKey:@"isFromMe"];
    
    if ([from isEqualToString:GETUSERID]) {
        [messageDict setValue:@2 forKey:@"messageStatus"];
        [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
        [messageDict setValue:[toName addHostName] forKey:@"bareJId"];
    } else {
        [messageDict setValue:[NSNumber numberWithInt:-1] forKey:@"messageStatus"];
        [messageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
        [messageDict setValue:[user.accountName addHostName] forKey:@"bareJId"];
    }
    
    if ([msg isEqualToString:CODE_FOR_IMAGE_IN_MESSAGE]) {
        
        NSMutableDictionary *mediaDict = [NSMutableDictionary dictionary];
        [mediaDict setValue:@1 forKey:@"mediaType"];
        
        NSString *stanza = [messageDict valueForKey:@"messageStanza"];
        stanza = [stanza stringByReplacingOccurrencesOfString:@"xml:lang" withString:@"lang"];
        
        NSXMLElement *xml = [[NSXMLElement alloc] initWithXMLString:stanza error:nil] ;
        
        NSArray *itemElements = [xml elementsForName: @"body"];
        
        for (NSXMLElement *element in itemElements) {
            if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"attachment"]) {
                
                NSString *strImg = [element stringValue];
                UIImage *imgThumb = [strImg decodeBase64ToImage];
                if(imgThumb == nil)
                    return;
                [m setObject:imgThumb forKey:KEY_THUMB_IMAGE];
                [m setObject:[NSNumber numberWithInt:MESSAGE_IMAGE] forKey:KEY_MESSAGE_TYPE];
                [mediaDict setValue:strImg forKey:@"mediaThumbPath"];
                
            } if ([[[element attributeForName:@"lang"] stringValue] isEqualToString:@"imageUrl"]) {
                
                NSString *imgUrl = [element stringValue];
                [m setObject:imgUrl forKey:KEY_IMAGE_URL];
                [mediaDict setValue:imgUrl forKey:@"mediaServerPath"];
            }
        }
        
        NSInteger mediaId = [DATABASEMANAGER insertMediaAndGetMediaID:mediaDict ];
        if (mediaId>0)
            [messageDict setValue:[NSNumber numberWithInteger:mediaId] forKey:@"mediaId"];
        
        [messageDict setValue:@MESSAGE_IMAGE forKey:@"messageType"];
        
    } else {
        [messageDict setValue:@MESSAGE_TEXT forKey:@"messageType"];
    }
    
    NSString *d = [data valueForKey:@"stamp"];
    NSDate *date = [self getLocalDateFromDate:d];
    [messageDict setValue:[NSString stringWithFormat:@"%f", [date timeIntervalSince1970]] forKey:@"messageDate"];
    
    [DATABASEMANAGER insertMessage:messageDict ];
    
    //    NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
    //    [recentMessageDict setValue:messageDict[@"isFromMe"] forKey:@"recentMessageOutgoing"];
    //    [recentMessageDict setValue:messageDict[@"messageDate"] forKey:@"recentMessageTimestamp"];
    //    [recentMessageDict setValue:messageDict[@"message"] forKey:@"recentMessage"];
    //    [recentMessageDict setValue:messageDict[@"bareJId"] forKey:@"bareJId"];
    //    [recentMessageDict setValue:messageDict[@"streamBareJId"] forKey:@"streamBareJId"];
    //    [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
}

- (NSDate *)getLocalDateFromDate:(NSString *)startTime {
    
//    NSDate *date = [NSDate getDateWithFormat:@"dd-MM-yyyy HH:mm:ss" ForSring:startTime];
//    NSDateFormatter *dateFormat1 = [[NSDateFormatter alloc] init];
//    [dateFormat1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
//    NSString *dateStr = [dateFormat1  stringFromDate:date];// string with yyyy-MM-dd format
    NSDate *newDate = [NSDate composeDateFromSring:startTime];
    return newDate;
}

- (void)fetchBuddyListFromServer{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"username" : GETUSERID}];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_ofroster_list_by_centre"];
    
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        
        if (success && [[responseData valueForKey:KEY_STATUS] boolValue]) {
            
            NSArray *rosterArray = [[responseData valueForKey:@"roster"] valueForKey:@"rosterItem"];
            NSLog(@"%@", rosterArray);
            
            NSMutableArray *buddies = [[NSMutableArray alloc] init];
            NSMutableArray *tempBuddies = [[NSMutableArray alloc] init];
            for (NSDictionary *roster in rosterArray) {
                
                if ([[roster valueForKey:@"subscriptionType"] isEqualToString:@"none"]) {
                    continue;
                }
                
                Buddy *objBuddy             = [[Buddy alloc] init];
                objBuddy.type               = kBaseTypeBuddy;
                objBuddy.displayName        = [Utility getValueFromDictionary:roster Key:@"nickname"];
                objBuddy.accountName        = [[Utility getValueFromDictionary:roster Key:@"jid"] removeHostName];
                objBuddy.subscriptionType   = [Utility getValueFromDictionary:roster Key:@"subscriptionType"];
                objBuddy.user               = [XMPPJID jidWithString:[roster valueForKey:@"jid"]];
                objBuddy.profileImageURL    = [Utility getValueFromDictionary:roster Key:@"image"];
                objBuddy.user_type          = [[Utility getValueFromDictionary:roster Key:@"user_type"] integerValue];
                objBuddy.centerId           = [Utility getValueFromDictionary:roster Key:@"center_id"];
                [buddies addObject:objBuddy];
                
                [tempBuddies addObject:@{@"displayName" : (objBuddy.displayName == nil ? @"" : objBuddy.displayName),
                                         @"avatarPath" : objBuddy.profileImageURL,
                                         @"contactJId" : [Utility getValueFromDictionary:roster Key:@"jid"],
                                         @"userJId" : [self getMyJid],
                                         @"status" : @"",
                                         @"subscriptionType" : [Utility getValueFromDictionary:roster Key:@"subscriptionType"],
                                         @"isDeleted" : @0,
                                         @"user_type" : [Utility getValueFromDictionary:roster Key:@"user_type"],
                                         @"center_id" : [Utility getValueFromDictionary:roster Key:@"center_id"]}];
            }
            if (buddies.count > 0) {
                [DATABASEMANAGER insertContacts:tempBuddies];
                [self updateBuddyListXmpp:buddies needRemove:NO];
            }
        }
    }];

}

- (void)fetchOldConversationFromServer{
    
    //    [self showLoader];
  
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"fromJID" : [GETUSERID addHostName]
                                                                                  }];
    NSString *url = [URL_BASE_CHAT stringByAppendingString:@"get_last_msg_by_user"];
    [[RequestHandler sharedHandler] sendJSONRequestWithParams:params URL:url handler:^(BOOL success, NSDictionary *responseData) {
        [self hideLoader];
        
        if (success && [[responseData valueForKey:KEY_STATUS] boolValue]) {
            
            NSDictionary *object = [responseData valueForKey:@"conversation_msg"];
            NSLog(@"%@", object);
            if([object isKindOfClass:[NSDictionary class]]){
                NSArray *bodyarray = [object valueForKey:@"latest_conversation_msg"];
                if([bodyarray isKindOfClass:[NSArray class]]){
                    
                    for (NSDictionary *messageDict in bodyarray) {
                        NSString *fromJid = [Utility getValueFromDictionary:messageDict Key:@"fromJID"];
                        BOOL isFromMe = [fromJid isEqualToString:[GETUSERID addHostName]];
                        NSString *datStr = [Utility getValueFromDictionary:messageDict Key:@"sentDate"];
                        NSDate *newDate = [self getLocalDateFromDate:datStr];
                        NSString *msgDate = [NSString stringWithFormat:@"%f", [newDate timeIntervalSince1970]];
                        NSString *toJid = [Utility getValueFromDictionary:messageDict Key:@"toJID"];
                        NSString *msg = [Utility getValueFromDictionary:messageDict Key:@"body"];
                        
                        NSMutableDictionary *recentMessageDict = [NSMutableDictionary dictionary];
                        [recentMessageDict setValue:[NSNumber numberWithBool:isFromMe] forKey:@"recentMessageOutgoing"];
                        [recentMessageDict setValue:msgDate forKey:@"recentMessageTimestamp"];
                        [recentMessageDict setValue:msg forKey:@"recentMessage"];
                        if([toJid isEqualToString:self.xmppStream.myJID.bare]){
                            [recentMessageDict setValue:fromJid forKey:@"bareJId"];
                        }else{
                            [recentMessageDict setValue:toJid forKey:@"bareJId"];
                        }
                        
                        [recentMessageDict setValue:self.xmppStream.myJID.bare forKey:@"streamBareJId"];
                        [DATABASEMANAGER insertRecentMessage:recentMessageDict ];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBuddyListMessage object:nil];
                    [self hideLoader];
                }
                if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(lastConversationLoaded:)]){
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.multicastDelegate lastConversationLoaded:YES];
                    });
                }
            }
        }else{
            if([self.multicastDelegate hasDelegateThatRespondsToSelector:@selector(lastConversationLoaded:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.multicastDelegate lastConversationLoaded:NO];
                });
            }
            [self hideLoader];
        }
    }];
    
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    /*
     * Properly secure your connection by setting kCFStreamSSLPeerName
     * to your server domain name
     */
    [settings setObject:self.xmppStream.myJID.domain forKey:(NSString *)kCFStreamSSLPeerName];
    
    /*
     * Use manual trust evaluation
     * as stated in the XMPPFramework/GCDAsyncSocket code documentation
     */
    [settings setObject:@(YES) forKey:GCDAsyncSocketManuallyEvaluateTrust];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    /* Custom validation for your certificate on server should be performed */
    
    completionHandler(YES); // After this line, SSL connection will be established
}

- (NSString *)getResourceId{
    
    return [[self.xmppStream myJID] resource];
}

- (NSString *)getMessageID{
    return [[[self.xmppStream generateUUID] substringToIndex:8] lowercaseString];
}
- (void)showLoader
{
    if(_m_HUD == nil)
    {
        _m_HUD = [[MBProgressHUD alloc] initWithView:APPDELEGATE.window];
        [APPDELEGATE.window addSubview:_m_HUD];
    }
    _m_HUD.label.text = @"Loading...";
    [_m_HUD showAnimated:YES];
    [APPDELEGATE.window bringSubviewToFront:self.m_HUD];
    
}

- (void)hideLoader
{
    [_m_HUD hideAnimated:YES];
}

-(NSString *)getMyJid{
    return isObjectNotEmpty([[self.xmppStream myJID] bare])?[[self.xmppStream myJID] bare]:[GETUSERID addHostName];
}


@end
