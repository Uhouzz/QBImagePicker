//
//  QBPhotoBrowserCell.m
//  Pods
//
//  Created by TCS on 16/11/4.
//
//

#import "QBPhotoBrowserCell.h"
#import <Photos/PHImageManager.h>
#import "QBTapImageView.h"
#import "UIView+QBImagePicker.h"

@interface QBPhotoBrowserCell ()<UIScrollViewDelegate,QBTapImageViewDelegate>

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) QBTapImageView *photoImageView;
@property (nonatomic, strong) UIScrollView *zoomingScrollView;

@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation QBPhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void) setupViews {
    [self.contentView addSubview:self.zoomingScrollView];
    [self.zoomingScrollView addSubview:self.photoImageView];
    [self.zoomingScrollView addSubview:self.indicatorView];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.indicatorView stopAnimating];
//    self.indicatorView = nil;
    self.photoImageView.image = nil;
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = 0;
    }
}

- (void)layoutSubviews {
    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.zoomingScrollView.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(self.photoImageView.frame, frameToCenter)) {
        self.photoImageView.frame = frameToCenter;
    }

}

- (void)configureCellWithAsset:(PHAsset *)asset {
    self.asset = asset;
    
    self.zoomingScrollView.maximumZoomScale = 1;
    self.zoomingScrollView.minimumZoomScale = 1;
    self.zoomingScrollView.zoomScale = 1;
    self.zoomingScrollView.contentSize = CGSizeMake(0, 0);
    self.photoImageView.frame = self.zoomingScrollView.bounds;
    
    self.requestID = [self requestFullScreenImageWithAsset:asset completion:^(UIImage *image) {
        self.requestID = 0;
        if (!image) {
            return ;
        }
        self.photoImageView.image = image;
        self.photoImageView.frame = [self frameForPhotoImageView];
    
        self.zoomingScrollView.contentSize = self.photoImageView.frame.size;
        
        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
        [self setNeedsLayout];
    }];
}

- (CGRect) frameForPhotoImageView {
    CGRect centerRect;
    CGSize boundsSize = _zoomingScrollView.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    CGSize size;
    CGFloat xScale = boundsSize.width / imageSize.width * screenScale;
    size = CGSizeMake(boundsSize.width, imageSize.height * xScale / screenScale);
    centerRect.origin = CGPointZero;
    centerRect.size = size;
    return centerRect;
}

- (PHImageRequestID) requestFullScreenImageWithAsset:(PHAsset *)asset completion:(void (^)(UIImage *image))comletion {
    if (!asset) {
        return PHInvalidImageRequestID;
    }

    CGSize size;
    
    CGFloat scale_width = CGRectGetWidth(self.zoomingScrollView.bounds) * [UIScreen mainScreen].scale;
    CGFloat scale_height = CGRectGetHeight(self.zoomingScrollView.bounds) * [UIScreen mainScreen].scale;
    size = CGSizeMake(scale_width, scale_height);
    
    if (asset.pixelWidth > scale_width || asset.pixelHeight > scale_height) {
        size = PHImageManagerMaximumSize;
    }
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeExact;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    option.networkAccessAllowed = YES;
    option.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (progress == 1) {
                [self.indicatorView stopAnimating];
            }
            
            if (progress == 0) {
                [self.indicatorView startAnimating];
            }
        });
    };
    
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (comletion) {
            comletion(result);
        }
    }];
}

- (QBTapImageView *)photoImageView {
    if (nil == _photoImageView) {
        _photoImageView = [[QBTapImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        _photoImageView.delegate = self;
    }
    return _photoImageView;
}

- (UIScrollView *)zoomingScrollView {
    if (nil == _zoomingScrollView) {
        _zoomingScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width-20, self.frame.size.height)];
        _zoomingScrollView.delegate = self;
        _zoomingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
        _zoomingScrollView.showsHorizontalScrollIndicator = NO;
        _zoomingScrollView.showsVerticalScrollIndicator = NO;
        _zoomingScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    return _zoomingScrollView;
}
- (UIActivityIndicatorView *) indicatorView {
    if (!_indicatorView) {
        _indicatorView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.center = CGPointMake(_zoomingScrollView.width / 2.0, _zoomingScrollView.height / 2.0);
        _indicatorView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);

    }
    
    return _indicatorView;
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
    // Reset
    self.zoomingScrollView.maximumZoomScale = 1;
    self.zoomingScrollView.minimumZoomScale = 1;
    self.zoomingScrollView.zoomScale = 1;
    
    // Bail if no image
    if (!_photoImageView.image) {
       return;
    }
    
    CGFloat minScale = 1;
    // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 4.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];
        
        if (maxScale < minScale) {
            maxScale = minScale * 2;
        }
    }
    
    // Set min/max zoom
    self.zoomingScrollView.maximumZoomScale = maxScale;
    self.zoomingScrollView.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomingScrollView.zoomScale = minScale;
    
    // Layout
    [self setNeedsLayout];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photoImageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.zoomingScrollView.scrollEnabled = YES; // reset
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection
- (void)handleSingleTap:(CGPoint)touchPoint {
    if (!self.photoBrowser) {
        return;
    }
    [self.photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    if (!self.photoBrowser) {
        return;
    }
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    
    // Zoom
    if (self.zoomingScrollView.zoomScale == self.zoomingScrollView.maximumZoomScale) {
        // Zoom out
        [self.zoomingScrollView setZoomScale:self.zoomingScrollView.minimumZoomScale animated:YES];
    } else {
        // Zoom in
        [self.zoomingScrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    }
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    if (!touch) {
        return;
    }
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    if (!touch) {
        return;
    }
    [self handleDoubleTap:[touch locationInView:imageView]];
}



@end
