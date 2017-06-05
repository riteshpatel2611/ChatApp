//
//  GroupDetailCell.h
//  Chat App
//
//  Created by Fxbytes on 6/5/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupDetailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet ChatAsyncImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblSubtitle;
@property (weak, nonatomic) IBOutlet UIButton *btnAccessary;

@end
