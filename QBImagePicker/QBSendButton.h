//
//  QBSendButton.h
//  ImagePicker
//
//  Created by TCS on 16/11/9.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QBSendButton : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *badgeValue;

- (void)addTaget:(id)target action:(SEL)action;

@end
