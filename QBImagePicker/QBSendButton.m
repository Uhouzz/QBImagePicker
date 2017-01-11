//
//  QBSendButton.m
//  ImagePicker
//
//  Created by TCS on 16/11/9.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import "QBSendButton.h"

#import "UIView+QBImagePicker.h"
#import "UIColor+QBColorHex.h"

static NSString *const kSendButtonTintNormalColor = @"#FF5A5F";
static NSString *const kSendButtonTintAbnormalColor = @"#FF5A5F";

static CGFloat const kSendButtonTextWitdh = 38.0f;

@interface QBSendButton ()

@property (nonatomic, strong) UILabel *badgeValueLabel;
@property (nonatomic, strong) UIView *backGroudView;
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation QBSendButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = CGRectMake(0, 0, 58, 26);
        [self initSubViews];
        self.badgeValue = @"0";
    }
    return self;
}

- (void) initSubViews {
    UIView *backGroudView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    backGroudView.centerY = self.centerY;
    backGroudView.backgroundColor = [UIColor hexStringToColor:kSendButtonTintNormalColor];
    backGroudView.layer.cornerRadius = backGroudView.height/2;
    [self addSubview:backGroudView];
    self.backGroudView = backGroudView;
    
    UILabel *badgeValueLabel = [[UILabel alloc] initWithFrame:_backGroudView.frame];
    badgeValueLabel.backgroundColor = [UIColor clearColor];
    badgeValueLabel.textColor = [UIColor whiteColor];
    badgeValueLabel.font = [UIFont systemFontOfSize:15.0f];
    badgeValueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:badgeValueLabel];
    self.badgeValueLabel  =badgeValueLabel;
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.frame = CGRectMake(0, 0, self.width, self.height);
    [sendButton setTitle:@"完成" forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor hexStringToColor:kSendButtonTintNormalColor] forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor hexStringToColor:kSendButtonTintAbnormalColor] forState:UIControlStateHighlighted];
    [sendButton setTitleColor:[UIColor hexStringToColor:kSendButtonTintAbnormalColor] forState:UIControlStateDisabled];
    sendButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    sendButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    sendButton.backgroundColor = [UIColor clearColor];
    [self addSubview:sendButton];
    self.sendButton = sendButton;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self.sendButton setTitle:title forState:UIControlStateNormal];
}

- (void)setBadgeValue:(NSString *)badgeValue {
    _badgeValue = badgeValue;

    CGSize size = [badgeValue boundingRectWithSize:CGSizeMake(MAXFLOAT, 20)
                                           options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                        attributes:@{NSFontAttributeName:self.badgeValueLabel.font}
                                           context:nil].size;
    
    self.badgeValueLabel.frame = CGRectMake(self.badgeValueLabel.left, self.badgeValueLabel.top, (size.width + 9) > 20 ? (size.width + 9):20, 20);
    self.backGroudView.width = self.badgeValueLabel.width;
    self.backGroudView.height = self.badgeValueLabel.height;
    
    CGFloat width = [self.sendButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}].width;
    
    self.sendButton.width = self.badgeValueLabel.width + width + 5;
    self.width = self.sendButton.width;
    
    self.badgeValueLabel.text = badgeValue;
    
    if (badgeValue.integerValue > 0) {
        [self showBadgeValue];
        self.backGroudView.transform =CGAffineTransformMakeScale(0, 0);
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:2 options:0 animations:^{
            self.backGroudView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
        }];
    } else {
        [self hideBadgeValue];
    }
}

- (void) showBadgeValue {
    self.badgeValueLabel.hidden = NO;
    self.backGroudView.hidden = NO;
}

- (void) hideBadgeValue {
    self.badgeValueLabel.hidden = YES;
    self.backGroudView.hidden = YES;
    self.sendButton.adjustsImageWhenDisabled = YES;
}

- (void)addTaget:(id)target action:(SEL)action {
    [self.sendButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end
