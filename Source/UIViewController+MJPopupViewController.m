//
//  UIViewController+MJPopupViewController.m
//  MJModalViewController
//
//  Created by Martin Juhasz on 11.05.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "UIViewController+MJPopupViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MJPopupBackgroundView.h"
#import <objc/runtime.h>
#import "UIViewController+MJPopupSettings.h"
#define kPopupModalAnimationDuration 0.35
#define kMJPopupViewController @"kMJPopupViewController"
#define kMJPopupBackgroundView @"kMJPopupBackgroundView"
#define kMJPresentingViewController @"kMJPresentingViewController"
#define kMJSourceViewTag 23941
#define kMJPopupViewTag 23942
#define kMJOverlayViewTag 23945

@interface UIViewController (MJPopupViewControllerPrivate)
- (UIView*)topView;
- (void)presentPopupView:(UIView*)popupView;
@end

static NSString *MJPopupViewDismissedKey = @"MJPopupViewDismissed";

////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

@implementation UIViewController (MJPopupViewController)

static void * const keypath = (void*)&keypath;

- (UIViewController*)mj_popupViewController {
    return objc_getAssociatedObject(self, kMJPopupViewController);
}

- (void)setMj_popupViewController:(UIViewController *)mj_popupViewController {
    objc_setAssociatedObject(self, kMJPopupViewController, mj_popupViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (MJPopupBackgroundView*)mj_popupBackgroundView {
    return objc_getAssociatedObject(self, kMJPopupBackgroundView);
}

- (void)setMj_popupBackgroundView:(MJPopupBackgroundView *)mj_popupBackgroundView {
    objc_setAssociatedObject(self, kMJPopupBackgroundView, mj_popupBackgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}
- (UIViewController*)mj_presentingViewController {
    return objc_getAssociatedObject(self, kMJPresentingViewController);
}

- (void)setMj_presentingViewController:(UIViewController *)mj_presentingViewController {
    objc_setAssociatedObject(self, kMJPresentingViewController, mj_presentingViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType dismissed:(void(^)(void))dismissed
{
    self.mj_popupViewController = popupViewController;
    [self presentPopupView:popupViewController.view animationType:animationType dismissed:dismissed];
}

- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePositionWhenKeyboardShown) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePositionWhenKeyboardHiden) name:UIKeyboardWillHideNotification object:nil];
    popupViewController.mj_presentingViewController = self;
    [self presentPopupViewController:popupViewController animationType:animationType dismissed:nil];
}

- (void)dismissPopupViewControllerWithanimationType:(MJPopupViewAnimation)animationType
{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    UIView *sourceView = [self topView];
    UIView *popupView = [sourceView viewWithTag:kMJPopupViewTag];
    UIView *overlayView = [sourceView viewWithTag:kMJOverlayViewTag];
    
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideRightRight:
            [self slideViewOut:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
            
        default:
            [self fadeViewOut:popupView sourceView:sourceView overlayView:overlayView];
            break;
    }
}
-(void)dismissCurrentPopupViewControllerWithanimationType:(MJPopupViewAnimation)animationType{
    NSAssert(self.mj_presentingViewController, @"presenting controller is nil");
    [self.mj_presentingViewController dismissPopupViewControllerWithanimationType:animationType];
}


////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View Handling

- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType
{
    [self presentPopupView:popupView animationType:animationType dismissed:nil];
}

- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType dismissed:(void(^)(void))dismissed
{
    UIView *sourceView = [self topView];
    sourceView.tag = kMJSourceViewTag;
    popupView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    popupView.tag = kMJPopupViewTag;
    
    // check if source view controller is not in destination
    if ([sourceView.subviews containsObject:popupView]) return;
    
    // customize popupView
    if ([self.mj_popupViewController showsShadow]) {
        popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:popupView.bounds].CGPath;
        popupView.layer.masksToBounds = NO;
        popupView.layer.shadowOffset = CGSizeMake(5, 5);
        popupView.layer.shadowRadius = 5;
        popupView.layer.shadowOpacity = 0.5;
        popupView.layer.shouldRasterize = YES;
        popupView.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    }
    
    // Add semi overlay
    UIView *overlayView = [[UIView alloc] initWithFrame:sourceView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.tag = kMJOverlayViewTag;
    overlayView.backgroundColor = [UIColor clearColor];
    
    // BackgroundView
    self.mj_popupBackgroundView = [[MJPopupBackgroundView alloc] initWithFrame:sourceView.bounds];
    self.mj_popupBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mj_popupBackgroundView.backgroundColor = [UIColor clearColor];
    self.mj_popupBackgroundView.alpha = 0.0f;
    [overlayView addSubview:self.mj_popupBackgroundView];
    
    // Make the Background Clickable
    UIButton * dismissButton = nil;
    if ([self.mj_popupViewController autoDismissEnabled]) {
        dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        dismissButton.backgroundColor = [UIColor clearColor];
        dismissButton.frame = sourceView.bounds;
        [overlayView addSubview:dismissButton];
        [dismissButton addTarget:self action:@selector(dismissPopupViewControllerWithanimation:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    popupView.alpha = 0.0f;
    [overlayView addSubview:popupView];
    [sourceView addSubview:overlayView];
    
  
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideRightRight:
            dismissButton.tag = animationType;
            [self slideViewIn:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
        default:
            dismissButton.tag = MJPopupViewAnimationFade;
            [self fadeViewIn:popupView sourceView:sourceView overlayView:overlayView];
            break;
    }
    
    [self setDismissedCallback:dismissed];
}

-(UIView*)topView {
    UIViewController *recentView = self;
    
    while (recentView.parentViewController != nil) {
        recentView = recentView.parentViewController;
    }
    return recentView.view;
}

- (void)dismissPopupViewControllerWithanimation:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* dismissButton = sender;
        switch (dismissButton.tag) {
            case MJPopupViewAnimationSlideBottomTop:
            case MJPopupViewAnimationSlideBottomBottom:
            case MJPopupViewAnimationSlideTopTop:
            case MJPopupViewAnimationSlideTopBottom:
            case MJPopupViewAnimationSlideLeftLeft:
            case MJPopupViewAnimationSlideLeftRight:
            case MJPopupViewAnimationSlideRightLeft:
            case MJPopupViewAnimationSlideRightRight:
                [self dismissPopupViewControllerWithanimationType:dismissButton.tag];
                break;
            default:
                [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                break;
        }
    } else {
        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    }
}

//////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Animations

#pragma mark --- Slide

- (void)slideViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupStartRect;
    
    CGPoint p = [self.mj_popupViewController initialPositionOffset];
    

    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
            popupStartRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                        sourceSize.height,
                                        popupSize.width,
                                        popupSize.height);
            
            break;
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
            popupStartRect = CGRectMake(-sourceSize.width,
                                        (sourceSize.height - popupSize.height) / 2 + p.y,
                                        popupSize.width,
                                        popupSize.height);
            break;
            
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
            popupStartRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                        -popupSize.height,
                                        popupSize.width,
                                        popupSize.height);
            break;
            
        default:
            popupStartRect = CGRectMake(sourceSize.width,
                                        (sourceSize.height - popupSize.height) / 2 + p.y,
                                        popupSize.width,
                                        popupSize.height);
            break;
    }
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                     (sourceSize.height - popupSize.height) / 2 + p.y,
                                     popupSize.width,
                                     popupSize.height);
    
    // Set starting properties
    popupView.frame = popupStartRect;
    popupView.alpha = 1.0f;
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.mj_popupViewController viewWillAppear:NO];
        self.mj_popupBackgroundView.alpha = 1.0f;
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}

- (void)slideViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect;
    CGPoint p = [self.mj_popupViewController initialPositionOffset];
    

    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideTopTop:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                      -popupSize.height,
                                      popupSize.width,
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopBottom:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                      sourceSize.height,
                                      popupSize.width,
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightRight:
            popupEndRect = CGRectMake(sourceSize.width,
                                      popupView.frame.origin.y ,
                                      popupSize.width,
                                      popupSize.height);
            break;
        default:
            popupEndRect = CGRectMake(-popupSize.width,
                                      popupView.frame.origin.y ,
                                      popupSize.width,
                                      popupSize.height);
            break;
    }
    
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.mj_popupViewController viewWillDisappear:NO];
        popupView.frame = popupEndRect;
        self.mj_popupBackgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
        [self.mj_popupViewController viewDidDisappear:NO];
        self.mj_popupViewController = nil;
        
        id dismissed = [self dismissedCallback];
        if (dismissed != nil)
        {
            ((void(^)(void))dismissed)();
            [self setDismissedCallback:nil];
        }
    }];
}

#pragma mark --- Fade

- (void)fadeViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
   //use inset
    CGPoint p = [self.mj_popupViewController initialPositionOffset];
    
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                     (sourceSize.height - popupSize.height) / 2 + p.y,
                                     popupSize.width,
                                     popupSize.height);
    
    // Set starting properties
    popupView.frame = popupEndRect;
    popupView.alpha = 0.0f;
    
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        [self.mj_popupViewController viewWillAppear:NO];
        self.mj_popupBackgroundView.alpha = 0.5f;
        popupView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}

- (void)fadeViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        [self.mj_popupViewController viewWillDisappear:NO];
        self.mj_popupBackgroundView.alpha = 0.0f;
        popupView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
        [self.mj_popupViewController viewDidDisappear:NO];
        self.mj_popupViewController = nil;
        
        id dismissed = [self dismissedCallback];
        if (dismissed != nil)
        {
            ((void(^)(void))dismissed)();
            [self setDismissedCallback:nil];
        }
    }];
}

#pragma mark Change Popup Position

- (void)changePositionWhenKeyboardShown
{
    if ([self.mj_popupViewController popupOffset] == 0)
    {
        return;
    }
    // Generating Start and Stop Positions
    UIView* popupView = self.mj_popupViewController.view;
    UIView *sourceView = [self topView];
    CGPoint p = [self.mj_popupViewController initialPositionOffset];
    

    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                     (sourceSize.height - popupSize.height) / 2 + p.y,
                                     popupSize.width,
                                     popupSize.height);
    popupEndRect.origin.y -= self.mj_popupViewController.popupOffset;
    // Set starting properties
    
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        [self.mj_popupViewController viewWillAppear:NO];
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}
- (void)changePositionWhenKeyboardHiden
{
    if ([self.mj_popupViewController popupOffset] == 0)
    {
        return;
    }
    // Generating Start and Stop Positions
    UIView* popupView = self.mj_popupViewController.view;
    UIView *sourceView = [self topView];
    CGPoint p = [self.mj_popupViewController initialPositionOffset];
    

    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2 + p.x,
                                     (sourceSize.height - popupSize.height) / 2 + p.y,
                                     popupSize.width,
                                     popupSize.height);
    // Set starting properties
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        [self.mj_popupViewController viewWillAppear:NO];
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}


#pragma mark -
#pragma mark Category Accessors

#pragma mark --- Dismissed

- (void)setDismissedCallback:(void(^)(void))dismissed
{
    objc_setAssociatedObject(self, &MJPopupViewDismissedKey, dismissed, OBJC_ASSOCIATION_RETAIN);
}

- (void(^)(void))dismissedCallback
{
    return objc_getAssociatedObject(self, &MJPopupViewDismissedKey);
}

@end
