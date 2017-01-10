//
//  QBTapImageView.h
//  ImagePicker
//
//  Created by TCS on 16/11/9.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QBTapImageViewDelegate <NSObject>

@optional

- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch;

@end

@interface QBTapImageView : UIImageView

@property (nonatomic, weak) id<QBTapImageViewDelegate> delegate;

@end
