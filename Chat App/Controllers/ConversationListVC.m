//
//  ConversationListVCTableViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "ConversationListVC.h"
#import "ChatConversationCell.h"
#import "BuddyListViewController.h"
#import "ChatViewController.h"
#import "SettingViewController.h"
@interface ConversationListVC ()

@end

@implementation ConversationListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation bar
    [self.navigationController setNavigationBarHidden:NO];
    
    UIBarButtonItem *btnMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonPressed)];
    UIBarButtonItem *btnNewChat = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickNewChat)];
    [self.navigationItem setLeftBarButtonItem:btnMenu];
    [self.navigationItem setRightBarButtonItem:btnNewChat];
    
    self.title = @"Conversation";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)menuButtonPressed{
    
    SettingViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SBID_SettingViewController"];
    [self.navigationController showViewController:vc sender:self];
}

- (void)onClickNewChat{
    
    BuddyListViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SBID_BuddyListViewController"];
    [self.navigationController showViewController:vc sender:self];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatConversationCell" forIndexPath:indexPath];
    if(indexPath.row == 1){
        cell.lblName.text = @"Andrew Lamrock";
        cell.imgView.image = [UIImage imageNamed:@"user"];
        cell.lblCount.text = @"11";
    }else if(indexPath.row == 2){
        cell.lblName.text = @"John Doe";
        cell.imgView.image = [UIImage imageNamed:@"user"];
        cell.lblCount.text = @"1";
    }else if(indexPath.row == 3){
        cell.lblName.text = @"Fxbytes";
        cell.imgView.image = [UIImage imageNamed:@"group"];
        cell.lblCount.text = @"5";
    }else if(indexPath.row == 4){
        cell.lblName.text = @"Maria Lawson";
        cell.imgView.image = [UIImage imageNamed:@"user"];
        cell.lblCount.text = @"2";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ChatViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SBID_ChatViewController"];
    [self.navigationController showViewController:vc sender:self];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
