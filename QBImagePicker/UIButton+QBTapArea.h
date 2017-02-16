//
//  UIButton+QBTapArea.h
//  Pods
//
//  Created by TCS on 17/2/16.
//
//

#import <UIKit/UIKit.h>

@interface UIButton (QBTapArea)

/**
 *  @brief  设置按钮额外热区
 */
@property (nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@end
