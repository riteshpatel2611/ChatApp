//
//  CustomAlertView.h
//  XMPPChat
//
//  Created by Fxbytes on 10/14/16.
//  Copyright © 2016 com.fxbytes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPJID.h"

enum {
    kAlertViewTagAddBuddy = 0x00,
    kAlertViewTagAddGroup,
    kAlertViewTagGroupInvitation,
    kAlertViewTagSettings,
    kAlertViewTagRemoveUser,
    kAlertViewTagUpdateGroupName,
    kAlertViewTagUpdateGroupImage,
    kAlertViewTagEditButton
    
};

@interface CustomAlertView : UIAlertView

@property (nonatomic, strong) id dataDetails;

@end
