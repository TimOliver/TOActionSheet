//
//  TOActionSheet.h
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TOActionSheetStyle) {
    TOActionSheetStyleLight,
    TOActionSheetStyleDark
};

@interface TOActionSheet : UIView

/**
 The title text that will appear at the top of the action sheet.
 */
@property (nonatomic, strong) NSString *title;

/**
 A custom view that will appear along the top of the action sheet.
 */
@property (nonatomic, strong) UIView *headerView;

/**
 The default style of this action sheet; whether light or dark.
 */
@property (nonatomic, assign) TOActionSheetStyle style UI_APPEARANCE_SELECTOR;

/** 
 The alpha value of the dimming view behind the action sheet
 */
@property (nonatomic, assign) CGFloat dimmingViewAlpha UI_APPEARANCE_SELECTOR;

/** 
 The maximum width of the action sheet when it is presented in compact mode
 */
@property (nonatomic, assign) CGFloat maximumCompactWidth;

/**
Optionally, the text for the 'Cancel' button.
*/
@property (nonatomic, copy) NSString *cancelButtonTitle;

/**
 Optionally, a block that will be executed when the 'Cancel' button is tapped.
 */
@property (nonatomic, copy) void (^cancelButtonTappedBlock)(void);

/**
 The font used for all of the buttons (minus the cancel button).
 */
@property (nonatomic, strong) UIFont *buttonFont UI_APPEARANCE_SELECTOR;

/**
 The font used for the cancel button.
 */
@property (nonatomic, strong) UIFont *cancelButtonFont UI_APPEARANCE_SELECTOR;

/**
 The background color of every standard button.
 */
@property (nonatomic, strong) UIColor *buttonBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The text color for each standard button.
 */
@property (nonatomic, strong) UIColor *buttonTextColor UI_APPEARANCE_SELECTOR;

/**
 The text color of buttons when tapped.
 */
@property (nonatomic, strong) UIColor *buttonTappedBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The text color for each standard button.
 */
@property (nonatomic, strong) UIColor *buttonTappedTextColor UI_APPEARANCE_SELECTOR;

/**
 The color of the separator lines between regular buttons
 */
@property (nonatomic, strong) UIColor *buttonSeparatorColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the cancel button.
 */
@property (nonatomic, strong) UIColor *cancelButtonBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The text color of the cancel button.
 */
@property (nonatomic, strong) UIColor *cancelButtonTextColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the cancel button.
 */
@property (nonatomic, strong) UIColor *cancelButtonTappedBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The text color of the cancel button.
 */
@property (nonatomic, strong) UIColor *cancelButtonTappedTextColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the destructive button.
 */
@property (nonatomic, strong) UIColor *destructiveButtonBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the destructive button.
 */
@property (nonatomic, strong) UIColor *destructiveButtonTextColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the destructive button.
 */
@property (nonatomic, strong) UIColor *destructiveButtonTappedBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The background color of the destructive button.
 */
@property (nonatomic, strong) UIColor *destructiveButtonTappedTextColor UI_APPEARANCE_SELECTOR;

/** 
 The background of the header view.
 */
@property (nonatomic, strong) UIColor *headerBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The background of the label in the title (Defaults to the button default color)
 */
@property (nonatomic, strong) UIColor *titleColor UI_APPEARANCE_SELECTOR;

/**
 The font used for the title text in the header
 */
@property (nonatomic, strong) UIFont *titleFont UI_APPEARANCE_SELECTOR;

/**
 Create a new instance of an action sheet, with the specified color style
 
 @param style The desired color style
 */
- (instancetype)initWithStyle:(TOActionSheetStyle)style;

/**
 Create a new instance of an action sheet, with a title as the top view
 
 @param title The title to display in the header view
 */
- (instancetype)initWithTitle:(NSString *)title;

/**
 Create a new instance of an action sheet with a custom view for the header
 
 @param headerView The view to display in the action sheet header
 */
- (instancetype)initWithHeaderView:(UIView *)headerView;

/**
 Add a standard button to the action sheet.
 @param title The title to display in the button
 @param tappedBlock A block that will be executed when the button is tapped
 */
- (void)addButtonWithTitle:(NSString *)title tappedBlock:(void (^)(void))tappedBlock;
- (void)addButtonWithTitle:(NSString *)title atIndex:(NSInteger)index tappedBlock:(void (^)(void))tappedBlock;
- (void)removeButtonAtIndex:(NSInteger)index;

- (void)addDestructiveButtonWithTitle:(NSString *)title tappedBlock:(void (^)(void))tappedBlock;
- (void)removeDestructiveButton;

- (void)showFromRect:(CGRect)rect inView:(UIView *)view;
- (void)showFromView:(UIView *)fromView inView:(UIView *)view;
- (void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem inView:(UIView *)view;

@end
