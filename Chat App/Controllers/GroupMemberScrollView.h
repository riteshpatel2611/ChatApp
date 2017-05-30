//
//  AddPhotoScrollView.h
//  Xplor
//
//  Created by BT129-1 on 23/08/2016.
//  Copyright © 2016 Appster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XPImageView.h"

#define IMAGES_COMPLETE     101
#define VIDEO_ADDED         102
#define IMAGE_ADDED         103
#define IMAGE_DELETED       104
#define ALL_DELETED         105

@protocol GroupMemberScrollViewDelegate <NSObject>

- (void)addNewImageInPost;
- (void)deleteBuddy:(Buddy *)buddyObj atIndex:(int)index;
- (void)didCompleteWithAction:(NSInteger)action;
@end

@interface GroupMemberScrollView : UIScrollView<UIScrollViewDelegate, XPImageViewDelegate>

- (void)initViewForImages:(id)controller;
- (void)addBuddies:(NSArray *)arrayImages;
- (void)addBuddy:(Buddy *)buddyObj;
@property (nonatomic, weak)id<GroupMemberScrollViewDelegate>scrollViewDelegate;

@end
