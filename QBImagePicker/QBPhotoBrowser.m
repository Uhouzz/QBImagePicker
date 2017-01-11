//
//  QBPhotoBrowser.m
//  Pods
//
//  Created by TCS on 16/11/4.
//
//

#import "QBPhotoBrowser.h"
#import "QBPhotoBrowserCell.h"
#import "QBSendButton.h"
#import "QBImagePickerController.h"

@interface QBImagePickerController (Private)

@property (nonatomic, strong) NSBundle *assetBundle;

@end

@interface QBPhotoBrowser ()<UICollectionViewDataSource,UICollectionViewDelegate>
{
    BOOL _statusBarShouldBeHidden;
    BOOL _didSavePreviousStateOfNavBar;
    BOOL _viewIsActive;
    BOOL _viewHasAppearedInitially;
    
    // Appearance
    BOOL _previousNavBarHidden;
    BOOL _previousNavBarTranslucent;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIColor *_previousNavBarTintColor;
    UIColor *_previousNavBarBarTintColor;
    UIBarButtonItem *_previousViewControllerBackButton;
    UIImage *_previousNavigationBarBackgroundImageDefault;
    UIImage *_previousNavigationBarBackgroundImageLandscapePhone;
}


@property (nonatomic, strong) UICollectionView *browserCollectionView;
@property (nonatomic, strong) NSMutableArray *photoDataSources;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL statusBarShouldBeHidden;

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) QBSendButton *sendButton;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation QBPhotoBrowser

- (instancetype) initWithPhotos:(NSArray *)photosArray
                  currentIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        _photoDataSources = [NSMutableArray arrayWithArray:photosArray];
        _currentIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self browserCollectionView];
    [self toolbar];
    [self setupToolbarItems];
    [self setupNavigationBarItems];
    
    [self updateSelestedNumber];
    [self updateNavigationBarAndToolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    // Super
    [super viewWillAppear:animated];
    _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    
    // Initial appearance
    if (!_viewHasAppearedInitially) {
        _viewHasAppearedInitially = YES;
    }
    //scroll to the current offset
    [self.browserCollectionView setContentOffset:CGPointMake(self.browserCollectionView.frame.size.width * self.currentIndex,0)];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        _viewIsActive = NO;
        [self restorePreviousNavBarAppearance:animated];
    }
    
    [self.navigationController.navigationBar.layer removeAllAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setControlsHidden:NO animated:NO];
    
    [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    
    // Super
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    _viewIsActive = NO;
    [super viewDidDisappear:animated];
}

- (void)updateNavigationBarAndToolBar {
    NSUInteger totalNumber = self.photoDataSources.count;
    self.title = [NSString stringWithFormat:@"%@/%@",@(self.currentIndex+1),@(totalNumber)];
    BOOL isSeleted = NO;
    if ([self.delegate respondsToSelector:@selector(photoBrowser:currentPhotoAssetIsSeleted:)]) {
        isSeleted = [self.delegate photoBrowser:self
                     currentPhotoAssetIsSeleted:self.photoDataSources[self.currentIndex]];
    }
    self.rightButton.selected = isSeleted;
}

- (void)updateSelestedNumber {
    NSUInteger selectedNumber = 0;
    if ([self.delegate respondsToSelector:@selector(seletedPhotosNumberInPhotoBrowser:)]) {
        selectedNumber = [self.delegate seletedPhotosNumberInPhotoBrowser:self];
    }
    self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(selectedNumber)];
    self.sendButton.alpha = selectedNumber < 1 ? 0.4 : 1;
    self.sendButton.userInteractionEnabled = selectedNumber < 1 ? NO : YES;
}

- (void) setupNavigationBarItems {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 44, 44)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -13, 0, 13);
    [backButton addTarget:self action:@selector(leftButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:[UIImage imageNamed:@"QBImage.bundle/icon_back"] forState:UIControlStateNormal];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIBarButtonItem *leftFixeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftFixeItem.width = -15;
    self.navigationItem.leftBarButtonItems = @[leftFixeItem,leftItem];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
    
    UIBarButtonItem *rightFixeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    rightFixeItem.width = -10;
    self.navigationItem.rightBarButtonItems = @[rightFixeItem,rightItem];
}

- (void) leftButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) rightButtonAction {
    if (self.rightButton.selected) {
        if ([self.delegate respondsToSelector:@selector(photoBrowser:deseletedAsset:)]) {
            [self.delegate photoBrowser:self deseletedAsset:self.photoDataSources[self.currentIndex]];
            self.rightButton.selected = NO;
        }
    
    } else {
        if ([self.delegate respondsToSelector:@selector(photoBrowser:seletedAsset:)]) {
            self.rightButton.selected = [self.delegate photoBrowser:self seletedAsset:self.photoDataSources[self.currentIndex]];
        }
    }
    
    [self updateSelestedNumber];
}

- (void) sendButtonAction {
    if ([self.delegate respondsToSelector:@selector(sendImagesFromPhotobrowser:currentAsset:)]) {
        [self.delegate sendImagesFromPhotobrowser:self currentAsset:self.photoDataSources[self.currentIndex]];
    }
}

#pragma mark - Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    if ([navBar respondsToSelector:@selector(setBarTintColor:)]) {
        navBar.barTintColor = nil;
        navBar.shadowImage = nil;
    }
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    }
}

- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
        _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    }
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact];
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
            navBar.barTintColor = _previousNavBarBarTintColor;
        }
        navBar.barStyle = _previousNavBarStyle;
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsCompact];
        }
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photoDataSources.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    QBPhotoBrowserCell *cell = (QBPhotoBrowserCell *)[collectionView dequeueReusableCellWithReuseIdentifier:QBPhotoBrowserCellIdentifier
                    forIndexPath:indexPath];
    cell.photoBrowser = self;
    [cell configureCellWithAsset:self.photoDataSources[indexPath.row]];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.bounds.size.width + 20, self.view.bounds.size.height);
}

- (void) setupToolbarItems {
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item4.width = -5;
    
    [self.toolbar setItems:@[item1,item2,item3,item4]];
}

- (UIButton *) rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(0, 0, 25, 25);
        [_rightButton setBackgroundImage:[UIImage imageNamed:@"QBImage.bundle/icon_selected_gray"] forState:UIControlStateNormal];
        [_rightButton setBackgroundImage:[UIImage imageNamed:@"QBImage.bundle/icon_selected"] forState:UIControlStateSelected];
        [_rightButton addTarget:self action:@selector(rightButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightButton;
}

- (UICollectionView *)browserCollectionView {
    if (! _browserCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.001;
        layout.minimumLineSpacing = 0.001;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _browserCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 0, self.view.bounds.size.width + 20, self.view.bounds.size.height+1) collectionViewLayout:layout];
        [_browserCollectionView registerClass:[QBPhotoBrowserCell class]
                   forCellWithReuseIdentifier:QBPhotoBrowserCellIdentifier];
        _browserCollectionView.delegate = self;
        _browserCollectionView.dataSource = self;
        _browserCollectionView.pagingEnabled = YES;
        _browserCollectionView.backgroundColor = [UIColor blackColor];
        _browserCollectionView.showsHorizontalScrollIndicator = NO;
        _browserCollectionView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:_browserCollectionView];
    }
    return _browserCollectionView;
}

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        CGFloat height = 44;
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height)];
        if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
            [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
            [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsCompact];
        }
        _toolbar.barStyle = UIBarStyleBlackTranslucent;
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_toolbar];
    }
    return _toolbar;
}

- (QBSendButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[QBSendButton alloc] initWithFrame:CGRectZero];
        [_sendButton addTaget:self action:@selector(sendButtonAction)];
        NSBundle *bundle = self.imagePickerController.assetBundle;
        NSString *done = NSLocalizedStringFromTableInBundle(@"assets.footer.done", @"QBImagePicker", bundle, nil);
        _sendButton.title = done;
    }
    return _sendButton;
}

- (void) backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - scrollerViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.browserCollectionView != scrollView) {
        return;
    }
    
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat itemWidth = CGRectGetWidth(self.browserCollectionView.frame);
    if (offsetX >= 0){
        NSInteger page = offsetX / itemWidth;
        self.currentIndex = page;
        [self updateNavigationBarAndToolBar];
    }
}


#pragma mark - Control Hiding / Showing
// Fades all controls slide and fade
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated{
    
    // Force visible
    if (nil == self.photoDataSources || self.photoDataSources.count == 0)
        hidden = NO;
    // Animations & positions
    CGFloat animatonOffset = 20;
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // Hide status bar
        _statusBarShouldBeHidden = hidden;
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationSlide];

        [UIView animateWithDuration:animationDuration animations:^(void) {
            [self setNeedsStatusBarAppearanceUpdate];

        } completion:^(BOOL finished) {}];
    }
    
    CGRect frame = CGRectIntegral(CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44));
    
    // Pre-appear animation positions for iOS 7 sliding
    if ([self areControlsHidden] && !hidden && animated) {
        // Toolbar
        self.toolbar.frame = CGRectOffset(frame, 0, animatonOffset);
    }
    
    [UIView animateWithDuration:animationDuration animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        // Nav bar slides up on it's own on iOS 7
        [self.navigationController.navigationBar setAlpha:alpha];
        // Toolbar
        _toolbar.frame = frame;
        if (hidden) _toolbar.frame = CGRectOffset(_toolbar.frame, 0, animatonOffset);
        _toolbar.alpha = alpha;
        
    } completion:^(BOOL finished) {}];
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarShouldBeHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)areControlsHidden {
    return _toolbar.alpha == 0;
}

- (void)hideControls {
    [self setControlsHidden:YES animated:YES];
}

- (void)toggleControls {
    [self setControlsHidden:![self areControlsHidden] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
