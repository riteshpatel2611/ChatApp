//
//  ForgotPasswordVC.m
//  Chat App
//
//  Created by Fxbytes on 5/18/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "ForgotPasswordVC.h"

@interface ForgotPasswordVC ()
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UIView *emailSentView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UIImageView *imgBaclground;

@end

@implementation ForgotPasswordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.emailSentView.hidden = YES;
    
    self.btnLogin.layer.cornerRadius = self.btnLogin.frame.size.height/2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickCancel:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickReset:(id)sender {
    
    if(!self.emailSentView.hidden){
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }else{
        
        [UIView transitionWithView:self.passwordView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.passwordView.hidden = !self.passwordView.hidden;
                            self.emailSentView.hidden = !self.emailSentView.hidden;
                            
                            [self.btnLogin setTitle:@"Login" forState:UIControlStateNormal];
                            self.imgBaclground.hidden = NO;
                        }
                        completion:NULL];
        
    }
  
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
