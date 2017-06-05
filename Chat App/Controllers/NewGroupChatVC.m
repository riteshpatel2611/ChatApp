//
//  NewGroupChatVC.m
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "NewGroupChatVC.h"
#import "BuddyCell.h"
#import "CreateGroupViewController.h"
@interface NewGroupChatVC ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *arraySelected;
@end

@implementation NewGroupChatVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    UIBarButtonItem *btnMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];
    UIBarButtonItem *btnNewChat = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onClickDone)];
//    [self.navigationItem setLeftBarButtonItem:btnMenu];
    [self.navigationItem setRightBarButtonItem:btnNewChat];
    
    self.title = @"Add Members";
    
    _arraySelected = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickDone{
    if(_arraySelected.count){
        
        CreateGroupViewController *nextVC = [STORYBOARD instantiateViewControllerWithIdentifier:@"SBID_CreateGroupViewController"];
        [self.navigationController showViewController:nextVC sender:self];
    }else{
        showAlertWithTitleWithoutAction(ALERT_VIEW_TITLE, ALERT_MESSAGE_EMPTYBUDDYLISTSELECTION, ALERT_BUTTON_TITLE_OK);
    }
   
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BuddyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BuddyCell" forIndexPath:indexPath];
    
    UIImageView *imageViewAccessary = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageViewAccessary.image = [UIImage imageNamed:@"uncheck"];
    cell.accessoryView = imageViewAccessary;
    
    if(indexPath.row == 0){
        cell.lblName.text = @"Andrew Lamrock";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }else if(indexPath.row == 1){
        cell.lblName.text = @"John Doe";
        cell.imgView.image = [UIImage imageNamed:@"user"];
    }else if(indexPath.row == 2){
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
    
    BuddyCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIImageView *accessaryImageView = (UIImageView *)cell.accessoryView;
    if (accessaryImageView.tag == 1) {
        accessaryImageView.tag = 0;
        accessaryImageView.image= [UIImage imageNamed:@"uncheck"];
        [_arraySelected removeObject:cell.lblName.text];
    } else {
        accessaryImageView.tag = 1;
        accessaryImageView.image= [UIImage imageNamed:@"check"];
        
        [_arraySelected addObject:cell.lblName.text];
    }
    
    [self showSelectedCount:_arraySelected.count];
}

-(void)showSelectedCount:(NSInteger)count{
    
    NSString *title = @"Add Member";
    NSString *countSring = [NSString stringWithFormat:@"\n%ld/6", (long)count];
    NSString *titleString = [NSString stringWithFormat:@"%@  %@",title,countSring];
    
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName: [UIColor whiteColor],
                                 NSFontAttributeName: [UIFont fontWithName:FONT_ROBOTO_REGULAR size:16]
                                 };
    
    NSMutableAttributedString *attributedText =[[NSMutableAttributedString alloc] initWithString:titleString attributes:attributes];
    
    // name text attributes
    UIColor *titleColor = [UIColor whiteColor];
    UIFont *titleFont = [UIFont fontWithName:FONT_ROBOTO_BOLD size:18.0];
    
    NSRange nameTextRange = [titleString rangeOfString:title];
    
    [attributedText setAttributes:@{NSForegroundColorAttributeName:titleColor,
                                    NSFontAttributeName:titleFont}
                            range:nameTextRange];
    
    
    // Date text attributes
    UIColor *countColor = [UIColor MyColor:51 green:49 blue:32 opacity:1.0];
    UIFont *countFont = [UIFont fontWithName:FONT_ROBOTO_BOLD size:18.0];
    
    NSRange dateTextRange = [titleString rangeOfString:countSring];
    
    [attributedText setAttributes:@{NSForegroundColorAttributeName:countColor,
                                    NSFontAttributeName:countFont}
                            range:dateTextRange];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.numberOfLines = 2;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.attributedText = attributedText;
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
}

@end
