//
//  QBAssetCell.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QBVideoIndicatorView;
@class QBAssetCell;

@protocol QBAssetCellDelegate <NSObject>
@optional
- (void)didSelectItemWithCell:(QBAssetCell *)assetCell;
- (void)didDeselectItemWithCell:(QBAssetCell *)assetCell;

@end


@interface QBAssetCell : UICollectionViewCell

@property (nonatomic, weak) id<QBAssetCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet QBVideoIndicatorView *videoIndicatorView;

@property (nonatomic, assign) BOOL multiSelected;

@property (nonatomic, assign) BOOL imageSelected;



@end
