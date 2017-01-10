//
//  UIColor+QBColorHex.h
//  Pods
//
//  Created by TCS on 17/1/3.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (QBColorHex)

+ (UIColor *)hexStringToColor:(NSString *)stringToConvert;
+ (UIColor *)colorWithHexNumber:(NSUInteger)hexColor;

@end
