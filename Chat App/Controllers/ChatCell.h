//
//  ChatCell.h
//  XMPPChat
//
//  Created by Amit on 17/10/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXLabel.h"
@protocol ChatCellDelegate <NSObject>

@optional
- (void)selectedChatCellDelegateActionWithMessage:(NSDictionary *)dicMsg Cell:(id)cell;
- (void)resendChatCellDelegateActionWithMessage:(NSDictionary *)dicMsg Cell:(id)cell;

@end

@interface ChatCell : UITableViewCell

@property (nonatomic, assign) id <ChatCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet ChatAsyncImageView *imgUser;
@property (weak, nonatomic) IBOutlet FXLabel *lblMessage;
@property (weak, nonatomic) IBOutlet UIImageView *imgBuble;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnRestart;
@property (weak, nonatomic) IBOutlet ChatAsyncImageView *imgMessage;


//- (void)loadMessage:(NSMutableDictionary *)dicMsg forBuddy:(BasicType *)buddy withTime:(BOOL)showTime;
//
//- (IBAction)restartSendRequestAction:(id)sender;

@end
