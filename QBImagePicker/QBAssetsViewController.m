//
//  QBAssetsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsViewController.h"
#import <Photos/Photos.h>

// Views
#import "QBImagePickerController.h"
#import "QBAssetCell.h"
#import "QBSendButton.h"
#import "QBVideoIndicatorView.h"
#import "QBPhotoBrowser.h"

static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

@interface QBImagePickerController (Private)

@property (nonatomic, strong) NSBundle *assetBundle;

@end

@implementation NSIndexSet (Convenience)

- (NSArray *)qb_indexPathsFromIndexesWithSection:(NSUInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

@end

@implementation UICollectionView (Convenience)

- (NSArray *)qb_indexPathsForElementsInRect:(CGRect)rect
{
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end

@interface QBAssetsViewController () <PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout,QBAssetCellDelegate,QBPhotoBrowserDelegate>

@property (nonatomic, strong) PHFetchResult *fetchResult;

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;

@property (nonatomic, assign) BOOL disableScrollToBottom;
@property (nonatomic, strong) NSIndexPath *lastSelectedItemIndexPath;
@property (nonatomic, strong) QBSendButton *sendButton;
@property (nonatomic, strong) UIButton *preViewButton;

@end

@implementation QBAssetsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpToolbarItems];
    [self resetCachedAssets];
    [self setupNavigationBarItems];
    
    // Register observer
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void) setupNavigationBarItems {
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 44, 44)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -13, 0, 13);
    [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:[UIImage imageNamed:@"QBImage.bundle/icon_navigation_back"] forState:UIControlStateNormal];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIBarButtonItem *leftFixeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftFixeItem.width = -15;
    
    self.navigationItem.leftBarButtonItems = @[leftFixeItem,leftItem];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSBundle *bundle = self.imagePickerController.assetBundle;
    NSString *cancel = NSLocalizedStringFromTableInBundle(@"assets.footer.cancel", @"QBImagePicker", bundle, nil);
    CGFloat width = [cancel sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}].width;
    [cancelButton setFrame:CGRectMake(0, 0, width, 44)];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [cancelButton setTitle:cancel forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    
    UIBarButtonItem *rightFixeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    rightFixeItem.width = -10;
    self.navigationItem.rightBarButtonItems = @[rightFixeItem,rightItem];
}

- (void) backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) cancelButtonAction {
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerControllerDidCancel:)]) {
        [self.imagePickerController.delegate qb_imagePickerControllerDidCancel:self.imagePickerController];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Configure navigation item
        self.navigationItem.title = self.assetCollection.localizedTitle;
    //    self.navigationItem.prompt = self.imagePickerController.prompt;
    
    // Configure collection view
    self.collectionView.allowsMultipleSelection = self.imagePickerController.allowsMultipleSelection;
    
    [self.collectionView reloadData];
    
    // Scroll to bottom
    if (self.fetchResult.count > 0 && self.isMovingToParentViewController && !self.disableScrollToBottom) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(self.fetchResult.count - 1) inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
    
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];

    self.disableScrollToBottom = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.disableScrollToBottom = NO;
    
    [self updateCachedAssets];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // Save indexPath for the last item
    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] lastObject];
    
    // Update layout
    [self.collectionViewLayout invalidateLayout];
    
    // Restore scroll position
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }];
}

- (void)dealloc
{
    // Deregister observer
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}


#pragma mark - Accessors

- (void)setAssetCollection:(PHAssetCollection *)assetCollection
{
    _assetCollection = assetCollection;
    
    [self updateFetchRequest];
    [self.collectionView reloadData];
}

- (PHCachingImageManager *)imageManager
{
    if (_imageManager == nil) {
        _imageManager = [PHCachingImageManager new];
    }
    
    return _imageManager;
}

- (BOOL)isAutoDeselectEnabled
{
    return (self.imagePickerController.maximumNumberOfSelection == 1
            && self.imagePickerController.maximumNumberOfSelection >= self.imagePickerController.minimumNumberOfSelection);
}


#pragma mark - Actions

- (IBAction)done:(id)sender
{
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
        [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController
                                               didFinishPickingAssets:self.imagePickerController.selectedAssets.array];
    }
}


#pragma mark - Toolbar

- (void)setUpToolbarItems {
    
    NSBundle *bundle = self.imagePickerController.assetBundle;
    NSString *preview = NSLocalizedStringFromTableInBundle(@"assets.footer.preview", @"QBImagePicker", bundle, nil);
    
    CGFloat width = [preview sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}].width;

    UIButton *preViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    preViewButton.frame = CGRectMake(0, 0, width + 10, 44);
    preViewButton.alpha = 0.4;
    preViewButton.titleEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5);
    preViewButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [preViewButton setTitle:preview forState:UIControlStateNormal];
    [preViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [preViewButton addTarget:self action:@selector(previewAction) forControlEvents:UIControlEventTouchUpInside];
    self.preViewButton = preViewButton;
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithCustomView:preViewButton];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSString *done = NSLocalizedStringFromTableInBundle(@"assets.footer.done", @"QBImagePicker", bundle, nil);
    QBSendButton *sendButton = [[QBSendButton alloc] initWithFrame:CGRectZero];
    sendButton.title = done;
    [sendButton addTaget:self action:@selector(sendButtonAction)];
    self.sendButton = sendButton;

    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton];
    
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item4.width = -5;
    
    self.toolbarItems = @[item1,item2,item3,item4];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateToolBar];
    });
}

#pragma mark - Fetching Assets

- (void)updateFetchRequest
{
    if (self.assetCollection) {
        PHFetchOptions *options = [PHFetchOptions new];
        
        switch (self.imagePickerController.mediaType) {
            case QBImagePickerMediaTypeImage:
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
                break;
                
            case QBImagePickerMediaTypeVideo:
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
                break;
                
            default:
                break;
        }
        
        self.fetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
        
        if ([self isAutoDeselectEnabled] && self.imagePickerController.selectedAssets.count > 0) {
            // Get index of previous selected asset
            PHAsset *asset = [self.imagePickerController.selectedAssets firstObject];
            NSInteger assetIndex = [self.fetchResult indexOfObject:asset];
            self.lastSelectedItemIndexPath = [NSIndexPath indexPathForItem:assetIndex inSection:0];
        }
    } else {
        self.fetchResult = nil;
    }
}


#pragma mark - Checking for Selection Limit

- (BOOL)isMinimumSelectionLimitFulfilled
{
    return (self.imagePickerController.minimumNumberOfSelection <= self.imagePickerController.selectedAssets.count);
}

- (BOOL)isMaximumSelectionLimitReached
{
    NSUInteger minimumNumberOfSelection = MAX(1, self.imagePickerController.minimumNumberOfSelection);
    
    if (minimumNumberOfSelection <= self.imagePickerController.maximumNumberOfSelection) {
        return (self.imagePickerController.maximumNumberOfSelection <= self.imagePickerController.selectedAssets.count);
    }
    
    return NO;
}

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = [self isViewLoaded] && self.view.window != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0) {
        // Compute the assets to start caching and to stop caching
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        } removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        CGSize itemSize = [(UICollectionViewFlowLayout *)self.collectionViewLayout itemSize];
        CGSize targetSize = CGSizeScale(itemSize, self.traitCollection.displayScale);
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:targetSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:targetSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect addedHandler:(void (^)(CGRect addedRect))addedHandler removedHandler:(void (^)(CGRect removedRect))removedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < self.fetchResult.count) {
            PHAsset *asset = self.fetchResult[indexPath.item];
            [assets addObject:asset];
        }
    }
    return assets;
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.fetchResult];
        
        if (collectionChanges) {
            // Get the new fetch result
            self.fetchResult = [collectionChanges fetchResultAfterChanges];
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // We need to reload all if the incremental diffs are not available
                [self.collectionView reloadData];
            } else {
                // If we have incremental diffs, tell the collection view to animate insertions and deletions
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [self.collectionView deleteItemsAtIndexPaths:[removedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [self.collectionView insertItemsAtIndexPaths:[insertedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [self.collectionView reloadItemsAtIndexPaths:[changedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AssetCell" forIndexPath:indexPath];
    cell.tag = indexPath.item;
    cell.delegate = self;
    cell.multiSelected = self.imagePickerController.allowsMultipleSelection;
    
    // Image
    PHAsset *asset = self.fetchResult[indexPath.item];
    CGSize itemSize = [(UICollectionViewFlowLayout *)collectionView.collectionViewLayout itemSize];
    CGSize targetSize = CGSizeScale(itemSize, self.traitCollection.displayScale);
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (cell.tag == indexPath.item) {
                                      cell.imageView.image = result;
                                  }
                              }];
    
    // Video indicator
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        cell.videoIndicatorView.hidden = NO;
        
        NSInteger minutes = (NSInteger)(asset.duration / 60.0);
        NSInteger seconds = (NSInteger)ceil(asset.duration - 60.0 * (double)minutes);
        cell.videoIndicatorView.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
        
        if (asset.mediaSubtypes & PHAssetMediaSubtypeVideoHighFrameRate) {
            cell.videoIndicatorView.videoIcon.hidden = YES;
            cell.videoIndicatorView.slomoIcon.hidden = NO;
        }
        else {
            cell.videoIndicatorView.videoIcon.hidden = NO;
            cell.videoIndicatorView.slomoIcon.hidden = YES;
        }
    } else {
        cell.videoIndicatorView.hidden = YES;
    }
    
    // Selection state
    if ([self.imagePickerController.selectedAssets containsObject:asset]) {
        //        cell.selected = YES;
        cell.imageSelected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        cell.imageSelected = NO;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.imagePickerController.allowsMultipleSelection) {
        NSMutableArray *assetsArray = [[NSMutableArray alloc] init];
        [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [assetsArray addObject:obj];
        }];
        
        [self browserPhotoAsstes:assetsArray pageIndex:indexPath.item];

    } else {
        PHAsset *asset = self.fetchResult[indexPath.item];
        if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
            [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController didFinishPickingAssets:@[asset]];
        }
    }
}

- (void) previewAction {
    
    [self browserPhotoAsstes:[[self.imagePickerController.selectedAssets objectEnumerator] allObjects] pageIndex:0];
}

- (void)browserPhotoAsstes:(NSArray *)assets pageIndex:(NSInteger)page
{
    QBPhotoBrowser *browser = [[QBPhotoBrowser alloc] initWithPhotos:assets
                                                        currentIndex:page];
    browser.delegate = self;
    browser.imagePickerController = self.imagePickerController;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];
}

/*
 - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 if (kind == UICollectionElementKindSectionFooter) {
 UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
 withReuseIdentifier:@"FooterView"
 forIndexPath:indexPath];
 
 // Number of assets
 UILabel *label = (UILabel *)[footerView viewWithTag:1];
 
 NSBundle *bundle = self.imagePickerController.assetBundle;
 NSUInteger numberOfPhotos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
 NSUInteger numberOfVideos = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
 
 switch (self.imagePickerController.mediaType) {
 case QBImagePickerMediaTypeAny:
 {
 NSString *format;
 if (numberOfPhotos == 1) {
 if (numberOfVideos == 1) {
 format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-video", @"QBImagePicker", bundle, nil);
 } else {
 format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-videos", @"QBImagePicker", bundle, nil);
 }
 } else if (numberOfVideos == 1) {
 format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-video", @"QBImagePicker", bundle, nil);
 } else {
 format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-videos", @"QBImagePicker", bundle, nil);
 }
 
 label.text = [NSString stringWithFormat:format, numberOfPhotos, numberOfVideos];
 }
 break;
 
 case QBImagePickerMediaTypeImage:
 {
 NSString *key = (numberOfPhotos == 1) ? @"assets.footer.photo" : @"assets.footer.photos";
 NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
 
 label.text = [NSString stringWithFormat:format, numberOfPhotos];
 }
 break;
 
 case QBImagePickerMediaTypeVideo:
 {
 NSString *key = (numberOfVideos == 1) ? @"assets.footer.video" : @"assets.footer.videos";
 NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
 
 label.text = [NSString stringWithFormat:format, numberOfVideos];
 }
 break;
 }
 
 return footerView;
 }
 
 return nil;
 }
 */

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:shouldSelectAsset:)]) {
        PHAsset *asset = self.fetchResult[indexPath.item];
        return [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController shouldSelectAsset:asset];
    }
    
    if ([self isAutoDeselectEnabled]) {
        return YES;
    }
    
    return ![self isMaximumSelectionLimitReached];
}

- (void)didSelectItemWithCell:(QBAssetCell *)assetCell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:assetCell];
    
    QBImagePickerController *imagePickerController = self.imagePickerController;
    NSMutableOrderedSet *selectedAssets = imagePickerController.selectedAssets;
    
    PHAsset *asset = self.fetchResult[indexPath.item];
    
    if (imagePickerController.allowsMultipleSelection) {
        if ([self isAutoDeselectEnabled] && selectedAssets.count > 0) {
            // Remove previous selected asset from set
            [selectedAssets removeObjectAtIndex:0];
            
            // Deselect previous selected asset
            if (self.lastSelectedItemIndexPath) {
                [self.collectionView deselectItemAtIndexPath:self.lastSelectedItemIndexPath animated:NO];
            }
        }
        
        if ([self seletedAssets:asset]) {
            assetCell.imageSelected = YES;
            self.lastSelectedItemIndexPath = indexPath;
        }

        
        if (imagePickerController.showsNumberOfSelectedAssets) {
            
        }
    } else {
        if ([imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
            [imagePickerController.delegate qb_imagePickerController:imagePickerController didFinishPickingAssets:@[asset]];
        }
    }
    
    if ([imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didSelectAsset:)]) {
        [imagePickerController.delegate qb_imagePickerController:imagePickerController didSelectAsset:asset];
    }
}


- (void)didDeselectItemWithCell:(QBAssetCell *)assetCell {
    
    assetCell.imageSelected = NO;

    NSIndexPath *indexPath = [self.collectionView indexPathForCell:assetCell];
    
    if (!self.imagePickerController.allowsMultipleSelection) {
        return;
    }
    
    QBImagePickerController *imagePickerController = self.imagePickerController;
    NSMutableOrderedSet *selectedAssets = imagePickerController.selectedAssets;
    
    PHAsset *asset = self.fetchResult[indexPath.item];
    
    // Remove asset from set
    [selectedAssets removeObject:asset];
    
    self.lastSelectedItemIndexPath = nil;
    

    if (imagePickerController.showsNumberOfSelectedAssets) {
        [self updateToolBar];
    }
    
    if ([imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didDeselectAsset:)]) {
        [imagePickerController.delegate qb_imagePickerController:imagePickerController didDeselectAsset:asset];
    }
}

- (void) sendButtonAction {
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didFinishPickingAssets:)]) {
        [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController
                                               didFinishPickingAssets:self.imagePickerController.selectedAssets.array];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfColumns;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        numberOfColumns = self.imagePickerController.numberOfColumnsInPortrait;
    } else {
        numberOfColumns = self.imagePickerController.numberOfColumnsInLandscape;
    }
    
    CGFloat width = (CGRectGetWidth(self.view.frame) - 2.0 * (numberOfColumns - 1)) / numberOfColumns;
    
    return CGSizeMake(width, width);
}

#pragma mark - DNPhotoBrowserDelegate
- (void)sendImagesFromPhotobrowser:(QBPhotoBrowser *)photoBrowser currentAsset:(PHAsset *)asset
{
    if (self.imagePickerController.selectedAssets.count <= 0) {
        [self seletedAssets:asset];
        [self.collectionView reloadData];
    }
    [self sendButtonAction];
}

- (NSUInteger)seletedPhotosNumberInPhotoBrowser:(QBPhotoBrowser *)photoBrowser
{
    return self.imagePickerController.selectedAssets.array.count;
}

- (BOOL)photoBrowser:(QBPhotoBrowser *)photoBrowser currentPhotoAssetIsSeleted:(PHAsset *)asset{
    return [self.imagePickerController.selectedAssets containsObject:asset];
}

- (BOOL)photoBrowser:(QBPhotoBrowser *)photoBrowser seletedAsset:(PHAsset *)asset
{
    BOOL seleted = [self seletedAssets:asset];
    [self.collectionView reloadData];
    return seleted;
}

- (BOOL)seletedAssets:(PHAsset *)asset {
    if ([self containsAsset:asset]) {
        return NO;
    }

    if (self.imagePickerController.selectedAssets.count >= self.imagePickerController.maximumNumberOfSelection) {
        
        NSBundle *bundle = self.imagePickerController.assetBundle;
        NSString *alertContent = NSLocalizedStringFromTableInBundle(@"assets.alert.content", @"QBImagePicker", bundle, nil);
        NSString *alertDone = NSLocalizedStringFromTableInBundle(@"assets.alert.done", @"QBImagePicker", bundle, nil);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:alertContent,self.imagePickerController.maximumNumberOfSelection] delegate:self cancelButtonTitle:alertDone otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    } else {
        [self.imagePickerController.selectedAssets addObject:asset];
        [self updateToolBar];
        
        return YES;
    }
}

- (BOOL) containsAsset:(PHAsset *)asset {
    return [self.imagePickerController.selectedAssets containsObject:asset];
}

- (void)photoBrowser:(QBPhotoBrowser *)photoBrowser deseletedAsset:(PHAsset *)asset
{
    if ([self containsAsset:asset]) {
        [self.imagePickerController.selectedAssets removeObject:asset];
    }
    
    [self updateToolBar];
    
    [self.collectionView reloadData];
}

- (void) updateToolBar {
    
    NSInteger selectedNumber = self.imagePickerController.selectedAssets.count;
    
    self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(selectedNumber)];
    
    self.sendButton.alpha = selectedNumber < 1 ? 0.4 : 1;
    self.preViewButton.alpha = selectedNumber < 1 ? 0.4 : 1;

    self.sendButton.userInteractionEnabled = selectedNumber < 1 ? NO : YES;
    self.preViewButton.userInteractionEnabled = selectedNumber < 1 ? NO : YES;

}

@end
