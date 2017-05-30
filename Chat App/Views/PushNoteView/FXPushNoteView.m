//
//  FXPushNoteView.m


#import "FXPushNoteView.h"

#define APP [UIApplication sharedApplication].delegate
//#define isIOS7 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
#define PUSH_VIEW [FXPushNoteView sharedPushView]

#define CLOSE_PUSH_SEC 5
#define SHOW_ANIM_DUR 0.5
#define HIDE_ANIM_DUR 0.35

@interface FXPushNoteView()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (strong, nonatomic) NSTimer *closeTimer;
@property (strong, nonatomic) NSString *currentMessage;
@property (strong, nonatomic) NSMutableArray *pendingPushArr;

@property (strong, nonatomic) void (^messageTapActionBlock)(NSString *message);
@property (strong, nonatomic) void (^messageSwipeActionBlock)(NSString *message);

@end


@implementation FXPushNoteView

//Singleton instance
static FXPushNoteView *_sharedPushView;

+ (instancetype)sharedPushView
{
	@synchronized([self class])
	{
		if (!_sharedPushView){
            NSArray *nibArr = [[NSBundle mainBundle] loadNibNamed: @"FXPushNoteView" owner:self options:nil];
            for (id currentObject in nibArr)
            {
                if ([currentObject isKindOfClass:[FXPushNoteView class]])
                {
                    _sharedPushView = (FXPushNoteView *)currentObject;
                    break;
                }
            }
            [_sharedPushView setUpUI];
		}
		return _sharedPushView;
	}
	// to avoid compiler warning
	return nil;
}

+ (void)setDelegateForPushNote:(id<AGPushNoteViewDelegate>)delegate {
    [PUSH_VIEW setPushNoteDelegate:delegate];
}

#pragma mark - Lifecycle (of sort)
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect f = self.frame;
        CGFloat width = [UIApplication sharedApplication].keyWindow.bounds.size.width;
        self.frame = CGRectMake(f.origin.x, f.origin.y, width, f.size.height);
    }
    return self;
}

- (void)setUpUI {
    CGRect f = self.frame;
    CGFloat width = [UIApplication sharedApplication].keyWindow.bounds.size.width;
    CGFloat height = f.size.height;// isIOS7? 54:
    
    self.frame = CGRectMake(f.origin.x, -height, width, height);
    CGRect cvF = self.frame;
    self.frame = CGRectMake(cvF.origin.x, cvF.origin.y, self.frame.size.width, self.frame.size.height);
    
    //OS Specific:
//    if (isIOS7) {
//        self.barTintColor = nil;
//        self.translucent = YES;
    
//    } else {
    
//        [self setBackgroundColor:[UIColor colorWithRed:5 green:31 blue:75 alpha:0.8]];
        [self.messageLabel setTextAlignment:NSTextAlignmentLeft];
//    }
    
    self.layer.zPosition = CGFLOAT_MAX;
    self.multipleTouchEnabled = NO;
    self.exclusiveTouch = YES;
    
    UITapGestureRecognizer *msgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageTapAction)];
    self.messageLabel.userInteractionEnabled = YES;
    [self.messageLabel addGestureRecognizer:msgTap];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(messageSwipeAction:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    self.messageLabel.userInteractionEnabled = YES;
    [self.messageLabel addGestureRecognizer:swipe];
    
    
    //:::[For debugging]:::
    //            self.containerView.backgroundColor = [UIColor yellowColor];
    //            self.closeButton.backgroundColor = [UIColor redColor];
    //            self.messageLabel.backgroundColor = [UIColor greenColor];
    
    [APP.window addSubview:PUSH_VIEW];
}

+ (void)awake {
    if (PUSH_VIEW.frame.origin.y == 0) {
        [APP.window addSubview:PUSH_VIEW];
    }
}

+ (void)showWithNotificationMessage:(NSString *)message {
    PUSH_VIEW.hidden = NO;
    
    [FXPushNoteView showWithNotificationMessage:message completion:^{
        //Nothing.
    }];
}

+ (void)showWithNotificationMessage:(NSString *)message completion:(void (^)(void))completion {
    
    PUSH_VIEW.currentMessage = message;

    if (message) {
        [PUSH_VIEW.pendingPushArr addObject:message];
        PUSH_VIEW.messageLabel.numberOfLines = 0;
        PUSH_VIEW.messageLabel.text = message;
        APP.window.windowLevel = UIWindowLevelStatusBar;
        
        CGRect f = PUSH_VIEW.frame;
        
        CGFloat labelHeight = [self getLabelHeight:PUSH_VIEW.messageLabel];
        
        PUSH_VIEW.frame = CGRectMake(f.origin.x, -labelHeight, f.size.width, labelHeight);
        [APP.window addSubview:PUSH_VIEW];
        
        //Show
        [UIView animateWithDuration:SHOW_ANIM_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect f = PUSH_VIEW.frame;
            PUSH_VIEW.frame = CGRectMake(f.origin.x, 0, f.size.width, f.size.height);
        } completion:^(BOOL finished) {
            completion();
            if ([PUSH_VIEW.pushNoteDelegate respondsToSelector:@selector(pushNoteDidAppear)]) {
                [PUSH_VIEW.pushNoteDelegate pushNoteDidAppear];
            }
        }];
        
        //Start timer (Currently not used to make sure user see & read the push...)
        PUSH_VIEW.closeTimer = [NSTimer scheduledTimerWithTimeInterval:CLOSE_PUSH_SEC target:[FXPushNoteView class] selector:@selector(close) userInfo:nil repeats:NO];
    }
}

+ (CGFloat)getLabelHeight:(UILabel*)label
{
    CGSize constraint = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));

    if(size.height<30.0f)
        return 64.0f;
    else if(size.height>90.0f)
        return 110.0f;
    else
        return size.height;
}

+ (void)closeWitCompletion:(void (^)(void))completion {
    if ([PUSH_VIEW.pushNoteDelegate respondsToSelector:@selector(pushNoteWillDisappear)]) {
        [PUSH_VIEW.pushNoteDelegate pushNoteWillDisappear];
    }
    
    [PUSH_VIEW.closeTimer invalidate];
    
    [UIView animateWithDuration:HIDE_ANIM_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect f = PUSH_VIEW.frame;
        PUSH_VIEW.frame = CGRectMake(f.origin.x, -f.size.height, f.size.width, f.size.height);
    } completion:^(BOOL finished) {
        [PUSH_VIEW handlePendingPushJumpWitCompletion:completion];
    }];
}

+ (void)close {
    [FXPushNoteView closeWitCompletion:^{
        //Nothing.
    }];
}

+ (void)swipeWitCompletion:(void (^)(void))completion {
    if ([PUSH_VIEW.pushNoteDelegate respondsToSelector:@selector(pushNoteWillDisappear)]) {
        [PUSH_VIEW.pushNoteDelegate pushNoteWillDisappear];
    }
    
    [PUSH_VIEW.closeTimer invalidate];
    
    CGRect f = PUSH_VIEW.frame;
    [UIView animateWithDuration:HIDE_ANIM_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        PUSH_VIEW.frame = CGRectMake(f.origin.x+f.size.width, f.origin.y, f.size.width, f.size.height);
    } completion:^(BOOL finished) {
        PUSH_VIEW.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, f.size.height);
        PUSH_VIEW.hidden = YES;
        [PUSH_VIEW handlePendingPushJumpWitCompletion:completion];
    }];
}

+ (void)swipe {
    [FXPushNoteView swipeWitCompletion:^{
        //Nothing.
    }];
}

#pragma mark - Pending push managment
- (void)handlePendingPushJumpWitCompletion:(void (^)(void))completion {
    id lastObj = [self.pendingPushArr lastObject]; //Get myself
    if (lastObj) {
        [self.pendingPushArr removeObject:lastObj]; //Remove me from arr
        NSString *messagePendingPush = [self.pendingPushArr lastObject]; //Maybe get pending push
        if (messagePendingPush) { //If got something - remove from arr, - than show it.
            [self.pendingPushArr removeObject:messagePendingPush];
//            [FXPushNoteView showWithNotificationMessage:messagePendingPush completion:completion];        // to prevent repeating alerts
        } else {
            APP.window.windowLevel = UIWindowLevelNormal;
        }
    }
}

- (NSMutableArray *)pendingPushArr {
    if (!_pendingPushArr) {
        _pendingPushArr = [[NSMutableArray alloc] init];
    }
    return _pendingPushArr;
}

#pragma mark - Actions
+ (void)setMessageAction:(void (^)(NSString *message))action {
    PUSH_VIEW.messageTapActionBlock = action;
    PUSH_VIEW.messageSwipeActionBlock = action;
}

- (void)messageTapAction {
    if (self.messageTapActionBlock) {
        self.messageTapActionBlock(self.currentMessage);
        [FXPushNoteView close];
    }
}

- (void)messageSwipeAction:(UIGestureRecognizer *)recognizer
{
    
    if (self.messageSwipeActionBlock) {
//        self.messageSwipeActionBlock(self.currentMessage);
        [FXPushNoteView swipe];
    }
}
- (IBAction)closeActionItem:(UIBarButtonItem *)sender {
    [FXPushNoteView close];
}


@end
