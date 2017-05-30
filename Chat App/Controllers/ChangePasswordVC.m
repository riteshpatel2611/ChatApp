//
//  ChangePasswordVC.m
//  Chat App
//
//  Created by Fxbytes on 5/25/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "ChangePasswordVC.h"

@interface ChangePasswordVC ()
@property (weak, nonatomic) IBOutlet UITextField *txtFieldOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldConfirmNewPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnUpdate;

@end

@implementation ChangePasswordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
//    [self.navigationItem setLeftBarButtonItem:btnBack];
    self.title = @"Change Password";
    
    self.btnUpdate.layer.cornerRadius = self.btnUpdate.frame.size.height/2;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 1)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickUpdate:(id)sender {
}
@end
