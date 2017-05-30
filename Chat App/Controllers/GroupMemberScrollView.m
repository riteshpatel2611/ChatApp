//
//  AddPhotoScrollView.m
//  Xplor
//
//  Created by BT129-1 on 23/08/2016.
//  Copyright © 2016 Appster. All rights reserved.
//

#import "GroupMemberScrollView.h"

@interface GroupMemberScrollView()
{
    BOOL videoAdded;
}
@end
@implementation GroupMemberScrollView

- (void)initViewForImages:(id)controller
{
    self.scrollViewDelegate = controller;
}

- (void)addBuddies:(NSArray *)arrayImages
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    CGFloat xPOS    =   0.0;
    
    for (Buddy *obj in arrayImages)
    {
        
        NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"XPImageView" owner:self options:nil];
        XPImageView *imgXPView = (XPImageView*)[arr objectAtIndex:0];
        imgXPView.delegate = self;
        [imgXPView redrawImageView];
        imgXPView.tag = self.subviews.count;
        [imgXPView loadData:obj];
        [imgXPView setFrame:CGRectMake(xPOS, 0, self.frame.size.height, self.frame.size.height)];
        [self addSubview:imgXPView];
        
        xPOS    =   xPOS + self.frame.size.height + 0;
    }
    
    [self setContentOffset:CGPointMake(arrayImages.count * self.frame.size.height,self.frame.size.height) animated:YES];
    [self setContentSize:CGSizeMake(xPOS + self.frame.size.height , 0)];
}

- (void)addBuddy:(Buddy *)buddyObj
{
    CGFloat xPOS    =   0.0;
        
    NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"XPImageView" owner:self options:nil];
    XPImageView *imgXPView = (XPImageView*)[arr objectAtIndex:0];
    imgXPView.delegate = self;
    [imgXPView redrawImageView];
    imgXPView.tag = self.subviews.count;
    [imgXPView loadData:buddyObj];
    [imgXPView setFrame:CGRectMake(xPOS, 0, self.frame.size.height, self.frame.size.height)];
    [self addSubview:imgXPView];

    [self resetImageCollection];
}

#pragma mark - Add Multiple Image
- (void)resetImageCollection {
    
    XPImageView *imgXPView = nil;
    
    int tag = 0;
    
    CGFloat xPOS    =   0.0;
    
    for (XPImageView *tmp in self.subviews)
    {
        if (![tmp isKindOfClass:[XPImageView class]]) {
            continue;
        }
        tmp.tag = tag;
        tag++;
        
        imgXPView = tmp;
        [tmp setFrame:CGRectMake(xPOS, 0, self.frame.size.height, self.frame.size.height)];
        
        xPOS    =   xPOS + self.frame.size.height + 0;
    }
    
}



#pragma mark - XPImageViewDelegate Method
- (void)deleteImageDelegateAction:(id)imgView {
    
    XPImageView *tmpView = (XPImageView *)imgView;
   
    [tmpView removeFromSuperview];
    [self resetImageCollection];
    
    if ([self.scrollViewDelegate conformsToProtocol:@protocol(GroupMemberScrollViewDelegate)]) {
        if ([self.scrollViewDelegate respondsToSelector:@selector(deleteBuddy:atIndex:)])
        {
            [self.scrollViewDelegate deleteBuddy:tmpView.objBuddy atIndex:tmpView.tag];
            
        }
        if ([self.scrollViewDelegate respondsToSelector:@selector(didCompleteWithAction:)])
        {
            if(self.subviews.count > 1)
                [self.scrollViewDelegate didCompleteWithAction:IMAGE_DELETED];
            else
                [self.scrollViewDelegate didCompleteWithAction:ALL_DELETED];
            
        }
    }
}

@end
