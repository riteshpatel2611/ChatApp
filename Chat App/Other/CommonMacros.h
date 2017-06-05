//
//  CommonMacros.h
//  Chat App
//
//  Created by Fxbytes on 5/17/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kNotificationConnectToServer                       = @"kNotificationConnectToServer";
static NSString *kNotificationUpdateBuddyListMessage                = @"kNotificationUpdateBuddyListMessage";
static NSString *kNotificationUpdateGroupListMembers                = @"kNotificationUpdateGroupListMembers";
static NSString *kNotificationUpdateBuddyPresence                   = @"kNotificationUpdateBuddyPresence";


@interface CommonMacros : NSObject


#define DEFAULT_HOST_NAME               @"152.194.204.120"
#define DEFAULT_GROUP_HOST_NAME         @"conference.152.194.204.120"

// Colors
#define COLOR_NAVIGATION_BAR_TINT           [UIColor MyColor:41 green:162 blue:215]
#define COLOR_NAVIGATION_TINT               [UIColor whiteColor]
#define COLOR_NAVIGATION_TITLE              [UIColor whiteColor]


// Fonts

#define FONT_ROBOTO_REGULAR         @"Roboto-Regular"
#define FONT_ROBOTO_BOLD            @"Roboto-Bold"
#define FONT_ROBOTO_MEDIUM          @"Roboto-Mediun"

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


#define STORYBOARD         [UIStoryboard storyboardWithName:@"Main" bundle: nil]


#define GETUSERID           [[[NSUserDefaults standardUserDefaults] objectForKey:USERID] lowercaseString]
#define GETUNIQUEUUID       [[[NSUserDefaults standardUserDefaults] objectForKey:UNIQUEUUID] lowercaseString]

#define MAX_IAMGE_SIZE 1000
#define QUALITY_IMAGE 0.7
#define MAX_IAMGE_THUMB_SIZE 100

#define DEVICE_HEIGHT [UIScreen mainScreen].bounds.size.height
#define DEVICE_WIDTH [UIScreen mainScreen].bounds.size.width
#define COLOR_WITH_rgba(r,g,b,a)        [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define FONT_SF_UI_DISPLAY_REGULAR      @"SFUIDisplay-Regular"
#define FONT_SF_UI_DISPLAY_BOLD         @"SFUIDisplay-Bold"
#define FONT_SF_UI_DISPLAY_BLACK        @"SFUIDisplay-Black"
#define FONT_SF_UI_DISPLAY_SEMI_BOLD    @"SFUIDisplay-Semibold"
#define FONT_SF_UI_DISPLAY_LIGHT        @"SFUIDisplay-Light"
#define FONT_SF_UI_DISPLAY_THIN         @"SFUIDisplay-Thine"
#define FONT_SF_UI_DISPLAY_HEAVY        @"SFUIDisplay-Heavy"
#define FONT_SF_UI_DISPLAY_ULTRALIGHT   @"SFUIDisplay-Ultralight"

//#define LIGHT_FONT_WITH_SIZE(x)     [UIFont fontWithName:ROBOTO_LIGHT size:x]
//#define REGULAR_FONT_WITH_SIZE(x)    [UIFont fontWithName:ROBOTO_REGULAR size:x]
//#define MEDIUM_FONT_WITH_SIZE(x)    [UIFont fontWithName:ROBOTO_MEDIUM size:x]
//#define ITALIC_FONT_WITH_SIZE(x)    [UIFont fontWithName:ROBOTO_ITALIC size:x]

#define MESSAGE_TEXT 1
#define MESSAGE_IMAGE 2

#define USERIMAGEURL    @"userImageURL"
#define USERID          @"userID"
#define UNIQUEUUID      @"uniqueUUID"
#define USERPASSWORD    @"userPassword"
#define DEVICETOKAN     @"deviceTokan"
#define RESOURCETYPE    @"ios"

#define KEY_RECEIVER_NAME @"receiver"
#define KEY_SENDER_NAME @"sender"
#define KEY_DISPLAYNAME @"displayName"
#define KEY_GROUP_NAME @"group"
#define KEY_MESSAGE @"msg"
#define KEY_ISMESSAGEINCOMING @"isIncoming"
#define KEY_IMAGE_URL @"imageUrl"
#define KEY_THUMB_IMAGE @"thumbImage"
#define KEY_MESSAGE_TYPE @"msgType"
#define KEY_PACKET_ID @"packetId"
#define KEY_TIME @"time"
#define KEY_PENDING_MSG_ID @"pendingMsgId"
#define KEY_IS_MSG_UPLOAD_IN_PROGRESS @"isMsgUploadInProgress"
#define KEY_IS_MSG_DOWNLOAD_IN_PROGRESS @"isMsgDownloadInProgress"
#define KEY_IMAGE_PATH @"image_path"
#define KEY_STATUS @"status"
#define KEY_MSG_STANZA  @"messageStanza"
#define KEY_TIME_STAMP  @"timeStamp"

#define IS_IPAD  UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#define CODE_FOR_IMAGE_IN_MESSAGE       @"11111111111DFSISDFSDFSDFDDDFAS"
#define CODE_FOR_MEMBER_ADDED           @"22222222222HDBFHASKHFDHSBGDJSH##"
#define CODE_FOR_MEMBER_REMOVED         @"33333333333FBSUYREBVFJKSBJFDHB##"
#define CODE_FOR_CHANGE_GROUPNAME       @"44444444444CIOAISJWMCDWEHJKNSK##"
#define CODE_FOR_CHANGE_GROUPPHOTO      @"55555555555HJKWEIRUFCYURPLSUXY##"

#define ALERT_BUTTON_TITLE_OK    @"OK"
#define ALERT_VIEW_TITLE         @"Alert"

#define APP_VERSION_STRING        [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

#define APPDELEGATE             [AppDelegate sharedDelegate]
#define CHATMANAGER             [ChatProtocolManager sharedChatManager]
#define BUDDYLISTMANAGER        [BuddyListManager sharedBuddyListManager]
#define DATABASEMANAGER         [Database connection]

#define VIEWCONTROLLER_LOGIN                    @"LoginController"
#define VIEWCONTROLLER_GROUPBUDDYLIST           @"GroupBuddyListController"
#define VIEWCONTROLLER_BUDDYLIST                @"BuddyListController"
#define VIEWCONTROLLER_NEWGROUPCHAT             @"NewGroupChatController"
#define VIEWCONTROLLER_CHANGEPASSWORD           @"ChangePasswordController"

#define CELL_BUDDYLIST                          @"BuddyCellIdentifier"
#define CELL_GROUPBUDDYLIST                     @"GroupBuddyCell"

#define SIDE_INDEX_TABLE @[@"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"]

//#define SEARCH_PREDECATE @"((SELF.type == 1 AND SELF.name CONTAINS[c] %@) OR (SELF.type == 2 AND SELF.displayName CONTAINS[c] %@))"
//#define SEARCH_PREDECATE_BEGINSWITH @"((SELF.type == 1 AND SELF.name BEGINSWITH[c] %@) OR (SELF.type == 2 AND SELF.displayName BEGINSWITH[c] %@))"
//#define SEARCH_PREDECATE_NUMERIC @"((SELF.type == 1 AND SELF.name MATCHES %@) OR (SELF.type == 2 AND SELF.displayName MATCHES %@))"

#define SEARCH_PREDECATE @"((SELF.name CONTAINS[c] %@))"
#define SEARCH_PREDECATE_BEGINSWITH @"((SELF.name BEGINSWITH[c] %@))"
#define SEARCH_PREDECATE_NUMERIC @"(SELF.name MATCHES %@)"

@end
