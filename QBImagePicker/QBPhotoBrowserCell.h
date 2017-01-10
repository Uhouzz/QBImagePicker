//
//  QBPhotoBrowserCell.h
//  Pods
//
//  Created by TCS on 16/11/4.
//
//

#import <UIKit/UIKit.h>
#import <Photos/PHAsset.h>
#import "QBPhotoBrowser.h"

static NSString *const QBPhotoBrowserCellIdentifier = @"QBPhotoBrowserCellIdentifier";

@interface QBPhotoBrowserCell : UICollectionViewCell

@property (nonatomic, weak) QBPhotoBrowser *photoBrowser;

- (void) configureCellWithAsset:(PHAsset *)asset;

@end
