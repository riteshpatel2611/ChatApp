//
//  CreateGroupViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/25/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "CreateGroupViewController.h"
#import "GroupMemberScrollView.h"

@interface CreateGroupViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgViewGroup;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldGroupName;
@property (weak, nonatomic) IBOutlet GroupMemberScrollView *scrollView;

@end

@implementation CreateGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
//    [self.navigationItem setLeftBarButtonItem:btnBack];
    
    UIBarButtonItem *btnCreate = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(onClickCreateGroup)];
    [self.navigationItem setRightBarButtonItem:btnCreate];
    self.title = @"New Group";
    
    Buddy *buddy1 = [[Buddy alloc] init];
    buddy1.displayName = @"Andrew Lamrok";
    buddy1.profileImageURL = @"https://static.pexels.com/photos/6468/animal-brown-horse.jpg";
    
    Buddy *buddy2 = [[Buddy alloc] init];
    buddy2.displayName = @"Jacob";
    buddy2.profileImageURL = @"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwsjlYLK6t8vhYJPGcejwLvZLWB6cFSWYtl6SxgRWr3ZGYvih-";
    NSArray *array = @[buddy1, buddy2];
    
    [self.scrollView addBuddies:array];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickCreateGroup{
    
}
@end
