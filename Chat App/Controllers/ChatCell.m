
//
//  ChatCell.m
//  XMPPChat
//
//  Created by Amit on 17/10/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import "ChatCell.h"
@implementation ChatCell

@synthesize  delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.imgMessage.userInteractionEnabled = YES;
    self.imgMessage.layer.cornerRadius = 20.0f;
    self.imgMessage.clipsToBounds = YES;
    
    self.lblStatus.hidden   =   YES;
//    self.lblStatus.layer.cornerRadius   =   self.lblStatus.frame.size.width/2;
//    self.lblStatus.clipsToBounds        =   YES;
    
    [self.activityIndicator setBackgroundColor:[UIColor darkGrayColor]];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.layer.cornerRadius = self.activityIndicator.frame.size.width/2;
    
    [self.btnRestart setImage:[UIImage imageNamed:@"download"] forState:UIControlStateSelected];
    [self.btnRestart setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    
    self.imgUser.layer.cornerRadius          = self.imgUser.frame.size.height/2;
    self.imgUser.clipsToBounds               = YES;
    
    self.lblMessage.edgeInsets = UIEdgeInsetsMake(8, 8 , 8, 8);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


@end
