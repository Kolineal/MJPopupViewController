//
//  UIViewController+UIViewController_MJPopupSettings.h
//  MJPopupViewControllerDemo
//
//  Created by  Igor Cherepanov on 7/24/14.
//
//

#import <UIKit/UIKit.h>
/*
 DON'T IMPORT TO VIEVCONTROLLERS THAT USE MJPopupViewController
 */
@interface UIViewController (MJPopupSettings)

- (BOOL)showsShadow;
- (void)setShowsShadow:(BOOL)showsShadow;

- (BOOL)autoDismissEnabled;
- (void)setAutoDismissEnabled:(BOOL)autoDismissEnabled;

- (float)popupOffset;
- (void)setPopupOffest:(float)popupOffset;

@end
