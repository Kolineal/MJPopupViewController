//
//  UIViewController+UIViewController_MJPopupSettings.m
//  MJPopupViewControllerDemo
//
//  Created by  Igor Cherepanov on 7/24/14.
//
//

#import "UIViewController+MJPopupSettings.h"
#import <objc/runtime.h>

@implementation UIViewController (MJPopupSettings)
-(BOOL)showsShadow{
    id number = objc_getAssociatedObject(self, @"showsShadow");
    if (number) {
        int result = [(NSNumber *)number intValue];
        if (result == 1) {
            return YES;
        }
        if (result == 0) {
            return NO;
        }
    }
    return YES;
}
-(BOOL)autoDismissEnabled{
    id number = objc_getAssociatedObject(self, @"autoDismissEnabled");
    if (number) {
        int result = [(NSNumber *)number intValue];
        if (result == 1) {
            return YES;
        }
        if (result == 0) {
            return NO;
        }
    }
   
    return YES;
}

-(void)setAutoDismissEnabled:(BOOL)autoDismissEnabled{
    objc_setAssociatedObject(self, @"autoDismissEnabled", [NSNumber numberWithBool:autoDismissEnabled], OBJC_ASSOCIATION_RETAIN);
}
-(void)setShowsShadow:(BOOL)showsShadow{
    objc_setAssociatedObject(self, @"showsShadow", [NSNumber numberWithBool:showsShadow], OBJC_ASSOCIATION_RETAIN);

}
@end
