//
//  SettingViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/22/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "SettingViewController.h"
#import "ProfileViewController.h"
#import "ChangePasswordVC.h"
#import "PNSettingVC.h"
#import "SignInViewController.h"
@interface SettingViewController ()
@property (weak, nonatomic) IBOutlet UIView *viewProfile;
@property (weak, nonatomic) IBOutlet UIView *viewChangePassword;
@property (weak, nonatomic) IBOutlet UIView *viewNotification;
@property (weak, nonatomic) IBOutlet UIView *viewLogout;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.title = @"Settings";
    
    UITapGestureRecognizer *tapProfile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnProfile)];
    [self.viewProfile addGestureRecognizer:tapProfile];
    
    UITapGestureRecognizer *tapPassword = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnChangePassword)];
    [self.viewChangePassword addGestureRecognizer:tapPassword];
    
    UITapGestureRecognizer *tapNotification = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnNotification)];
    [self.viewNotification addGestureRecognizer:tapNotification];
    
    UITapGestureRecognizer *tapLogout = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnLogout)];
    [self.viewLogout addGestureRecognizer:tapLogout];
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didTapOnProfile{
    ProfileViewController *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_ProfileViewController"];
    [self.navigationController showViewController:nextVC sender:self];
}

-(void)didTapOnChangePassword{
    ChangePasswordVC *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_ChangePasswordVC"];
    [self.navigationController showViewController:nextVC sender:self];
}

-(void)didTapOnNotification{
    PNSettingVC *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_PNSettingVC"];
    [self.navigationController showViewController:nextVC sender:self];
}

-(void)didTapOnLogout{
    
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if([vc isKindOfClass:[SignInViewController class]]){
            SignInViewController *signInVC = (SignInViewController *)vc;
            [self.navigationController popToViewController:signInVC animated:YES];
            [self.navigationController setNavigationBarHidden:YES];
        }
    }
    
}
@end
