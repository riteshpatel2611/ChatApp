//
//  ChatViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/22/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatCell.h"
#import "IQKeyboardManager.h"
@interface ChatViewController ()<UITextViewDelegate>

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
//    [self.navigationItem setLeftBarButtonItem:btnBack];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.title = @"Creative minds";

    
    self.tblViewChat.estimatedRowHeight = 2.0;
    self.tblViewChat.rowHeight = UITableViewAutomaticDimension;
    
    self.viewWrapper.layer.borderWidth=0.8;
    self.viewWrapper.layer.borderColor = [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1].CGColor;
    
    self.countLabel.layer.cornerRadius   =   self.countLabel.frame.size.width/2;
    self.countLabel.clipsToBounds        =   YES;
    self.msgCountView.hidden = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.tblViewChat addGestureRecognizer:tap];
    self.btnSend.enabled        =   NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) viewWillAppear:(BOOL)Animated {
    
    [[IQKeyboardManager sharedManager] setEnable:NO];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[IQKeyboardManager sharedManager] setEnable:YES];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];

    
}
- (void) keyboardWillChangeFrame:(NSNotification*)notification {
    
    NSDictionary* notificationInfo = [notification userInfo];
    CGRect keyboardFrame = [[notificationInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:[[notificationInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:[[notificationInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^{
                         
                         CGRect f = self.view.frame;
                         f.size.height = keyboardFrame.origin.y;
                         
                         self.view.frame = f;
//                         [self performSelector:@selector(madeLastMessageVisible) withObject:nil afterDelay:0.3];
                         
                     } completion:nil];
}


-(void)dismissKeyboard
{
    [self.txtFiledMsg resignFirstResponder];
}

#pragma mark - UITableView DataSource Method
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatCell *cell = nil;
    switch (indexPath.row) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
            cell.lblMessage.text = @"New chat started";
            break;
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ReciverCell"];
            cell.lblMessage.text = @"Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";
            cell.lblTimeStamp.text = @"Today 10:30 AM";
            break;
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:@"SenderCell"];
            cell.lblMessage.text = @"Hey I am good, how about you?\n how was the weekend.\nlorem ipsum is just a dummy text, to check height of text in chat cell.";
            cell.lblTimeStamp.text = @"Today 10:40 AM";
            break;
        case 3:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ReciverImageCell"];
            cell.lblTimeStamp.text = @"Today 11:30 AM";
            break;
        case 4:
            cell = [tableView dequeueReusableCellWithIdentifier:@"SenderImageCell"];
            cell.lblTimeStamp.text = @"Today 11:30 AM";
            break;
        default:
            break;
    }
    
    
    return cell;
}

#pragma -mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    text = [textView.text stringByReplacingCharactersInRange:range withString:text];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.btnSend.enabled = (text.length == 0)?NO:YES;

    return YES;
}



@end
