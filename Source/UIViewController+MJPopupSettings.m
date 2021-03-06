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
        return [number boolValue];
    }
    return YES;
}
-(BOOL)autoDismissEnabled{
    id number = objc_getAssociatedObject(self, @"autoDismissEnabled");
    if (number) {
        return [number boolValue];
    }
   
    return YES;
}
- (float)popupOffset{
    id number = objc_getAssociatedObject(self, @"popupOffset");
    if (number)
        return [number floatValue];
    else
        return 0.0f;
}
-(CGPoint)initialPositionOffset{
    id value = objc_getAssociatedObject(self, @"initialPositionOffset");
    if (value) {
        CGPoint result = [(NSValue *)value CGPointValue];
        return result;
    }
    
    return CGPointZero;
}
-(void)setAutoDismissEnabled:(BOOL)autoDismissEnabled{
    objc_setAssociatedObject(self, @"autoDismissEnabled", [NSNumber numberWithBool:autoDismissEnabled], OBJC_ASSOCIATION_RETAIN);
}
-(void)setShowsShadow:(BOOL)showsShadow{
    objc_setAssociatedObject(self, @"showsShadow", [NSNumber numberWithBool:showsShadow], OBJC_ASSOCIATION_RETAIN);
}
-(void)setPopupOffest:(float)popupOffset{
    objc_setAssociatedObject(self, @"popupOffset", [NSNumber numberWithFloat:popupOffset],  OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(void)setInitialPositionOffset:(CGPoint)initialOffset{
    objc_setAssociatedObject(self, @"initialPositionOffset", [NSValue valueWithCGPoint:initialOffset], OBJC_ASSOCIATION_RETAIN);

}
@end
