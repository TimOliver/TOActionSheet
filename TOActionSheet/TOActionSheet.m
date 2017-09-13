//
//  TOActionSheet.m
//
//  Copyright 2015 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TOActionSheet.h"

typedef NS_ENUM(NSInteger, TOActionSheetArrowDirection) {
    TOActionSheetArrowDirectionNone,
    TOActionSheetArrowDirectionDown,
    TOActionSheetArrowDirectionLeft,
    TOActionSheetArrowDirectionUp,
    TOActionSheetArrowDirectionRight
};

const CGFloat kTOActionSheetButtonHeight  = 56.0f;
const CGFloat kTOActionSheetDefaultWidth  = 300.0f;
const CGFloat kTOActionSheetBorderRadius  = 15.0f;
const CGFloat kTOActionSheetTitlePadding  = 15.0f;
const CGFloat kTOActionSheetCompactMargin = 20.0f;
const CGFloat kTOActionSheetArrowBase     = 36.0f;
const CGFloat kTOActionSheetArrowHeight   = 13.0f;
const CGFloat kTOActionSheetScreenPadding = 20.0f;

@interface TOActionSheet ()

/* The width of this action sheet */
@property (nonatomic, assign) CGFloat width;

/* The elements we can use to align the popup sheet */
@property (nonatomic, assign) CGRect targetRect;
@property (nonatomic, strong) UIView *targetView;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, strong) UIBarButtonItem *targetButtonItem;

/* The titles and blocks for each button */
@property (nonatomic, strong) NSMutableArray *buttonTitles;
@property (nonatomic, strong) NSMutableArray *buttonIcons;
@property (nonatomic, strong) NSMutableArray *buttonBlocks;

@property (nonatomic, copy) NSString *destructiveTitle;
@property (nonatomic, copy) UIImage *destructiveIcon;
@property (nonatomic, copy) void (^destructiveBlock)(void);

/* The views of each button */
@property (nonatomic, strong) NSMutableArray *buttonViews;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *destructiveButton;
@property (nonatomic, strong) NSMutableArray *separatorViews;

/* The views used to construct the view hierarchy */
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *headerBackgroundView;
@property (nonatomic, strong) UIImageView *arrowImageView;

/* Determine whether we need to be in regular or compact traits */
@property (nonatomic, readonly) BOOL compactLayout;

/* Work out if the header view will be visible */
@property (nonatomic, readonly) BOOL headerIsVisible;

/* Work out the best direction and placement of the popup when in regular (ie iPad) mode. */
@property (nonatomic, readonly) CGRect presentationRect;

/* The direction of the arrow graphic in regular mode */
@property (nonatomic, assign) TOActionSheetArrowDirection arrowDirection;

/* View setup */
- (void)setUp;
- (void)setColorsForStyle:(TOActionSheetStyle)style;
- (void)show;

/* Content views setup */
- (void)setUpContainerWidth;
- (void)setUpContainer;
- (void)setUpDimmingView;
- (void)setUpRegularButtons;
- (void)setUpCancelButton;
- (void)setUpHeaderView;
- (void)setUpDestructiveButton;
- (void)setUpSeparators;

/* User interaction */
- (void)buttonTapped:(id)sender;
- (void)buttonTapDown:(id)sender;
- (void)buttonTapUp:(id)sender;

- (void)dimmingViewTapped:(id)sender;

/* Presentation/Dismissal Animations */
- (void)presentViewWithCompactAnimation;
- (void)dismissViewWithCompactAnimation;

- (void)presentViewWithRegularAnimation;
- (void)dismissViewWithRegularAnimation;

/* Layout Calculations for Regular mode */
- (TOActionSheetArrowDirection)bestArrowDirectionForPresentationRect:(CGRect)presentationRect;
- (CGRect)frameOfContainerViewWithArrowDirection:(TOActionSheetArrowDirection)direction presentationRect:(CGRect)presentationRect;
- (CGRect)frameOfArrowViewWithDirection:(TOActionSheetArrowDirection)direction presentationRect:(CGRect)presentationRect;
- (UIColor *)bestColorForArrowWithDirection:(TOActionSheetArrowDirection)direction;

/* Image asset generation */
- (UIImage *)buttonBackgroundImageWithColor:(UIColor *)color roundedTop:(BOOL)roundedTop roundedBottom:(BOOL)roundedBottom;
- (UIImage *)buttonBackgroundImageWithColor:(UIColor *)color; //Generates 1x1 art for square buttons
- (UIImage *)arrowImageForDirection:(TOActionSheetArrowDirection)direction color:(UIColor *)color;

- (void)deviceWillChangeOrientation:(NSNotification *)notification;
- (void)presentViewAfterSizeTransition;

@end

@implementation TOActionSheet

- (instancetype)init
{
    if (self = [super init]) {
        [self setUp];
    }
    
    return self;
}

- (instancetype)initWithStyle:(TOActionSheetStyle)style
{
    if (self = [super init]) {
        _style = style;
        [self setUp];
    }
    
    return self;
}

- (instancetype)initWithHeaderView:(UIView *)headerView
{
    if (self = [super init]) {
        _headerView = headerView;
        [self setUp];
    }
    
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
{
    if (self = [super init]) {
        _title = title;
        [self setUp];
    }
    
    return self;
}

- (void)setUp
{
    //Set initial theming properties
    _buttonFont = [UIFont systemFontOfSize:18.0f];
    _titleFont = [UIFont systemFontOfSize:15.0f];
    _cancelButtonFont = [UIFont boldSystemFontOfSize:18.0f];
    _cancelButtonTitle = NSLocalizedStringFromTable(@"Cancel", @"TOActionSheetLocalizable", @"Cancel Button");
    [self setColorsForStyle:_style];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWillChangeOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)setColorsForStyle:(TOActionSheetStyle)style
{
    if (style == TOActionSheetStyleDark) {
        _buttonBackgroundColor              = [UIColor colorWithWhite:0.3f alpha:1.0f];
        _buttonTextColor                    = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _buttonTappedBackgroundColor        = [UIColor colorWithRed:44.0f/255.0f green:130.0f/255.0f blue:170.0f/255.0f alpha:1.0f];
        _buttonTappedTextColor              = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _cancelButtonBackgroundColor        = [UIColor colorWithWhite:0.25f alpha:1.0f];
        _cancelButtonTextColor              = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _cancelButtonTappedBackgroundColor  = [UIColor colorWithWhite:0.15 alpha:1.0f];
        _cancelButtonTappedTextColor        = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _destructiveButtonBackgroundColor   = [UIColor colorWithRed:0.8f green:0.15f blue:0.15f alpha:1.0f];
        _destructiveButtonTextColor         = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _destructiveButtonTappedBackgroundColor = [UIColor colorWithRed:0.6f green:0.0f blue:0.0f alpha:1.0f];
        _destructiveButtonTappedTextColor   = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _buttonSeparatorColor               = [UIColor colorWithWhite:0.4f alpha:1.0f];
        _headerBackgroundColor              = [UIColor colorWithWhite:0.25f alpha:1.0f];
        _dimmingViewAlpha                   = 0.65f;
        _titleColor                         = [UIColor colorWithWhite:0.85f alpha:1.0f];
    }
    else {
        _buttonBackgroundColor              = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _buttonTextColor                    = [UIColor colorWithWhite:0.0f alpha:1.0f];
        _buttonTappedBackgroundColor        = [UIColor colorWithRed:82.0f/255.0f green:200.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
        _buttonTappedTextColor              = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _cancelButtonBackgroundColor        = [UIColor colorWithWhite:0.3f alpha:1.0f];
        _cancelButtonTextColor              = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _cancelButtonTappedBackgroundColor  = [UIColor colorWithWhite:0.25f alpha:1.0f];
        _cancelButtonTappedTextColor        = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _destructiveButtonBackgroundColor   = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f];
        _destructiveButtonTextColor         = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _destructiveButtonTappedBackgroundColor = [UIColor colorWithRed:0.8f green:0.0f blue:0.0f alpha:1.0f];
        _destructiveButtonTappedTextColor   = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _buttonSeparatorColor               = [UIColor colorWithWhite:0.9f alpha:1.0f];
        _headerBackgroundColor              = [UIColor colorWithWhite:0.95f alpha:1.0f];
        _dimmingViewAlpha                   = 0.3f;
        _titleColor                         = [UIColor blackColor];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setUpContainerWidth];

    CGFloat contentInset = 0.0f;
    if (@available(iOS 11.0, *)) {
        contentInset = self.safeAreaInsets.bottom;
    }

    CGRect frame = CGRectZero;
    if (self.compactLayout) {
        self.arrowImageView.hidden = YES;

        frame = self.cancelButton.frame;
        frame.size.width = self.width;
        frame.origin.x = (self.frame.size.width - frame.size.width) * 0.5f;
        frame.origin.y = (self.frame.size.height - (kTOActionSheetCompactMargin + contentInset)) - frame.size.height;
        self.cancelButton.frame = frame;
        
        frame = self.containerView.frame;
        frame.size.width = self.width;
        frame.origin.x = (self.frame.size.width - frame.size.width) * 0.5f;
        frame.origin.y = (self.cancelButton.frame.origin.y - kTOActionSheetCompactMargin) - frame.size.height;
        self.containerView.frame = frame;
    }
    else {
        //make sure the frame is reset to standard
        frame = self.containerView.frame;
        frame.size.width = self.width;
        self.containerView.frame = frame;
        
        CGRect presentationRect = self.presentationRect;
        TOActionSheetArrowDirection direction = [self bestArrowDirectionForPresentationRect:presentationRect];
        if (direction != self.arrowDirection) {
            if (self.arrowImageView == nil) {
                self.arrowImageView = [[UIImageView alloc] init];
                [self.containerView addSubview:self.arrowImageView];
            }
            
            self.arrowDirection = direction;
            self.arrowImageView.image = [self arrowImageForDirection:direction color:[self bestColorForArrowWithDirection:self.arrowDirection]];
            self.arrowImageView.frame = (CGRect){CGPointZero, self.arrowImageView.image.size};
        }
        
        self.arrowImageView.hidden = NO;
        self.containerView.frame = [self frameOfContainerViewWithArrowDirection:self.arrowDirection presentationRect:presentationRect];
        self.arrowImageView.frame = [self frameOfArrowViewWithDirection:self.arrowDirection presentationRect:presentationRect];
    }
    
    self.cancelButton.hidden = !self.compactLayout;
}

- (void)deviceWillChangeOrientation:(NSNotification *)notification
{
    if (self.compactLayout)
        return;
    
    [self presentViewAfterSizeTransition];
}

- (void)presentViewAfterSizeTransition
{
    self.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        self.hidden = NO;
        self.alpha = 0.0f;
        [UIView animateWithDuration:0.1f animations:^{
            self.alpha = 1.0f;
        }];
    });
}

#pragma mark - Image Rendering -
- (UIImage *)buttonBackgroundImageWithColor:(UIColor *)color roundedTop:(BOOL)roundedTop roundedBottom:(BOOL)roundedBottom
{
    //Set canvas size
    CGRect rect = CGRectMake(0, 0, (kTOActionSheetBorderRadius * 2) + 1, (kTOActionSheetBorderRadius * 2) + 1);
    
    //Calculate which corners need rounding
    UIRectCorner corners = 0;
    if (roundedTop)
        corners |= (UIRectCornerTopLeft | UIRectCornerTopRight);
    
    if (roundedBottom)
        corners |= (UIRectCornerBottomLeft | UIRectCornerBottomRight);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:corners
                                                     cornerRadii:(CGSize){kTOActionSheetBorderRadius, kTOActionSheetBorderRadius}];
    
    //Render the image
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    {
        [color setFill];
        [path fill];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    //Set the image as resizable and return
    UIEdgeInsets edgeInsets = (UIEdgeInsets){kTOActionSheetBorderRadius, kTOActionSheetBorderRadius, kTOActionSheetBorderRadius, kTOActionSheetBorderRadius};
    return [image resizableImageWithCapInsets:edgeInsets];
}

- (UIImage *)buttonBackgroundImageWithColor:(UIColor *)color
{
    CGRect rect = (CGRect){0,0,1,1};
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    {
        [color setFill];
        CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)arrowImageForDirection:(TOActionSheetArrowDirection)direction color:(UIColor *)color
{
    CGSize size = CGSizeZero;
    if (direction == TOActionSheetArrowDirectionDown || direction == TOActionSheetArrowDirectionUp)
        size = (CGSize){kTOActionSheetArrowBase, kTOActionSheetArrowHeight};
    else
        size = (CGSize){kTOActionSheetArrowHeight, kTOActionSheetArrowBase};
    
    CGRect arrowRect = (CGRect){CGPointZero, size};
    
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGMutablePathRef arrowPath = CGPathCreateMutable();
        
        switch (direction) {
            case TOActionSheetArrowDirectionDown:
                CGPathMoveToPoint(arrowPath, NULL, CGRectGetMinX(arrowRect), CGRectGetMinY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMinX(arrowRect)+10.0f, CGRectGetMinY(arrowRect),
                                      CGRectGetMidX(arrowRect)-6.0f, CGRectGetMaxY(arrowRect),
                                      CGRectGetMidX(arrowRect), CGRectGetMaxY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMidX(arrowRect)+6.0f, CGRectGetMaxY(arrowRect),
                                      CGRectGetMaxX(arrowRect)-10.0f, CGRectGetMinY(arrowRect),
                                      CGRectGetMaxX(arrowRect), CGRectGetMinY(arrowRect));
                
                break;
            case TOActionSheetArrowDirectionUp:
                CGPathMoveToPoint(arrowPath, NULL, CGRectGetMinX(arrowRect), CGRectGetMaxY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMinX(arrowRect)+10.0f, CGRectGetMaxY(arrowRect),
                                      CGRectGetMidX(arrowRect)-6.0f, CGRectGetMinY(arrowRect),
                                      CGRectGetMidX(arrowRect), CGRectGetMinY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMidX(arrowRect)+6.0f, CGRectGetMinY(arrowRect),
                                      CGRectGetMaxX(arrowRect)-10.0f, CGRectGetMaxY(arrowRect),
                                      CGRectGetMaxX(arrowRect), CGRectGetMaxY(arrowRect));
                break;
            case TOActionSheetArrowDirectionRight:
                CGPathMoveToPoint(arrowPath, NULL, CGRectGetMinX(arrowRect), CGRectGetMinY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMinX(arrowRect), CGRectGetMinY(arrowRect)+10.0f,
                                      CGRectGetMaxX(arrowRect), CGRectGetMidY(arrowRect)-6.0f,
                                      CGRectGetMaxX(arrowRect), CGRectGetMidY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMaxX(arrowRect), CGRectGetMidY(arrowRect)+6.0f,
                                      CGRectGetMinX(arrowRect), CGRectGetMaxY(arrowRect)-10.0f,
                                      CGRectGetMinX(arrowRect), CGRectGetMaxY(arrowRect));
                break;
            case TOActionSheetArrowDirectionLeft:
            default:
                CGPathMoveToPoint(arrowPath, NULL, CGRectGetMaxX(arrowRect), CGRectGetMinY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMaxX(arrowRect), CGRectGetMinY(arrowRect)+10.0f,
                                      CGRectGetMinX(arrowRect), CGRectGetMidY(arrowRect)-6.0f,
                                      CGRectGetMinX(arrowRect), CGRectGetMidY(arrowRect));
                CGPathAddCurveToPoint(arrowPath, NULL,
                                      CGRectGetMinX(arrowRect), CGRectGetMidY(arrowRect)+6.0f,
                                      CGRectGetMaxX(arrowRect), CGRectGetMaxY(arrowRect)-10.0f,
                                      CGRectGetMaxX(arrowRect), CGRectGetMaxY(arrowRect));
                
                break;
        }
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextAddPath(context, arrowPath);
        CGContextFillPath(context);
        
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Action Sheet Views Set-up -
- (void)setUpRegularButtons
{
    CGRect buttonFrame = (CGRect){0,0,self.width,kTOActionSheetButtonHeight};
    
    // See if we need to generate graphics for buttons in-between the top and bottom rounded ones
    NSInteger numberOfElements = 0;
    if (self.headerView || self.title.length)
        numberOfElements++;
    
    numberOfElements += self.buttonTitles.count;
    
    if (self.destructiveTitle)
        numberOfElements++;
    
    UIImage *regularBG = nil;
    UIImage *regularTappedBG = nil;
    if (numberOfElements >= 3) {
        regularBG = [self buttonBackgroundImageWithColor:self.buttonBackgroundColor];
        regularTappedBG = [self buttonBackgroundImageWithColor:self.buttonTappedBackgroundColor];
    }
    
    //Set up each of the regular buttons
    NSInteger i = 0;
    self.buttonViews = [NSMutableArray array];
    for (NSString *title in self.buttonTitles) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(buttonTapDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
        [button addTarget:self action:@selector(buttonTapUp:) forControlEvents:UIControlEventTouchDragExit|UIControlEventTouchUpInside];
        [self.buttonViews addObject:button];
        
        button.frame = buttonFrame;
        button.titleLabel.font = self.buttonFont;
        
        [button setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
        [button setTitleColor:self.buttonTappedTextColor forState:UIControlStateHighlighted];
        [button setTitle:title forState:UIControlStateNormal];
        
        if (self.contentstyle == TOActionSheetContentStyleLeft) {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        } else if (self.contentstyle == TOActionSheetContentStyleRight) {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        } else {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        }
        
        if (self.buttonIcons.count && [self.buttonIcons objectAtIndex:i] != nil) {
            UIImage *icon = [[self.buttonIcons objectAtIndex:i] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *image = [[UIImageView alloc] initWithImage:icon];
            image.tag = 123;
            image.tintColor = self.buttonTextColor;
            CGFloat size = (button.frame.size.height-image.frame.size.height)/2;
            if (self.contentstyle == TOActionSheetContentStyleRight) {
                image.frame = (CGRect){button.frame.size.width-(10+image.frame.size.width), size, image.frame.size.width, image.frame.size.height};
            } else {
                image.frame = (CGRect){size, size, image.frame.size.width, image.frame.size.height};
            }
            [button addSubview:image];
            
            if (self.contentstyle == TOActionSheetContentStyleLeft) {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 50, 0, 0)];
            } else if (self.contentstyle == TOActionSheetContentStyleRight) {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
            }
        }
        
        if (i == 0 && self.buttonTitles.count > 1 && (self.title.length == 0 && self.headerView == nil)) {
            UIImage *background = [self buttonBackgroundImageWithColor:self.buttonBackgroundColor roundedTop:YES roundedBottom:NO];
            UIImage *backgroundPressed = [self buttonBackgroundImageWithColor:self.buttonTappedBackgroundColor roundedTop:YES roundedBottom:NO];
            [button setBackgroundImage:background forState:UIControlStateNormal];
            [button setBackgroundImage:backgroundPressed forState:UIControlStateHighlighted];
        }
        else if (i >= self.buttonTitles.count-1 && self.destructiveTitle.length == 0) {
            UIImage *background = [self buttonBackgroundImageWithColor:self.buttonBackgroundColor roundedTop:NO roundedBottom:YES];
            UIImage *backgroundPressed = [self buttonBackgroundImageWithColor:self.buttonTappedBackgroundColor roundedTop:NO roundedBottom:YES];
            [button setBackgroundImage:background forState:UIControlStateNormal];
            [button setBackgroundImage:backgroundPressed forState:UIControlStateHighlighted];
        }
        else {
            [button setBackgroundImage:regularBG forState:UIControlStateNormal];
            [button setBackgroundImage:regularTappedBG forState:UIControlStateHighlighted];
        }
        
        i++;
    }
}

- (void)setUpCancelButton
{
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.cancelButton.frame = (CGRect){0,0,self.width,kTOActionSheetButtonHeight};
    [self.cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = self.cancelButtonFont;
    
    UIImage *backgroundImage = [self buttonBackgroundImageWithColor:self.cancelButtonBackgroundColor roundedTop:YES roundedBottom:YES];
    [self.cancelButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:self.cancelButtonTextColor forState:UIControlStateNormal];
    
    UIImage *backgroundTappedImage = [self buttonBackgroundImageWithColor:self.cancelButtonTappedBackgroundColor roundedTop:YES roundedBottom:YES];
    [self.cancelButton setBackgroundImage:backgroundTappedImage forState:UIControlStateHighlighted];
    [self.cancelButton setTitleColor:self.cancelButtonTappedTextColor forState:UIControlStateHighlighted];
    
    [self.cancelButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.cancelButton];
}

- (void)setUpDestructiveButton
{
    if (self.destructiveTitle.length == 0)
        return;
    
    self.destructiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.destructiveButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.destructiveButton.frame = (CGRect){0,0,self.width,kTOActionSheetButtonHeight};
    [self.destructiveButton setTitle:self.destructiveTitle forState:UIControlStateNormal];
    [self.destructiveButton setTitleColor:self.destructiveButtonTextColor forState:UIControlStateNormal];
    [self.destructiveButton setTitleColor:self.destructiveButtonTappedTextColor forState:UIControlStateHighlighted];
    self.destructiveButton.titleLabel.font = self.buttonFont;
    
    if (self.contentstyle == TOActionSheetContentStyleLeft) {
        self.destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    } else if (self.contentstyle == TOActionSheetContentStyleRight) {
        self.destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    } else {
        self.destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    
    if (self.destructiveIcon != nil) {
        UIImage *icon = [self.destructiveIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *image = [[UIImageView alloc] initWithImage:icon];
        image.tintColor = self.destructiveButtonTextColor;
        CGFloat size = (self.destructiveButton.frame.size.height-image.frame.size.height)/2;
        if (self.contentstyle == TOActionSheetContentStyleRight) {
            image.frame = (CGRect){self.destructiveButton.frame.size.width-(10+image.frame.size.width), size, image.frame.size.width, image.frame.size.height};
        } else {
            image.frame = (CGRect){size, size, image.frame.size.width, image.frame.size.height};
        }
        [self.destructiveButton addSubview:image];
        
        if (self.contentstyle == TOActionSheetContentStyleLeft) {
            [self.destructiveButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 50, 0, 0)];
        } else if (self.contentstyle == TOActionSheetContentStyleRight) {
            [self.destructiveButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        }
    }
    
    BOOL roundedTop = (self.buttonTitles.count == 0 && self.headerView == nil && self.title.length == 0);
    UIImage *backgroundImage = [self buttonBackgroundImageWithColor:self.destructiveButtonBackgroundColor roundedTop:roundedTop roundedBottom:YES];
    [self.destructiveButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    
    UIImage *backgroundTappedImage = [self buttonBackgroundImageWithColor:self.destructiveButtonTappedBackgroundColor roundedTop:roundedTop roundedBottom:YES];
    [self.destructiveButton setBackgroundImage:backgroundTappedImage forState:UIControlStateHighlighted];
    
    [self.destructiveButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpSeparators
{
    NSInteger numberOfSeparators = 0;
    if (self.headerView || self.title.length)
        numberOfSeparators++;
    
    numberOfSeparators += (self.buttonTitles.count - 1);
    
    CGFloat lineHeight = 1.0f / [[UIScreen mainScreen] scale];
    
    self.separatorViews = [NSMutableArray array];
    for (NSInteger i = 0; i < numberOfSeparators; i++) {
        UIView *separatorView = [[UIView alloc] initWithFrame:(CGRect){0,0,self.width,lineHeight}];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        separatorView.backgroundColor = self.buttonSeparatorColor;
        [self.separatorViews addObject:separatorView];
    }
}

- (void)setUpHeaderView
{
    if (self.headerView == nil && self.title.length == 0)
        return;
    
    UIImage *backgroundImage = [self buttonBackgroundImageWithColor:self.headerBackgroundColor roundedTop:YES roundedBottom:NO];
    self.headerBackgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.headerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //Set up if a header view was supplied
    CGRect frame = CGRectZero;
    if (self.headerView) {
        frame = self.headerView.frame;
        frame.size.width = self.width;
        frame.origin = CGPointZero;
        self.headerView.frame = frame;
        self.headerBackgroundView.frame = frame;
        [self.headerBackgroundView addSubview:self.headerView];
        self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    else if (self.title) { //set up a title label if just a title was supplied
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = self.title;
        titleLabel.font = self.titleFont;
        titleLabel.textColor = self.titleColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 0;
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        frame = titleLabel.frame;
        frame.size = [titleLabel sizeThatFits:(CGSize){self.width-(kTOActionSheetTitlePadding*2.0f), NSIntegerMax}];
        frame.origin = (CGPoint){kTOActionSheetTitlePadding, kTOActionSheetTitlePadding};
        
        CGRect backgroundFrame = self.headerBackgroundView.frame;
        backgroundFrame.size.width = self.width;
        backgroundFrame.size.height = frame.size.height + (kTOActionSheetTitlePadding * 2.0f);
        self.headerBackgroundView.frame = backgroundFrame;
        
        frame.origin.x = floorf((backgroundFrame.size.width - frame.size.width) * 0.5f);
        frame.origin.y = floorf((backgroundFrame.size.height - frame.size.height) * 0.5f);
        titleLabel.frame = frame;
        
        [self.headerBackgroundView addSubview:titleLabel];
    }
}

- (void)setUpContainerWidth
{
    if (self.compactLayout == NO) {
        self.width = kTOActionSheetDefaultWidth;
        return;
    }
    
    CGFloat width = MIN(self.frame.size.width, self.frame.size.height);
    width -= 20.0f; //10 point padding on either side
    
    if (self.maximumCompactWidth > FLT_EPSILON)
        width = MIN(self.maximumCompactWidth,width);
    
    self.width = width;
}

- (void)setUpContainer
{
    //Create the container
    self.containerView = [[UIView alloc] init];
    CGRect frame = CGRectZero;
    frame.size.width = self.width;
    frame.size.height += self.headerBackgroundView.frame.size.height;
    frame.size.height += (self.buttonTitles.count * kTOActionSheetButtonHeight);
    frame.size.height += (self.destructiveButton.frame.size.height);
    self.containerView.frame = frame;
    
    //Lay out the elements in the container
    CGFloat height = 0.0f;
    
    //Add the header view
    if (self.headerBackgroundView) {
        [self.containerView addSubview:self.headerBackgroundView];
        height += self.headerBackgroundView.frame.size.height;
    }
    
    //Add the regular buttons
    for (UIButton *button in self.buttonViews) {
        frame = button.frame;
        frame.origin.y = height;
        button.frame = frame;
        [self.containerView addSubview:button];
        height += frame.size.height;
    }
    
    //Add the destructive button
    if (self.destructiveButton) {
        frame = self.destructiveButton.frame;
        frame.origin.y = height;
        self.destructiveButton.frame = frame;
        [self.containerView addSubview:self.destructiveButton];
    }
    
    //Add the separators
    if (self.headerBackgroundView)
        height = self.headerBackgroundView.frame.size.height;
    else
        height = kTOActionSheetButtonHeight;
        
    for (UIView *separatorView in self.separatorViews) {
        frame = separatorView.frame;
        frame.origin.y = height;
        separatorView.frame = frame;
        height += kTOActionSheetButtonHeight;
        [self.containerView addSubview:separatorView];
    }
    
    [self addSubview:self.containerView];
}

- (void)setUpDimmingView
{
    self.frame = self.parentView.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:self.dimmingViewAlpha];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimmingViewTapped:)]];
    [self.parentView addSubview:self];
}

#pragma mark - View Display -
- (void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem inView:(UIView *)view
{
    self.targetButtonItem = barButtonItem;
    self.parentView = view;
    [self show];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view
{
    self.targetRect = rect;
    self.parentView = view;
    [self show];
}

- (void)showFromView:(UIView *)fromView inView:(UIView *)view
{
    self.targetView = fromView;
    self.parentView = view;
    [self show];
}

- (void)show
{
    //Ensure no errors occur if presented twice
    if (self.containerView)
        return;
    
    //Set up ourselves
    [self setUpDimmingView];
    
    //Set up the width of the container
    [self setUpContainerWidth];
    
    //Set up various views in the container
    [self setUpRegularButtons];
    [self setUpCancelButton];
    [self setUpDestructiveButton];
    [self setUpHeaderView];
    [self setUpSeparators];
    [self setUpContainer];
    
    //Force a layout now to update the state
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    //Present the views
    if (self.compactLayout)
        [self presentViewWithCompactAnimation];
    else
        [self presentViewWithRegularAnimation];
}

- (void)presentViewWithCompactAnimation
{
    CGFloat offset = self.frame.size.height - self.containerView.frame.origin.y;

    CGRect containerFrame = self.containerView.frame;
    self.containerView.frame = CGRectOffset(self.containerView.frame, 0.0f, offset);
    
    CGRect cancelButtonFrame = self.cancelButton.frame;
    self.cancelButton.frame = CGRectOffset(self.cancelButton.frame, 0.0f, offset);
    
    //Animate the container view
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.containerView.frame = containerFrame;
    } completion:nil];
    
    //animate the cancel button
    [UIView animateWithDuration:0.4f delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.cancelButton.frame = cancelButtonFrame;
    } completion:nil];
    
    //animate the dimming view
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.4f animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:self.dimmingViewAlpha];
    }];
}

- (void)dismissViewWithCompactAnimation
{
    CGFloat offset = self.frame.size.height - self.containerView.frame.origin.y;
    
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.5f options:0 animations:^{
        self.containerView.frame = CGRectOffset(self.containerView.frame, 0.0f, offset);
        self.cancelButton.frame = CGRectOffset(self.cancelButton.frame, 0.0f, offset);
        self.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL complete) {
        [self removeFromSuperview];
        if (self.actionSheetDismissedBlock)
            self.actionSheetDismissedBlock();
    }];
}

- (void)presentViewWithRegularAnimation
{
    CGPoint anchorPoint = (CGPoint){0.5f, 0.5f};
    switch (self.arrowDirection) {
        case TOActionSheetArrowDirectionDown:
            anchorPoint.x = CGRectGetMidX(self.arrowImageView.frame) / CGRectGetWidth(self.containerView.frame);
            anchorPoint.y = 1.0f;
            break;
        case TOActionSheetArrowDirectionLeft:
            anchorPoint.y = CGRectGetMidY(self.arrowImageView.frame) / CGRectGetHeight(self.containerView.frame);
            anchorPoint.x = 0.0f;
            break;
        case TOActionSheetArrowDirectionUp:
            anchorPoint.x = CGRectGetMidX(self.arrowImageView.frame) / CGRectGetWidth(self.containerView.frame);
            anchorPoint.y = 0.0f;
            break;
        case TOActionSheetArrowDirectionRight:
            anchorPoint.y = CGRectGetMidY(self.arrowImageView.frame) / CGRectGetHeight(self.containerView.frame);
            anchorPoint.x = 1.0f;
            break;
        default: break;
    }
    
    self.containerView.layer.anchorPoint = anchorPoint;
    self.containerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.0f, 0.0f);
    
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.containerView.transform = CGAffineTransformIdentity;
                     } completion:nil];
    
    //animate the dimming view
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.4f animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:self.dimmingViewAlpha];
    }];
}

- (void)dismissViewWithRegularAnimation
{
    [UIView animateWithDuration:0.25f animations:^{
        self.containerView.alpha = 0.0f;
        self.backgroundColor = [UIColor clearColor];
     } completion:^(BOOL complete) {
         [self removeFromSuperview];
         if (self.actionSheetDismissedBlock)
             self.actionSheetDismissedBlock();
     }];
}

#pragma mark - User Interaction -
- (void)buttonTapped:(id)sender
{
    if (sender == self.cancelButton) {
        if (self.cancelButtonTappedBlock)
            self.cancelButtonTappedBlock();
    }
    else if (sender == self.destructiveButton) {
        if (self.destructiveBlock)
            self.destructiveBlock();
    }
    else {
        NSInteger index = [self.buttonViews indexOfObject:sender];
        [sender viewWithTag:123].tintColor = self.buttonTappedTextColor;
        if (index != NSNotFound) {
            void (^buttonBlock)() = self.buttonBlocks[index];
            buttonBlock();
        }
    }
    
    if (self.compactLayout)
        [self dismissViewWithCompactAnimation];
    else
        [self dismissViewWithRegularAnimation];
}

- (void)buttonTapDown:(id)sender
{
    [sender viewWithTag:123].tintColor = self.buttonTappedTextColor;
    //Hide the separators around the button that was tapped
    NSInteger buttonIndex = [self.buttonViews indexOfObject:sender];
    if (buttonIndex == NSNotFound)
        return;
    
    NSInteger firstIndex = buttonIndex-1;
    NSInteger secondIndex = buttonIndex;
    if (self.headerIsVisible) {
        firstIndex++;
        secondIndex++;
    }
    
    if (firstIndex >= 0)
        [self.separatorViews[firstIndex] setHidden:YES];
    
    if (secondIndex >= 0 && secondIndex < self.separatorViews.count)
        [self.separatorViews[secondIndex] setHidden:YES];
}

- (void)buttonTapUp:(id)sender
{
    [sender viewWithTag:123].tintColor = self.buttonTextColor;
    for (UIView *view in self.separatorViews)
        view.hidden = NO;
}

- (void)dimmingViewTapped:(UIGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self];
    
    if (CGRectContainsPoint(self.containerView.frame, tapPoint))
        return;
    
    if (self.compactLayout)
        [self dismissViewWithCompactAnimation];
    else
        [self dismissViewWithRegularAnimation];
}

#pragma mark - Button Configuration -
- (void)addButtonWithTitle:(NSString *)title icon:(UIImage *)icon tappedBlock:(void (^)(void))tappedBlock
{
    if (self.buttonIcons == nil) {
        self.buttonIcons = [NSMutableArray array];
    }

    if (icon != nil) {
        [self.buttonIcons insertObject:icon atIndex:self.buttonTitles.count];
    }

    [self addButtonWithTitle:title atIndex:self.buttonTitles.count tappedBlock:tappedBlock];
}

- (void)addButtonWithTitle:(NSString *)title tappedBlock:(void (^)(void))tappedBlock
{
    [self addButtonWithTitle:title atIndex:self.buttonTitles.count tappedBlock:tappedBlock];
}

- (void)addButtonWithTitle:(NSString *)title atIndex:(NSInteger)index tappedBlock:(void (^)(void))tappedBlock
{
    if (title.length == 0 || tappedBlock == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"TOActionSheet: Buttons must have both a block and a title."];
    }
    
    if (self.buttonTitles == nil)
        self.buttonTitles = [NSMutableArray array];
    
    if (self.buttonBlocks == nil)
        self.buttonBlocks = [NSMutableArray array];

    [self.buttonTitles insertObject:title atIndex:index];
    [self.buttonBlocks insertObject:tappedBlock atIndex:index];
}

- (void)removeButtonAtIndex:(NSInteger)index
{
    [self.buttonTitles removeObjectAtIndex:index];
    [self.buttonBlocks removeObjectAtIndex:index];
}

- (void)addDestructiveButtonWithTitle:(NSString *)title icon:(UIImage *)image tappedBlock:(void (^)(void))tappedBlock
{
    if (title.length == 0 || tappedBlock == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"TOActionSheet: Buttons must have both a block and a title."];
    }
    
    
    self.destructiveIcon = image;
    self.destructiveTitle = title;
    self.destructiveBlock = tappedBlock;
}

- (void)addDestructiveButtonWithTitle:(NSString *)title tappedBlock:(void (^)(void))tappedBlock
{
    if (title.length == 0 || tappedBlock == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"TOActionSheet: Buttons must have both a block and a title."];
    }
    
    self.destructiveTitle = title;
    self.destructiveBlock = tappedBlock;
}

- (void)removeDestructiveButton
{
    self.destructiveTitle = nil;
    self.destructiveBlock = nil;
}

#pragma mark - Layout Calculation -
- (BOOL)compactLayout
{
    //iOS 7
    if ([self respondsToSelector:NSSelectorFromString(@"traitCollection")] == NO)
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    //iOS 8+
    UITraitCollection *traitCollection = self.parentView.traitCollection;
    if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return YES;
    
    return (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
}

- (BOOL)headerIsVisible
{
    return self.headerView || self.title.length > 0;
}

- (CGRect)presentationRect
{
    if (CGRectIsEmpty(self.targetRect) == NO)
        return self.targetRect;
    
    if (self.targetView) {
        CGRect frame = self.targetView.frame;
        return [self.targetView.superview convertRect:frame toView:self];
    }
    
    if (self.targetButtonItem) {
        UIView *view = [self.targetButtonItem valueForKey:@"view"];
        if (view) {
            CGRect frame = view.frame;
            return [self.targetView.superview convertRect:frame toView:self];
        }
    }
    
    return CGRectZero;
}

- (TOActionSheetArrowDirection)bestArrowDirectionForPresentationRect:(CGRect)presentationRect
{
    //Work out the total size
    CGFloat height = CGRectGetHeight(self.containerView.frame) + kTOActionSheetArrowHeight;
    CGFloat width = kTOActionSheetDefaultWidth + kTOActionSheetArrowHeight;
    
    //Go in a counter-clockwise direction
    if (CGRectGetMinY(presentationRect) - height > 0)
        return TOActionSheetArrowDirectionDown; //Appears on top
    else if (CGRectGetMinX(presentationRect) - width > 0)
        return TOActionSheetArrowDirectionRight; //Left hand side
    else if (CGRectGetMaxX(presentationRect) + width <= CGRectGetWidth(self.frame))
        return TOActionSheetArrowDirectionLeft;
    else if (CGRectGetMaxY(presentationRect) + width <= CGRectGetHeight(self.frame))
        return TOActionSheetArrowDirectionUp;

    return TOActionSheetArrowDirectionNone;
}

- (CGRect)frameOfContainerViewWithArrowDirection:(TOActionSheetArrowDirection)direction presentationRect:(CGRect)presentationRect
{
    CGRect frame = self.containerView.frame;
    CGSize boundSize = self.bounds.size;
    
    switch (direction) {
        case TOActionSheetArrowDirectionDown:
            frame.origin.y = CGRectGetMinY(presentationRect) - (CGRectGetHeight(frame) + kTOActionSheetArrowHeight);
            frame.origin.x = CGRectGetMidX(presentationRect) - (CGRectGetWidth(frame) * 0.5f);
            break;
        case TOActionSheetArrowDirectionRight:
            frame.origin.y = CGRectGetMidY(presentationRect) - (CGRectGetHeight(frame) * 0.5f);
            frame.origin.x = CGRectGetMinX(presentationRect) - (CGRectGetWidth(frame) + kTOActionSheetArrowHeight);
            break;
        case TOActionSheetArrowDirectionUp:
            frame.origin.y = CGRectGetMaxY(presentationRect) + kTOActionSheetArrowHeight;
            frame.origin.x = CGRectGetMidX(presentationRect) - (CGRectGetWidth(frame) * 0.5f);
            break;
        case TOActionSheetArrowDirectionLeft:
            frame.origin.y = CGRectGetMidY(presentationRect) - (CGRectGetHeight(frame) * 0.5f);
            frame.origin.x = CGRectGetMaxX(presentationRect) + kTOActionSheetArrowHeight;
            break;
        default:
            break;
    }
    
    //make sure the frame doens't leave the container bounds
    if (frame.origin.x < kTOActionSheetScreenPadding)
        frame.origin.x = kTOActionSheetScreenPadding;
    
    if (frame.origin.y < kTOActionSheetScreenPadding)
        frame.origin.y = kTOActionSheetScreenPadding;
    
    if (CGRectGetMaxX(frame) > (boundSize.width - kTOActionSheetScreenPadding))
        frame.origin.x = (boundSize.width - kTOActionSheetScreenPadding) - CGRectGetWidth(frame);
    
    if (CGRectGetMaxY(frame) > (boundSize.height - kTOActionSheetScreenPadding))
        frame.origin.y = (boundSize.height - kTOActionSheetScreenPadding) - CGRectGetHeight(frame);
    
    return frame;
}

- (CGRect)frameOfArrowViewWithDirection:(TOActionSheetArrowDirection)direction presentationRect:(CGRect)presentationRect
{
    CGRect frame = self.arrowImageView.frame;
    CGRect containerFrame = self.containerView.frame;
    CGRect containerBounds = self.containerView.bounds;
    CGFloat offset = 0.0f;
    
    switch (direction) {
        case TOActionSheetArrowDirectionDown:
            frame.origin.y = CGRectGetHeight(containerFrame);
            
            offset = CGRectGetMidX(presentationRect) - CGRectGetMidX(containerFrame);
            frame.origin.x = (CGRectGetMidX(containerBounds) - (CGRectGetWidth(frame) * 0.5f)) + offset;
            
            break;
        case TOActionSheetArrowDirectionRight:
            offset = CGRectGetMidY(presentationRect) - CGRectGetMidY(containerFrame);
            frame.origin.y = (CGRectGetMidY(containerBounds) - (CGRectGetHeight(frame) * 0.5f)) + offset;
            frame.origin.x = CGRectGetWidth(containerBounds);
            break;
        case TOActionSheetArrowDirectionUp:
            frame.origin.y = -kTOActionSheetArrowHeight;
            
            offset = CGRectGetMidX(presentationRect) - CGRectGetMidX(containerFrame);
            frame.origin.x = (CGRectGetMidX(containerBounds) - (CGRectGetWidth(frame) * 0.5f)) + offset;
            break;
        case TOActionSheetArrowDirectionLeft:
            offset = CGRectGetMidY(presentationRect) - CGRectGetMidY(containerFrame);
            frame.origin.y = (CGRectGetMidY(containerBounds) - (CGRectGetHeight(frame) * 0.5f)) + offset;
            frame.origin.x = -kTOActionSheetArrowHeight;
            break;
        default:
            break;
    }
    
    //Cap the arrow so it doesn't go beyond the curved edges of the container view
    if (direction == TOActionSheetArrowDirectionDown || direction == TOActionSheetArrowDirectionUp) {
        frame.origin.x = MAX(kTOActionSheetBorderRadius, frame.origin.x);
        CGFloat minX = (CGRectGetWidth(containerBounds) - kTOActionSheetBorderRadius) - kTOActionSheetArrowBase;
        frame.origin.x = MIN(minX, frame.origin.x);
    }
    else if (direction == TOActionSheetArrowDirectionLeft || direction == TOActionSheetArrowDirectionRight) {
        frame.origin.y = MAX(kTOActionSheetBorderRadius, frame.origin.y);
        CGFloat minY = (CGRectGetHeight(containerBounds) - kTOActionSheetBorderRadius) - kTOActionSheetArrowBase;
        frame.origin.y = MIN(minY, frame.origin.y);
    }
    
    return frame;
}

- (UIColor *)bestColorForArrowWithDirection:(TOActionSheetArrowDirection)direction
{
    switch (direction) {
        case TOActionSheetArrowDirectionDown:
            if (self.destructiveTitle)
                return self.destructiveButtonBackgroundColor;
            
            if (self.buttonTitles.count)
                return self.buttonBackgroundColor;
            
            return self.headerBackgroundColor;
            break;
        case TOActionSheetArrowDirectionLeft:
        case TOActionSheetArrowDirectionRight:
            return self.buttonBackgroundColor;
        case TOActionSheetArrowDirectionUp:
            if (self.headerView || self.title.length)
                return self.headerBackgroundColor;
            
            return self.buttonBackgroundColor;
        default:
            break;
    }
    
    return nil;
}

#pragma mark - Accessors -
- (void)setStyle:(TOActionSheetStyle)style
{
    if (style == _style)
        return;
    
    _style = style;
    [self setColorsForStyle:_style];
}

@end
