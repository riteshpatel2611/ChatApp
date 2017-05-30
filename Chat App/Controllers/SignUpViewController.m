//
//  SignUpViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/18/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "SignUpViewController.h"
#import "ConversationListVC.h"

@interface SignUpViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtFieldCountryCode;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldMobile;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldConfirmPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (strong, nonatomic) NSArray *arrayCodes;
@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.btnLogin.layer.cornerRadius = self.btnLogin.frame.size.height/2;
    
    // getting user's country code
    CTCarrier *carrier = [[CTTelephonyNetworkInfo new] subscriberCellularProvider];
    NSString *countryCode = carrier.isoCountryCode;
    if(countryCode)
        self.txtFieldCountryCode.text = countryCode;
    
    // getting list of country codes
    [self parseJSON];
    
    UIPickerView *pickrView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 300)];
    pickrView.dataSource = self;
    pickrView.delegate = self;
    
    self.txtFieldCountryCode.inputView = pickrView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickCancel:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickLogin:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickSignup:(id)sender {
    
    if(isObjectEmpty(self.txtFieldEmail.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTEREMAIL, ALERT_BUTTON_TITLE_OK);
    }else if (isObjectEmpty(_txtFieldPassword.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERPASSWORD, ALERT_BUTTON_TITLE_OK);
    }else if (isObjectEmpty(_txtFieldConfirmPassword.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERCPASSWORD, ALERT_BUTTON_TITLE_OK);
    }else if (isObjectEmpty(_txtFieldMobile.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERMOBILE, ALERT_BUTTON_TITLE_OK);
    }else if (isObjectEmpty(_txtFieldUsername.text)){
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_ENTERUSERNAME, ALERT_BUTTON_TITLE_OK);
    }else{
        ConversationListVC *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_ConversationListVC"];
        [self.navigationController showViewController:nextVC sender:self];
    }
}

- (void)parseJSON {
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countries" ofType:@"json"]];
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
    
    if (localError != nil) {
        NSLog(@"%@", [localError userInfo]);
    }
    _arrayCodes = (NSArray *)parsedObject;
}

#pragma UIPickerView DataSource and Delegates
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
     return _arrayCodes.count;
}
- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
     return [[_arrayCodes objectAtIndex:row] valueForKey:@"name"];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    self.txtFieldCountryCode.text = [[_arrayCodes objectAtIndex:row] valueForKey:@"dial_code"];
}

@end
