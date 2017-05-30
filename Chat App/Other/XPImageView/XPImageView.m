//
//  XPImageView.m
//  Xplor
//
//  Created by Xplor on 08/09/15.
//  Copyright (c) 2015 Xplor. All rights reserved.
//

#import "XPImageView.h"

@implementation XPImageView

@synthesize delegate, orignalImg, objBuddy;

#pragma mark - Delete Image
- (IBAction)deleteAction:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(deleteImageDelegateAction:)]) {
        [self.delegate deleteImageDelegateAction:self];
    }
}

- (void)loadData:(Buddy *)obj {

    if (self.objBuddy != nil) {
        self.objBuddy = nil;
    }
    self.objBuddy = obj;
    self.lblName.text = obj.name;
    [self.imgView setImageURL:[NSURL URLWithString:obj.profileImageURL]];
}

#pragma mark - Other Method
- (void)redrawImageView {
    
    self.imgView.clipsToBounds = YES;
    self.imgView.layer.cornerRadius = self.imgView.bounds.size.width/2;
}

@end
