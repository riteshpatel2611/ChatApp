//
//  XPImageView.h
//  Xplor
//
//  Created by Xplor on 08/09/15.
//  Copyright (c) 2015 Xplor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicType.h"

@protocol XPImageViewDelegate <NSObject>

@optional
- (void)deleteImageDelegateAction:(id)imgView;

@end

@interface XPImageView : UIView
{
#if __has_feature(objc_arc)
    __unsafe_unretained id<XPImageViewDelegate> delegate;
#else
    id<XPImageViewDelegate> delegate;
#endif
}

@property (nonatomic, assign) id <XPImageViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (nonatomic, retain) UIImage *orignalImg;
@property (nonatomic, retain) Buddy *objBuddy;

- (IBAction)deleteAction:(id)sender;
- (void)loadData:(Buddy *)obj;
- (void)redrawImageView;

@end
