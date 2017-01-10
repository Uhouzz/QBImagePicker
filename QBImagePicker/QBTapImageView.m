//
//  QBTapImageView.m
//  ImagePicker
//
//  Created by TCS on 16/11/9.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import "QBTapImageView.h"

@implementation QBTapImageView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger tapCount = touch.tapCount;
    switch (tapCount) {
        case 1:
            [self handleSingleTap:touch];
            break;
        case 2:
            [self handleDoubleTap:touch];
            break;
        default:
            break;
    }
    [[self nextResponder] touchesEnded:touches withEvent:event];
}

- (void)handleSingleTap:(UITouch *)touch {
    if ([self.delegate respondsToSelector:@selector(imageView:singleTapDetected:)])
        [self.delegate imageView:self singleTapDetected:touch];
}

- (void)handleDoubleTap:(UITouch *)touch {
    if ([self.delegate respondsToSelector:@selector(imageView:doubleTapDetected:)])
        [self.delegate imageView:self doubleTapDetected:touch];
}

@end
