//
//  QBPhotoBrowser.h
//  Pods
//
//  Created by TCS on 16/11/4.
//
//

#import <UIKit/UIKit.h>
#import <Photos/PHAsset.h>

@class QBPhotoBrowser;
@class QBImagePickerController;

@protocol QBPhotoBrowserDelegate <NSObject>

@optional
- (void)sendImagesFromPhotobrowser:(QBPhotoBrowser *)photoBrowse currentAsset:(PHAsset *)asset;
- (NSUInteger)seletedPhotosNumberInPhotoBrowser:(QBPhotoBrowser *)photoBrowser;
- (BOOL)photoBrowser:(QBPhotoBrowser *)photoBrowser currentPhotoAssetIsSeleted:(PHAsset *)asset;
- (BOOL)photoBrowser:(QBPhotoBrowser *)photoBrowser seletedAsset:(PHAsset *)asset;
- (void)photoBrowser:(QBPhotoBrowser *)photoBrowser deseletedAsset:(PHAsset *)asset;
- (void)photoBrowser:(QBPhotoBrowser *)photoBrowser dataSource:(NSArray *)dataSource;

@end

@interface QBPhotoBrowser : UIViewController

@property (nonatomic, weak) QBImagePickerController *imagePickerController;
@property (nonatomic, weak) id<QBPhotoBrowserDelegate> delegate;

- (instancetype)initWithPhotos:(NSArray *)photosArray
                  currentIndex:(NSInteger)index;

- (void)hideControls;
- (void)toggleControls;

@end
