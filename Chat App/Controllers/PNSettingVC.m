//
//  PNSettingVC.m
//  Chat App
//
//  Created by Fxbytes on 5/25/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "PNSettingVC.h"

@interface PNSettingVC ()
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

@end

@implementation PNSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
//    [self.navigationItem setLeftBarButtonItem:btnBack];
    self.title = @"Notification";
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didChangeSwitch:(id)sender {
    
    UISwitch *swtch = (UISwitch *)sender;
    if(swtch.isOn){
        self.lblTitle.text = @"Enabled";
    }else{
        self.lblTitle.text = @"Disabled";
    }
}

@end
