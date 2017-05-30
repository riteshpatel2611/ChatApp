//
//  TutorialViewController.m
//  Chat App
//
//  Created by Fxbytes on 5/17/17.
//  Copyright © 2017 Fxbytes. All rights reserved.
//

#import "TutorialViewController.h"
#import "CommonMacros.h"
@interface TutorialViewController ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *mScrollView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblSubtitle;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControll;

@property (nonatomic, strong) NSArray *arrayTutorial;
@end

@implementation TutorialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController setNavigationBarHidden:YES];
    
    NSDictionary *dic1  = @{@"image"     :       [UIImage imageNamed:@"Tutorial_chat"],
                            @"title"     :       @"Chat",
                            @"subtitle"  :       @"Keep in touch with old and new\n friends, chitchat with them"
                            };
    
    NSDictionary *dic2  = @{@"image"     :       [UIImage imageNamed:@"Tutorial_share"],
                            @"title"     :       @"Share",
                            @"subtitle"  :       @"Share photo, video, audio and\neverything you want"
                            };

    
    NSDictionary *dic3  = @{@"image"     :       [UIImage imageNamed:@"Tutorial_group"],
                            @"title"     :       @"Group Chat",
                            @"subtitle"  :       @"Use group chat to organize\n meetings with friends"
                            };
    
    _arrayTutorial      = @[dic1, dic2, dic3];
    
    for(int i = 0; i<_arrayTutorial.count; i++){
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(DEVICE_WIDTH * i, 0, DEVICE_WIDTH, 163.0f)];
        imageView.image        = [_arrayTutorial[i] valueForKey:@"image"];
        imageView.contentMode  = UIViewContentModeScaleAspectFit;
        [_mScrollView addSubview:imageView];
    }
    
    _mScrollView.contentOffset = CGPointMake(0, 0);
    
    _mScrollView.contentSize = CGSizeMake(DEVICE_WIDTH * _arrayTutorial.count, 163.0f);
    _pageControll.numberOfPages = _arrayTutorial.count;
    
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    gesture.delegate = self;
    [self.view addGestureRecognizer:gesture];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    NSInteger page = round(self.mScrollView.contentOffset.x/self.mScrollView.frame.size.width);
    self.pageControll.currentPage = page;
    
    _lblTitle.text      =   [[_arrayTutorial objectAtIndex:page] valueForKey:@"title"];
    _lblSubtitle.text   =   [[_arrayTutorial objectAtIndex:page] valueForKey:@"subtitle"];
    
}

- (IBAction)onClickSkip:(id)sender {
}

- (void)swipeLeft:(id)sender{
    
    NSInteger prevIndex = self.pageControll.currentPage + 1;
    if(prevIndex >= 0){
        [self.mScrollView scrollRectToVisible:CGRectMake(DEVICE_WIDTH * prevIndex, 0, DEVICE_WIDTH, 163.0f) animated:YES];
    }
    
}

- (void)swipeRight:(id)sender{
    
    NSInteger nextIndex = self.pageControll.currentPage - 1;
    if(nextIndex <= 2){
        [self.mScrollView scrollRectToVisible:CGRectMake(DEVICE_WIDTH * nextIndex, 0, DEVICE_WIDTH, 163.0f) animated:YES];
    }
}

- (void)handleGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    
    if(velocity.x > 0)
    {
        NSLog(@"gesture moving right");
        [self swipeRight:nil];
    }
    else
    {
        NSLog(@"gesture moving left");
        [self swipeLeft:nil];
    }
    
    if(velocity.y > 0)
    {
        NSLog(@"gesture moving Up");
    }
    else
    {
        NSLog(@"gesture moving Bottom");
    }
    
}
@end
