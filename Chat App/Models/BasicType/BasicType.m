//
//  BasicType.m
//  XMPPChat
//
//  Created by Xplor on 10/17/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#import "BasicType.h"

@implementation BasicType

- (NSString *)name {
    
    return (self.displayName.length > 0 ? self.displayName : self.accountName);
}

- (NSString *)accountNameChat {
    
    return (self.accountName.length > 0 ? self.accountName : self.displayName);
}


@end

@implementation Buddy

- (BuddyStatus)getStatus {
    
    return self.status;
}

@end

@implementation Group

@end