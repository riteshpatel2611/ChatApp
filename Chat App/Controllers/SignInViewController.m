//
//  SignInViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/18/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "SignInViewController.h"
#import "ConversationListVC.h"
@interface SignInViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldUserName;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.btnLogin.layer.cornerRadius = self.btnLogin.frame.size.height/2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self.txtFieldUserName setText:nil];
    [self.txtFieldPassword setText:nil];
}
- (IBAction)onClickCancel:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onClickLogin:(id)sender {
    
    if(isObjectEmpty(self.txtFieldUserName.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERUSERNAME, ALERT_BUTTON_TITLE_OK);
    }else if (isObjectEmpty(_txtFieldPassword.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERPASSWORD, ALERT_BUTTON_TITLE_OK);
    }else{
        ConversationListVC *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_ConversationListVC"];
        [self.navigationController showViewController:nextVC sender:self];
    }
}

- (IBAction)onClickForgotPassword:(id)sender {

}

- (void)connectToServer {
    
    [CHATMANAGER addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [CHATMANAGER showLoader];
    
    if ([CHATMANAGER loginUser:@{@"username" : [[NSUserDefaults standardUserDefaults] objectForKey:USERID],
                                 @"password" : [[NSUserDefaults standardUserDefaults] objectForKey:USERPASSWORD]}]) {
        NSLog(@"connected");
    }
}

- (void)loginResult:(BOOL)success {
    
    if (!success) {
        self.title = @"Home";
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_WRONGLOGIN, ALERT_BUTTON_TITLE_OK);
        [CHATMANAGER disconnect];
        [CHATMANAGER removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    } else {
        
        ConversationListVC *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_ConversationListVC"];
        [self.navigationController showViewController:nextVC sender:self];
     
    }
    [CHATMANAGER hideLoader];
}
@end
