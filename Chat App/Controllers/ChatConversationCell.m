//
//  ChatConversationCell.m
//  Chat App
//
//  Created by Fxbytes on 5/19/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "ChatConversationCell.h"

@implementation ChatConversationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.lblCount.layer.cornerRadius = self.lblCount.frame.size.width/2;
    self.lblCount.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
