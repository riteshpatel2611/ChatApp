//
//  ChatViewController.h
//  Chat App
//
//  Created by Fxbytes on 5/22/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController

//UIX
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewWrapperHeight;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIView *msgCountView;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (nonatomic, retain) UIRefreshControl *refreshCtrl;
@property (weak, nonatomic) IBOutlet UITextView *txtFiledMsg;
@property (weak, nonatomic) IBOutlet UITableView *tblViewChat;
@property (weak, nonatomic) IBOutlet UIView *viewWrapper;

@end
