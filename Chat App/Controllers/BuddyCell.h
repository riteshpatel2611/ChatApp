//
//  BuddyCell.h
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BuddyCell : UITableViewCell
@property (weak, nonatomic) IBOutlet ChatAsyncImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *lblName;

@end
