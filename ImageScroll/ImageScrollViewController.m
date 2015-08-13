//
//  ImageScrollViewController.m
//  ImageScroll
//
//  Created by Evgenii Neumerzhitckii on 19/05/13.
//  Copyright (c) 2013 Evgenii Neumerzhitckii. All rights reserved.
//

#import "ImageScrollViewController.h"

@interface ImageScrollViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;
@property (weak, nonatomic) IBOutlet UIButton *changeImageButton;
@property (nonatomic) CGFloat lastZoomScale;
@property (nonatomic, assign) BOOL fitsToScreen;

@property (nonatomic, retain) UITapGestureRecognizer *gestureRecognizer;

@end

@implementation ImageScrollViewController

- (void)commonInit
{
    self.fitsToScreen = YES;
    
    self.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    self.gestureRecognizer.numberOfTapsRequired = 2;
    
    [self.view addGestureRecognizer:self.gestureRecognizer];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self commonInit];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.imageView.image = [UIImage imageNamed: @"wallabi.jpg"];
    self.scrollView.delegate = self;
    [self updateZoom];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    [self updateZoom];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator NS_AVAILABLE_IOS(8_0);
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.view setNeedsUpdateConstraints];
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    self.fitsToScreen = scrollView.zoomScale <= scrollView.minimumZoomScale;
    
    [self updateConstraints];
}

- (void) updateConstraints {
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;
    
    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    // center image if it is smaller than screen
    float hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    if (hPadding < 0) hPadding = 0;
    
    float vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    if (vPadding < 0) vPadding = 0;
    
    self.constraintLeft.constant = hPadding;
    self.constraintRight.constant = hPadding;
    
    self.constraintTop.constant = vPadding;
    self.constraintBottom.constant = vPadding;
    
    // Makes zoom out animation smooth and starting from the right point not from (0, 0)
    [self.view layoutIfNeeded];
}

// Zoom to show as much image as possible even when image is smaller than screen
- (void) updateZoom {
    float minZoom = MIN(self.view.bounds.size.width / self.imageView.image.size.width,
                        self.view.bounds.size.height / self.imageView.image.size.height);
    
    self.scrollView.minimumZoomScale = minZoom;
    
    // Force scrollViewDidZoom fire if zoom did not change
    if (minZoom == self.lastZoomScale) minZoom += 0.000001;
    
    if (self.fitsToScreen)
        self.lastZoomScale = self.scrollView.zoomScale = minZoom;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (IBAction)onImageChangeTouched:(id)sender {
    self.changeImageButton.selected = !self.changeImageButton.isSelected;
    [self.changeImageButton invalidateIntrinsicContentSize];
    
    NSString *fileName = @"wallabi.jpg";
    if (self.changeImageButton.selected ) fileName = @"wallabi_small.jpg";
    
    self.fitsToScreen = YES;
    self.imageView.image = [UIImage imageNamed: fileName];
    [self updateZoom];
}

- (void) positionContent:(CGPoint)cp toPosition:(CGPoint)vp {
    CGPoint offset = CGPointZero;
    float scale = self.scrollView.zoomScale;
    
    offset = CGPointMake(((cp.x * scale) - vp.x), ((cp.y * scale) - vp.y));
    
    [self.scrollView setContentOffset:offset];
}

- (BOOL)systemVersionGreaterThanOrEqualToVersion:(NSString *)minVersion
{
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
    return [sysVersion compare:minVersion options:NSNumericSearch] == NSOrderedDescending || [sysVersion compare:minVersion options:NSNumericSearch] == NSOrderedSame;
}

- (void) doubleTapGesture:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if(self.scrollView.zoomScale < 1.0){
            CGPoint locationInView = [gestureRecognizer locationOfTouch:0 inView:self.view.superview];
            CGPoint locationInImage = [gestureRecognizer locationOfTouch:0 inView:self.imageView];

            BOOL isAtLeastIOS8 = [self systemVersionGreaterThanOrEqualToVersion:@"8.0"];
            void(^zoomIn)() = ^{
                [self.scrollView setZoomScale:MAX(1,self.scrollView.minimumZoomScale) animated:isAtLeastIOS8 ? NO : YES];
                [self positionContent:locationInImage toPosition:locationInView];
            };
            
            if (isAtLeastIOS8)
                [UIView animateWithDuration:0.4 animations:^{
                    zoomIn();
                }];
            else
                zoomIn();
        } else {
            [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        }
    }
}

@end
