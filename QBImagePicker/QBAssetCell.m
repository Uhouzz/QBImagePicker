//
//  QBAssetCell.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCell.h"

@interface QBAssetCell ()

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *checkButton;

@end

@implementation QBAssetCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.checkButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.checkButton setImage:[UIImage imageNamed:@"QBImage.bundle/icon_selected_gray.png"] forState:UIControlStateNormal];
    [self.checkButton setImage:[UIImage imageNamed:@"QBImage.bundle/icon_selected.png"] forState:UIControlStateSelected];
}

- (void)setMultiSelected:(BOOL)multiSelected {
    _multiSelected = multiSelected;
    self.checkButton.hidden = !multiSelected;
}

- (void)setImageSelected:(BOOL)imageSelected {
    _imageSelected = imageSelected;
    self.checkButton.selected = _imageSelected;
    
    [self updateCheckImageView];
}

- (void)updateCheckImageView {
    if (self.checkButton.selected) {
        self.checkButton.imageView.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:2 options:0 animations:^{
            self.checkButton.imageView.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
        }];
    }
}

- (IBAction)checkButtonAction:(id)sender
{
    if (self.checkButton.selected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didDeselectItemWithCell:)]) {
            [self.delegate didDeselectItemWithCell:self];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectItemWithCell:)]) {
            [self.delegate didSelectItemWithCell:self];
        }
    }
}


@end
