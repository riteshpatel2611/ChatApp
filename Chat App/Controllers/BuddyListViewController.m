//
//  BuddyListViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "BuddyListViewController.h"
#import "BuddyCell.h"
#import "NewGroupChatVC.h"
#import <ContactsUI/ContactsUI.h>
@interface BuddyListViewController ()<CNContactViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BuddyListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
//    [self.navigationItem setLeftBarButtonItem:btnBack];
    self.title = @"New Chat";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CreateNewGroup" forIndexPath:indexPath];
        return cell;
    }else  if(indexPath.row == 1){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewContact" forIndexPath:indexPath];
        return cell;
    }
    
    BuddyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BuddyCell" forIndexPath:indexPath];
    
    if(indexPath.row == 2){
        cell.lblName.text = @"Jacob Willson";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }else if(indexPath.row == 3){
        cell.lblName.text = @"Maria Lawson";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }else if(indexPath.row == 4){
        cell.lblName.text = @"Ritesh Patel";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }else if(indexPath.row == 5){
        cell.lblName.text = @"Gorav Jain";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == 0){
        
        NewGroupChatVC *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SBID_NewGroupChatVC"];
        [self.navigationController showViewController:vc sender:self];

    }else if (indexPath.row == 1){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            CNContactViewController *vc = [CNContactViewController viewControllerForNewContact:[[CNMutableContact alloc] init]];
            vc.delegate = self;
            [Utility setNavigationBarThemeForContactsUI];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nc animated:YES completion:nil];
            
        });
    }
}
#pragma -mark ContactsUI Delegate
- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property{
    return YES;
}
- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(nullable CNContact *)contact{
     [Utility setNavigationBarTheme];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
