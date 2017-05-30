//
//  BuddyListManager.m
//  XMPPChat


#import "BuddyListManager.h"

@interface BuddyListManager ()

@property (nonatomic, strong) NSMutableDictionary *allBuddies;

@end

@implementation BuddyListManager

+(instancetype)sharedBuddyListManager {
    
    static BuddyListManager* sharedBuddyListManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBuddyListManager = [[BuddyListManager alloc] init];
        sharedBuddyListManager.allBuddies = [[NSMutableDictionary alloc] init];
        sharedBuddyListManager.onlineBuddies = [[NSArray alloc] init];
    });
    
    return sharedBuddyListManager;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)addBuddy:(Buddy *)buddy {
    
}
@end
