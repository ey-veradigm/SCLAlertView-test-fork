//
//  SCLAlertView.m
//  SCLAlertView
//
//  Created by Diogo Autilio on 9/26/14.
//  Copyright (c) 2014-2025 AnyKey Entertainment. All rights reserved.
//

#import "SCLAlertView.h"
#import "SCLAlertViewResponder.h"
#import "SCLAlertViewStyleKit.h"
#import "UIImage+ImageEffects.h"
#import "SCLAlertView+WindowResolver.h"
#import "SCLTimerDisplay.h"
#import "SCLMacros.h"

@import AVFoundation;
@import AudioToolbox;

#define DEFAULT_WINDOW_WIDTH 240

@interface SCLAlertView ()  <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray<UIView *> *inputs;
@property (strong, nonatomic) NSMutableArray<SCLTextView *> *textFields;
@property (strong, nonatomic) NSMutableArray<UIView *> *customViews;
@property (strong, nonatomic) NSMutableArray<SCLButton *> *buttons;
@property (strong, nonatomic) NSMapTable<UIView *, UIFont *> *baseFonts;
@property (strong, nonatomic) NSMapTable<UIView *, UIFont *> *scaledFonts;
@property (copy, nonatomic) NSAttributedString *baseAttributedText;
@property (copy, nonatomic) NSAttributedString *scaledAttributedText;
@property (strong, nonatomic) UIImageView *circleIconImageView;
@property (strong, nonatomic) UIView *circleView;
@property (strong, nonatomic) UIView *circleViewBackground;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIScrollView *contentScrollView;
@property (strong, nonatomic) UIImageView *backgroundView;
@property (strong, nonatomic) UITapGestureRecognizer *gestureRecognizer;
@property (strong, nonatomic) NSString *titleFontFamily;
@property (strong, nonatomic) NSString *bodyTextFontFamily;
@property (strong, nonatomic) NSString *buttonsFontFamily;
@property (strong, nonatomic) UIWindow *previousWindow;
@property (strong, nonatomic) UIWindow *SCLAlertWindow;
@property (copy, nonatomic) SCLDismissBlock dismissBlock;
@property (copy, nonatomic) SCLDismissAnimationCompletionBlock dismissAnimationCompletionBlock;
@property (copy, nonatomic) SCLShowAnimationCompletionBlock showAnimationCompletionBlock;
@property (weak, nonatomic) UIViewController *rootViewController;
@property (weak, nonatomic) id<UIGestureRecognizerDelegate> restoreInteractivePopGestureDelegate;
@property (assign, nonatomic) SystemSoundID soundID;
@property (assign, nonatomic) BOOL usingNewWindow;
@property (assign, nonatomic) BOOL restoreInteractivePopGestureEnabled;
@property (nonatomic) CGFloat backgroundOpacity;
@property (nonatomic) CGFloat titleFontSize;
@property (nonatomic) CGFloat bodyFontSize;
@property (nonatomic) CGFloat buttonsFontSize;
@property (nonatomic) CGFloat windowWidth;
@property (nonatomic) CGRect keyboardFrame;

@end

@implementation SCLAlertView

static const CGFloat kCircleHeight = 56.0f;
static const CGFloat kCircleHeightBackground = 62.0f;
static const CGFloat kActivityIndicatorHeight = 40.0f;

// Timer
NSTimer *durationTimer;
SCLTimerDisplay *buttonTimer;

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"NSCoding not supported"
                                 userInfo:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setupViewWindowWidth:DEFAULT_WINDOW_WIDTH];
    }
    return self;
}

- (instancetype)initWithWidth:(CGFloat)width
{
    self = [super init];
    if (self)
    {
        [self setupViewWindowWidth:width];
    }
    return self;
}

- (instancetype)initWithWindowWidth:(CGFloat)windowWidth
{
    self = [super init];
    if (self)
    {
        [self setupViewWindowWidth:windowWidth];
    }
    return self;
}

- (instancetype)initWithNewWindow
{
    self = [self initWithWindowWidth:DEFAULT_WINDOW_WIDTH];
    if(self)
    {
        [self setupNewWindow];
    }
    return self;
}

+ (instancetype)alertWithNewWindow
{
    return [[self alloc] initWithNewWindow];
}

- (instancetype)initWithNewWindowWidth:(CGFloat)windowWidth
{
    self = [self initWithWindowWidth:windowWidth];
    if(self)
    {
        [self setupNewWindow];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
    [self restoreInteractivePopGesture];
}

#pragma mark - Observers

- (void)addObservers
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    // Let UIKit propagate the new traits before measuring the visible alert.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.view setNeedsLayout];
        [weakSelf.view layoutIfNeeded];
    });
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (![self.traitCollection.preferredContentSizeCategory isEqualToString:previousTraitCollection.preferredContentSizeCategory]) {
        [self.view setNeedsLayout];
    }
}

#pragma mark - Setup View

- (void)setupViewWindowWidth:(CGFloat)windowWidth
{
    // Default values
    self.circleIconHeight = 20.0f;
    self.windowWidth = windowWidth;
    self.shouldDismissOnTapOutside = NO;
    self.usingNewWindow = NO;
    self.keyboardFrame = CGRectNull;
    self.hideAnimationType =  SCLAlertViewHideAnimationFadeOut;
    self.showAnimationType = SCLAlertViewShowAnimationSlideInFromTop;
    self.backgroundType = SCLAlertViewBackgroundShadow;
    self.tintTopCircle = YES;
    
    // Fonts
    _titleFontFamily = @"HelveticaNeue";
    _bodyTextFontFamily = @"HelveticaNeue";
    _buttonsFontFamily = @"HelveticaNeue-Bold";
    _titleFontSize = 20.0f;
    _bodyFontSize = 14.0f;
    _buttonsFontSize = 14.0f;
    
    // Init
    _labelTitle = [[UILabel alloc] init];
    _viewText = [[UITextView alloc] init];
    _viewText.accessibilityTraits = UIAccessibilityTraitStaticText;
    _contentView = [[UIView alloc] init];
    _contentScrollView = [[UIScrollView alloc] init];
    _contentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _contentScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _circleView = [[UIView alloc] init];
    _circleViewBackground = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kCircleHeightBackground, kCircleHeightBackground)];
    _circleIconImageView = [[UIImageView alloc] init];
    _backgroundView = [[UIImageView alloc] initWithFrame:[self mainScreenFrame]];
    _buttons = [[NSMutableArray alloc] init];
    _inputs = [[NSMutableArray alloc] init];
    _textFields = [[NSMutableArray alloc] init];
    _customViews = [[NSMutableArray alloc] init];
    _baseFonts = [NSMapTable weakToStrongObjectsMapTable];
    _scaledFonts = [NSMapTable weakToStrongObjectsMapTable];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.accessibilityViewIsModal = YES;
    
    // Add subviews
    [self.view addSubview:_contentView];
    [self.view addSubview:_circleViewBackground];
    
    // Circle view
    CGFloat x = (kCircleHeightBackground - kCircleHeight) / 2;
    _circleView.frame = CGRectMake(x, x, kCircleHeight, kCircleHeight);
    _circleView.layer.cornerRadius = _circleView.frame.size.height / 2;
    
    // Circle background view
    _circleViewBackground.backgroundColor = [UIColor whiteColor];
    _circleViewBackground.layer.cornerRadius = _circleViewBackground.frame.size.height / 2;
    x = (kCircleHeight - _circleIconHeight) / 2;
    
    // Circle image view
    _circleIconImageView.frame = CGRectMake(x, x, _circleIconHeight, _circleIconHeight);
    _circleIconImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [_circleViewBackground addSubview:_circleView];
    [_circleView addSubview:_circleIconImageView];
    
    // Background view
    _backgroundView.userInteractionEnabled = YES;
    
    // Title
    _labelTitle.numberOfLines = 0;
    _labelTitle.lineBreakMode = NSLineBreakByWordWrapping;
    _labelTitle.textAlignment = NSTextAlignmentCenter;
    _labelTitle.font = [UIFont fontWithName:_titleFontFamily size:_titleFontSize];
    
    // Body text
    _viewText.editable = NO;
    _viewText.allowsEditingTextAttributes = YES;
    _viewText.textAlignment = NSTextAlignmentCenter;
    _viewText.font = [UIFont fontWithName:_bodyTextFontFamily size:_bodyFontSize];
    _viewText.scrollEnabled = NO;
    _viewText.textContainerInset = UIEdgeInsetsZero;
    _viewText.textContainer.lineFragmentPadding = 0;
    _viewText.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    // Content view
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.layer.cornerRadius = 5.0f;
    _contentView.layer.masksToBounds = YES;
    _contentView.layer.borderWidth = 0.5f;
    [_contentView addSubview:_contentScrollView];
    [_contentScrollView addSubview:_viewText];
    [_contentScrollView addSubview:_labelTitle];
    
    // Colors
    self.backgroundViewColor = [UIColor whiteColor];
    _labelTitle.textColor = UIColorFromHEX(0x4D4D4D); // Dark gray
    _viewText.textColor = UIColorFromHEX(0x4D4D4D);   // Dark gray
    _contentView.layer.borderColor = UIColorFromHEX(0xCCCCCC).CGColor; // Light gray
    [self addObservers];
}

- (void)setupNewWindow
{
    // Preserve the current key window to restore it after dismissing the alert
    self.previousWindow = [SCLAlertView scl_currentKeyWindow];

    // Create a dedicated window to host the alert
    UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[self mainScreenFrame]];
    alertWindow.windowLevel = UIWindowLevelAlert;
    alertWindow.backgroundColor = [UIColor clearColor];
    alertWindow.rootViewController = [UIViewController new];
    alertWindow.accessibilityViewIsModal = YES;

    // On iOS 13+, explicitly attach the alert window to the active UIWindowScene
    if (@available(iOS 13.0, *)) {
        // Try to reuse the scene from the current key window, if available
        UIWindow *key = [SCLAlertView scl_currentKeyWindow];
        if (key.windowScene != nil) {
            alertWindow.windowScene = key.windowScene;
        } else {
            // Fallback: iterate through connected scenes and pick a foreground active UIWindowScene
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive &&
                    [scene isKindOfClass:[UIWindowScene class]]) {
                    alertWindow.windowScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }
    }

    self.SCLAlertWindow = alertWindow;
    self.usingNewWindow = YES;
}

#pragma mark - View Lifecycle

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self updateDynamicTypeFonts];

    CGRect available = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
    if (!CGRectIsNull(_keyboardFrame) && self.view.window) {
        CGRect keyboard = [self.view convertRect:_keyboardFrame fromCoordinateSpace:self.view.window.screen.coordinateSpace];
        CGRect overlap = CGRectIntersection(available, keyboard);
        if (!CGRectIsNull(overlap) && CGRectGetMaxY(overlap) >= CGRectGetMaxY(available)) {
            available.size.height = MAX(0.0f, CGRectGetMinY(overlap) - CGRectGetMinY(available));
        }
    }
    available = CGRectInset(available, 12.0f, 12.0f);
    CGFloat width = MAX(1.0f, MIN(_windowWidth, CGRectGetWidth(available)));
    CGFloat textWidth = MAX(1.0f, width - 24.0f);
    CGFloat circleHeight = _useLargerIcon ? 106.0f : kCircleHeight;
    CGFloat circleBackgroundHeight = _useLargerIcon ? 122.0f : kCircleHeightBackground;
    CGFloat minimumViewportHeight = MAX(44.0f, MAX(_labelTitle.font.lineHeight, _viewText.font.lineHeight));
    for (SCLButton *button in _buttons) {
        minimumViewportHeight = MAX(minimumViewportHeight, button.titleLabel.font.lineHeight + button.contentEdgeInsets.top + button.contentEdgeInsets.bottom);
    }
    for (SCLTextView *field in _textFields) {
        minimumViewportHeight = MAX(minimumViewportHeight, [field sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
    }
    BOOL showsCircle = _circleViewBackground.superview &&
        CGRectGetHeight(available) - circleBackgroundHeight / 2.0f >= minimumViewportHeight;
    _circleViewBackground.hidden = !showsCircle;
    CGFloat circleOverlap = showsCircle ? circleBackgroundHeight / 2.0f : 0.0f;
    CGFloat y = circleOverlap + 8.0f;

    if (_labelTitle) {
        CGFloat height = ceil([_labelTitle sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
        _labelTitle.frame = CGRectMake(12.0f, y, textWidth, height);
        y += height + 10.0f;
    }
    if (_viewText) {
        CGFloat height = ceil([_viewText sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
        _viewText.frame = CGRectMake(12.0f, y, textWidth, height);
        y += height + 14.0f;
    }
    for (UIView *input in _inputs) {
        CGFloat height = CGRectGetHeight(input.bounds);
        if ([_textFields containsObject:input] || [input isKindOfClass:[SCLSwitchView class]]) {
            height = ceil([input sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
        }
        input.frame = CGRectMake(12.0f, y, textWidth, height);
        input.layer.cornerRadius = 3.0f;
        y += height + 10.0f;
    }
    for (UIView *customView in _customViews) {
        customView.frame = CGRectMake(12.0f, y, MIN(CGRectGetWidth(customView.bounds), textWidth), CGRectGetHeight(customView.bounds));
        y += CGRectGetHeight(customView.bounds) + 10.0f;
    }

    BOOL horizontal = _horizontalButtons && _buttons.count > 1 &&
        !UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
    CGFloat buttonWidth = horizontal ? (textWidth - (_buttons.count - 1) * 10.0f) / _buttons.count : textWidth;
    for (SCLButton *button in _buttons) {
        if (horizontal && (buttonWidth < 44.0f || [button sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width > buttonWidth)) {
            horizontal = NO;
        }
    }
    if (!horizontal) {
        buttonWidth = textWidth;
    }
    CGFloat rowHeight = 0.0f;
    for (SCLButton *button in _buttons) {
        rowHeight = MAX(rowHeight, [button sizeThatFits:CGSizeMake(buttonWidth, CGFLOAT_MAX)].height);
    }
    CGFloat x = 12.0f;
    for (SCLButton *button in _buttons) {
        CGFloat height = horizontal ? rowHeight : [button sizeThatFits:CGSizeMake(buttonWidth, CGFLOAT_MAX)].height;
        button.frame = CGRectMake(x, y, buttonWidth, height);
        if (horizontal) {
            x += buttonWidth + 10.0f;
        } else {
            y += height + 10.0f;
        }
    }
    if (horizontal) {
        y += rowHeight + 10.0f;
    }

    CGFloat contentHeight = ceil(y + 4.0f);
    CGFloat height = MIN(contentHeight, MAX(1.0f, CGRectGetHeight(available) - circleOverlap));
    CGFloat panelY = CGRectGetMinY(available) + circleOverlap + MAX(0.0f, (CGRectGetHeight(available) - circleOverlap - height) / 2.0f);
    _contentView.frame = CGRectMake(CGRectGetMidX(available) - width / 2.0f, panelY, width, height);
    _contentView.layer.cornerRadius = self.cornerRadius ? self.cornerRadius : 5.0f;
    _contentScrollView.frame = _contentView.bounds;
    _contentScrollView.contentSize = CGSizeMake(width, contentHeight);
    _contentScrollView.scrollEnabled = contentHeight > height;
    CGPoint offset = _contentScrollView.contentOffset;
    offset.y = MIN(MAX(0.0f, offset.y), MAX(0.0f, contentHeight - height));
    _contentScrollView.contentOffset = CGPointMake(0.0f, offset.y);

    _circleViewBackground.frame = CGRectMake(CGRectGetMidX(_contentView.frame) - circleBackgroundHeight / 2.0f, panelY - circleOverlap, circleBackgroundHeight, circleBackgroundHeight);
    _circleViewBackground.layer.cornerRadius = circleBackgroundHeight / 2.0f;
    CGFloat circleInset = (circleBackgroundHeight - circleHeight) / 2.0f;
    _circleView.frame = CGRectMake(circleInset, circleInset, circleHeight, circleHeight);
    _circleView.layer.cornerRadius = circleHeight / 2.0f;
    CGFloat iconHeight = _useLargerIcon ? 70.0f : _circleIconHeight;
    _circleIconImageView.frame = CGRectMake((circleHeight - iconHeight) / 2.0f, (circleHeight - iconHeight) / 2.0f, iconHeight, iconHeight);
    _activityIndicatorView.center = CGPointMake(circleHeight / 2.0f, circleHeight / 2.0f);
    _backgroundView.frame = self.view.superview.bounds;
    [self scrollActiveTextFieldToVisible];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

#pragma mark - Gesture Handling

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    if (_shouldDismissOnTapOutside)
    {
        BOOL hide = _shouldDismissOnTapOutside;
        
        for (UIView *input in _inputs)
        {
            if ([input isKindOfClass:[UITextField class]] && input.isFirstResponder)
            {
                [input resignFirstResponder];
                hide = NO;
            }
        }
        if(hide)
        {
            [self hideView];
        }
    }
}

- (void)setShouldDismissOnTapOutside:(BOOL)shouldDismissOnTapOutside
{
    _shouldDismissOnTapOutside = shouldDismissOnTapOutside;
    [_gestureRecognizer.view removeGestureRecognizer:_gestureRecognizer];
    self.gestureRecognizer = nil;
    if(_shouldDismissOnTapOutside)
    {
        self.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _gestureRecognizer.delegate = self;
        [self.view addGestureRecognizer:_gestureRecognizer];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return gestureRecognizer != _gestureRecognizer ||
        (![touch.view isDescendantOfView:_contentView] && ![touch.view isDescendantOfView:_circleViewBackground]);
}

#pragma mark - Navigation Gesture

- (void)disableInteractivePopGesture
{
    UINavigationController *navigationController;
    
    if([_rootViewController isKindOfClass:[UINavigationController class]])
    {
        navigationController = ((UINavigationController*)_rootViewController);
    }
    else
    {
        navigationController = _rootViewController.navigationController;
    }
    
    // Disable back gesture
    if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        _restoreInteractivePopGestureEnabled = navigationController.interactivePopGestureRecognizer.enabled;
        _restoreInteractivePopGestureDelegate = navigationController.interactivePopGestureRecognizer.delegate;
        navigationController.interactivePopGestureRecognizer.enabled = NO;
        navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)restoreInteractivePopGesture
{
    UINavigationController *navigationController;
    
    if([_rootViewController isKindOfClass:[UINavigationController class]])
    {
        navigationController = ((UINavigationController*)_rootViewController);
    }
    else
    {
        navigationController = _rootViewController.navigationController;
    }
    
    // Restore back gesture
    if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        navigationController.interactivePopGestureRecognizer.enabled = _restoreInteractivePopGestureEnabled;
        navigationController.interactivePopGestureRecognizer.delegate = _restoreInteractivePopGestureDelegate;
    }
}

#pragma mark - Custom Fonts

- (UIFont *)scaledFont:(UIFont *)font forView:(UIView<UIContentSizeCategoryAdjusting> *)view textStyle:(UIFontTextStyle)textStyle
{
    UIFont *baseFont = [_baseFonts objectForKey:view];
    if (!baseFont || ![font isEqual:[_scaledFonts objectForKey:view]]) {
        baseFont = font;
        [_baseFonts setObject:baseFont forKey:view];
    }

    // Fonts already carrying a text style are owned by UIKit, not scaled again.
    BOOL automatic = [baseFont.fontDescriptor objectForKey:UIFontDescriptorTextStyleAttribute] != nil;
    view.adjustsFontForContentSizeCategory = automatic;
    UIFont *scaledFont = automatic ? font : [[UIFontMetrics metricsForTextStyle:textStyle] scaledFontForFont:baseFont compatibleWithTraitCollection:self.traitCollection];
    [_scaledFonts setObject:scaledFont forKey:view];
    return scaledFont;
}

- (void)updateDynamicTypeFonts
{
    if (_labelTitle) {
        _labelTitle.font = [self scaledFont:_labelTitle.font forView:_labelTitle textStyle:UIFontTextStyleTitle2];
    }
    if (_viewText && _baseAttributedText) {
        if (_scaledAttributedText && ![_viewText.attributedText isEqualToAttributedString:_scaledAttributedText]) {
            self.baseAttributedText = _viewText.attributedText;
        }
        NSMutableAttributedString *text = [_baseAttributedText mutableCopy];
        UIFont *defaultFont = [UIFont fontWithName:_bodyTextFontFamily size:_bodyFontSize];
        UIFontMetrics *metrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
        [_baseAttributedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, text.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            UIFont *font = value ?: defaultFont;
            [text addAttribute:NSFontAttributeName value:[metrics scaledFontForFont:font compatibleWithTraitCollection:self.traitCollection] range:range];
        }];
        _viewText.adjustsFontForContentSizeCategory = NO;
        if (![_viewText.attributedText isEqualToAttributedString:text]) {
            _viewText.attributedText = text;
        }
        self.scaledAttributedText = _viewText.attributedText;
    } else if (_viewText) {
        _viewText.font = [self scaledFont:_viewText.font forView:_viewText textStyle:UIFontTextStyleBody];
    }
    for (SCLButton *button in _buttons) {
        button.titleLabel.font = [self scaledFont:button.titleLabel.font forView:button.titleLabel textStyle:UIFontTextStyleHeadline];
    }
    for (SCLTextView *textField in _textFields) {
        textField.font = [self scaledFont:textField.font forView:textField textStyle:UIFontTextStyleBody];
    }
}

- (void)setTitleFontFamily:(NSString *)titleFontFamily withSize:(CGFloat)size
{
    self.titleFontFamily = titleFontFamily;
    self.titleFontSize = size;
    self.labelTitle.font = [UIFont fontWithName:_titleFontFamily size:_titleFontSize];
    if (_labelTitle) {
        [_baseFonts removeObjectForKey:_labelTitle];
        [_scaledFonts removeObjectForKey:_labelTitle];
    }
    [self.view setNeedsLayout];
}

- (void)setBodyTextFontFamily:(NSString *)bodyTextFontFamily withSize:(CGFloat)size
{
    self.bodyTextFontFamily = bodyTextFontFamily;
    self.bodyFontSize = size;
    self.viewText.font = [UIFont fontWithName:_bodyTextFontFamily size:_bodyFontSize];
    if (_viewText) {
        [_baseFonts removeObjectForKey:_viewText];
        [_scaledFonts removeObjectForKey:_viewText];
    }
    if (_baseAttributedText) {
        self.scaledAttributedText = nil;
    }
    [self.view setNeedsLayout];
}

- (void)setButtonsTextFontFamily:(NSString *)buttonsFontFamily withSize:(CGFloat)size
{
    UIFont *previousFont = [UIFont fontWithName:_buttonsFontFamily size:_buttonsFontSize];
    self.buttonsFontFamily = buttonsFontFamily;
    self.buttonsFontSize = size;
    for (SCLButton *button in _buttons) {
        UIFont *baseFont = [_baseFonts objectForKey:button.titleLabel] ?: button.titleLabel.font;
        if (![button.titleLabel.font isEqual:[_scaledFonts objectForKey:button.titleLabel]]) {
            baseFont = button.titleLabel.font;
        }
        if ([baseFont isEqual:previousFont]) {
            button.titleLabel.font = [UIFont fontWithName:_buttonsFontFamily size:_buttonsFontSize];
            [_baseFonts removeObjectForKey:button.titleLabel];
            [_scaledFonts removeObjectForKey:button.titleLabel];
        }
    }
    [self.view setNeedsLayout];
}

#pragma mark - Background Color

- (void)setBackgroundViewColor:(UIColor *)backgroundViewColor
{
    _backgroundViewColor = backgroundViewColor;
    _circleViewBackground.backgroundColor = _backgroundViewColor;
    _contentView.backgroundColor = _backgroundViewColor;
    _viewText.backgroundColor = _backgroundViewColor;
}

#pragma mark - Sound

- (void)setSoundURL:(NSURL *)soundURL
{
    _soundURL = soundURL;
    
    // Dispose previous sound
    AudioServicesDisposeSystemSoundID(_soundID);
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)_soundURL, &_soundID);
    
    // Play new sound
    AudioServicesPlaySystemSound(_soundID);
}

#pragma mark - Activity Indicator

- (void)addActivityIndicatorView
{
    // Add UIActivityIndicatorView
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.frame = CGRectMake(kCircleHeight / 2 - kActivityIndicatorHeight / 2, kCircleHeight / 2 - kActivityIndicatorHeight / 2, kActivityIndicatorHeight, kActivityIndicatorHeight);
    [_circleView addSubview:_activityIndicatorView];
}

#pragma mark - Custom View

- (UIView *)addCustomView:(UIView *)customView
{
    [_contentScrollView addSubview:customView];
    [_customViews addObject:customView];
    [self.view setNeedsLayout];
    
    return customView;
}

- (void)addInput:(UIView *)input
{
    if ([input isKindOfClass:[UITextField class]]) {
        for (UIView *previous in _inputs.reverseObjectEnumerator) {
            if ([previous isKindOfClass:[UITextField class]]) {
                ((UITextField *)previous).returnKeyType = UIReturnKeyNext;
                break;
            }
        }
    }
    [_contentScrollView addSubview:input];
    [_inputs addObject:input];
    [self.view setNeedsLayout];
}

#pragma mark - Switch View

- (SCLSwitchView *)addSwitchViewWithLabel:(NSString *)label
{
    // Add switch view
    SCLSwitchView *switchView = [[SCLSwitchView alloc] initWithFrame:CGRectMake(0, 0, self.windowWidth, 31.0f)];
    
    if (label != nil)
    {
        switchView.labelText = label;
    }
    
    [self addInput:switchView];
    
    return switchView;
}

#pragma mark - Text Field

- (SCLTextView *)addTextField:(NSString *)title setDefaultText:(NSString *)defaultText
{
    // Add text field
    SCLTextView *txt = [[SCLTextView alloc] init];
    txt.font = [UIFont fontWithName:_bodyTextFontFamily size:_bodyFontSize];
    txt.delegate = self;
    
    if (title != nil)
    {
        txt.placeholder = title;
    }
    if (defaultText != nil)
    {
        txt.text = defaultText;
    }
    
    [_textFields addObject:txt];
    [self addInput:txt];
    return txt;
}

- (void)addCustomTextField:(UITextField *)textField
{
    [self addInput:textField];
}

# pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSUInteger index = [_inputs indexOfObject:textField];
    for (NSUInteger next = index + 1; index != NSNotFound && next < _inputs.count; next++) {
        UIView *input = _inputs[next];
        if ([input isKindOfClass:[UITextField class]]) {
            [input becomeFirstResponder];
            return NO;
        }
    }
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self scrollActiveTextFieldToVisible];
}

- (void)scrollActiveTextFieldToVisible
{
    for (UIView *input in _inputs) {
        if (input.isFirstResponder) {
            [_contentScrollView scrollRectToVisible:CGRectInset(input.frame, 0.0f, -8.0f) animated:NO];
            break;
        }
    }
}

#pragma mark - Keyboard

- (void)layoutForKeyboardNotification:(NSNotification *)notification
{
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16;
    [UIView animateWithDuration:duration delay:0 options:curve | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (self.view.window) {
        self.keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [self layoutForKeyboardNotification:notification];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardFrame = CGRectNull;
    [self layoutForKeyboardNotification:notification];
}

#pragma mark - Buttons

- (SCLButton *)addButton:(NSString *)title
{
    // Add button
    SCLButton *btn = [[SCLButton alloc] initWithWindowWidth:self.windowWidth];
    btn.layer.masksToBounds = YES;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont fontWithName:_buttonsFontFamily size:_buttonsFontSize];
    
    [_contentScrollView addSubview:btn];
    [_buttons addObject:btn];
    [self.view setNeedsLayout];
    
    return btn;
}

- (SCLButton *)addDoneButtonWithTitle:(NSString *)title
{
    SCLButton *btn = [self addButton:title];
    
    if (_completeButtonFormatBlock != nil)
    {
        btn.completeButtonFormatBlock = _completeButtonFormatBlock;
    }
    
    [btn addTarget:self action:@selector(hideView) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (SCLButton *)addButton:(NSString *)title actionBlock:(SCLActionBlock)action
{
    SCLButton *btn = [self addButton:title];
    
    if (_buttonFormatBlock != nil)
    {
        btn.buttonFormatBlock = _buttonFormatBlock;
    }
    
    btn.actionType = SCLBlock;
    btn.actionBlock = action;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (SCLButton *)addButton:(NSString *)title validationBlock:(SCLValidationBlock)validationBlock actionBlock:(SCLActionBlock)action
{
    SCLButton *btn = [self addButton:title actionBlock:action];
    btn.validationBlock = validationBlock;
    
    return btn;
}

- (SCLButton *)addButton:(NSString *)title target:(id)target selector:(SEL)selector
{
    SCLButton *btn = [self addButton:title];
    btn.actionType = SCLSelector;
    btn.target = target;
    btn.selector = selector;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)buttonTapped:(SCLButton *)btn
{
    // Cancel countdown timer
    [buttonTimer cancelTimer];
    
    // Validate if needed
    if (btn.validationBlock && !btn.validationBlock()) {
        return;
    }
    
    if (btn.actionType == SCLBlock)
    {
        if (btn.actionBlock)
            btn.actionBlock();
    }
    else if (btn.actionType == SCLSelector)
    {
        UIControl *ctrl = [[UIControl alloc] init];
        [ctrl sendAction:btn.selector to:btn.target forEvent:nil];
    }
    else
    {
        NSLog(@"Unknown action type for button");
    }
    
    if([self isVisible])
    {
        [self hideView];
    }
}

#pragma mark - Button Timer

- (void)addTimerToButtonIndex:(NSInteger)buttonIndex reverse:(BOOL)reverse
{
    buttonIndex = MAX(buttonIndex, 0);
    buttonIndex = MIN(buttonIndex, [_buttons count]);
    
    buttonTimer = [[SCLTimerDisplay alloc] initWithOrigin:CGPointMake(5, 5) radius:13 lineWidth:4];
    buttonTimer.buttonIndex = buttonIndex;
    buttonTimer.reverse = reverse;
}

#pragma mark - Show Alert (Core)

- (SCLAlertViewResponder *)showTitle:(UIViewController *)vc image:(UIImage *)image color:(UIColor *)color title:(NSString *)title subTitle:(NSString *)subTitle duration:(NSTimeInterval)duration completeText:(NSString *)completeText style:(SCLAlertViewStyle)style
{
    if(_usingNewWindow) {

        self.backgroundView.frame = _SCLAlertWindow.bounds;
        
        // Add window subview
        [_SCLAlertWindow.rootViewController addChildViewController:self];
        [_SCLAlertWindow.rootViewController.view addSubview:_backgroundView];
        [_SCLAlertWindow.rootViewController.view addSubview:self.view];
    } else {
        _rootViewController = vc;
        
        [self disableInteractivePopGesture];
        
        self.backgroundView.frame = vc.view.bounds;
        
        // Add view controller subviews
        [_rootViewController addChildViewController:self];
        [_rootViewController.view addSubview:_backgroundView];
        [_rootViewController.view addSubview:self.view];
    }

    self.view.frame = self.view.superview.bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self didMoveToParentViewController:self.parentViewController];
    self.view.alpha = 0.0f;
    [self setBackground];
    
    // Alert color/icon
    UIColor *viewColor;
    UIImage *iconImage;
    
    // Icon style
    switch (style)
    {
        case SCLAlertViewStyleSuccess:
            viewColor = UIColorFromHEX(0x22B573);
            iconImage = SCLAlertViewStyleKit.imageOfCheckmark;
            break;
            
        case SCLAlertViewStyleError:
            viewColor = UIColorFromHEX(0xC1272D);
            iconImage = SCLAlertViewStyleKit.imageOfCross;
            break;
            
        case SCLAlertViewStyleNotice:
            viewColor = UIColorFromHEX(0x727375);
            iconImage = SCLAlertViewStyleKit.imageOfNotice;
            break;
            
        case SCLAlertViewStyleWarning:
            viewColor = UIColorFromHEX(0xFFD110);
            iconImage = SCLAlertViewStyleKit.imageOfWarning;
            break;
            
        case SCLAlertViewStyleInfo:
            viewColor = UIColorFromHEX(0x2866BF);
            iconImage = SCLAlertViewStyleKit.imageOfInfo;
            break;
            
        case SCLAlertViewStyleEdit:
            viewColor = UIColorFromHEX(0xA429FF);
            iconImage = SCLAlertViewStyleKit.imageOfEdit;
            break;
            
        case SCLAlertViewStyleWaiting:
            viewColor = UIColorFromHEX(0x6c125d);
            break;
            
        case SCLAlertViewStyleQuestion:
            viewColor = UIColorFromHEX(0x727375);
            iconImage = SCLAlertViewStyleKit.imageOfQuestion;
            break;
            
        case SCLAlertViewStyleCustom:
            viewColor = color;
            iconImage = image;
            self.circleIconHeight *= 2.0f;
            break;
    }
    
    // Custom alert color override
    if(_customViewColor)
    {
        viewColor = _customViewColor;
    }
    
    // Title
    if ([title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        self.labelTitle.text = title;
    } else {
        [_labelTitle removeFromSuperview];
        _labelTitle = nil;
    }
    
    // Subtitle
    if ([subTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        if (_attributedFormatBlock == nil) {
            _viewText.text = subTitle;
        } else {
            self.baseAttributedText = self.attributedFormatBlock(subTitle);
        }
    } else {
        [_viewText removeFromSuperview];
        _viewText = nil;
    }
    
    // Add button if needed
    if(completeText != nil)
    {
        [self addDoneButtonWithTitle:completeText];
    }
    
    // Alert view color and images
    self.circleView.backgroundColor = self.tintTopCircle ? viewColor : _backgroundViewColor;
    
    if (style == SCLAlertViewStyleWaiting)
    {
        [self.activityIndicatorView startAnimating];
    }
    else
    {
        if (self.iconTintColor) {
            self.circleIconImageView.tintColor = self.iconTintColor;
            iconImage  = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        self.circleIconImageView.image = iconImage;
    }
    
    for (UIView *input in _inputs)
    {
        input.layer.borderColor = viewColor.CGColor;
    }
    
    for (SCLButton *btn in _buttons)
    {
        if (style == SCLAlertViewStyleWarning)
        {
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        
        if (!btn.defaultBackgroundColor) {
            btn.defaultBackgroundColor = viewColor;
        }
        
        if (btn.completeButtonFormatBlock != nil)
        {
            [btn parseConfig:btn.completeButtonFormatBlock()];
        }
        else if (btn.buttonFormatBlock != nil)
        {
            [btn parseConfig:btn.buttonFormatBlock()];
        }
    }
    
    // Duration
    if (duration > 0)
    {
        [durationTimer invalidate];
        
        if (buttonTimer && _buttons.count > 0)
        {
            SCLButton *btn = _buttons[buttonTimer.buttonIndex];
            btn.timer = buttonTimer;
            __weak __typeof(self) weakSelf = self;
            [buttonTimer startTimerWithTimeLimit:duration completed:^{
                [weakSelf buttonTapped:btn];
            }];
        }
        else
        {
            durationTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                             target:self
                                                           selector:@selector(hideView)
                                                           userInfo:nil
                                                            repeats:NO];
        }
    }
    
    if(_usingNewWindow)
    {
        [_SCLAlertWindow makeKeyAndVisible];
    }

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    // Show the alert view
    [self showView];
    
    // Chainable responder
    return [[SCLAlertViewResponder alloc] init:self];
}

#pragma mark - Show using UIViewController

- (void)showSuccess:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleSuccess];
}

- (void)showError:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleError];
}

- (void)showNotice:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleNotice];
}

- (void)showWarning:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleWarning];
}

- (void)showInfo:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleInfo];
}

- (void)showEdit:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleEdit];
}

- (void)showTitle:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle style:(SCLAlertViewStyle)style closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:style];
}

- (void)showCustom:(UIViewController *)vc image:(UIImage *)image color:(UIColor *)color title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:image color:color title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleCustom];
}

- (void)showWaiting:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self addActivityIndicatorView];
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleWaiting];
}

- (void)showQuestion:(UIViewController *)vc title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:vc image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleQuestion];
}

#pragma mark - Show using new window

- (void)showSuccess:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleSuccess];
}

- (void)showError:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleError];
}

- (void)showNotice:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleNotice];
}

- (void)showWarning:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleWarning];
}

- (void)showInfo:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleInfo];
}

- (void)showEdit:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleEdit];
}

- (void)showTitle:(NSString *)title subTitle:(NSString *)subTitle style:(SCLAlertViewStyle)style closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:style];
}

- (void)showCustom:(UIImage *)image color:(UIColor *)color title:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:image color:color title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleCustom];
}

- (void)showWaiting:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self addActivityIndicatorView];
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleWaiting];
}

- (void)showQuestion:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration
{
    [self showTitle:nil image:nil color:nil title:title subTitle:subTitle duration:duration completeText:closeButtonTitle style:SCLAlertViewStyleQuestion];
}

#pragma mark - Visibility

- (void)removeTopCircle
{
    [_circleViewBackground removeFromSuperview];
    [_circleView removeFromSuperview];
    [self.view setNeedsLayout];
}

- (BOOL)isVisible
{
    return (self.view.alpha);
}

- (void)alertIsDismissed:(SCLDismissBlock)dismissBlock
{
    self.dismissBlock = dismissBlock;
}

- (void)alertDismissAnimationIsCompleted:(SCLDismissAnimationCompletionBlock)dismissAnimationCompletionBlock
{
    self.dismissAnimationCompletionBlock = dismissAnimationCompletionBlock;
}

- (void)alertShowAnimationIsCompleted:(SCLShowAnimationCompletionBlock)showAnimationCompletionBlock
{
    self.showAnimationCompletionBlock = showAnimationCompletionBlock;
}

- (SCLForceHideBlock)forceHideBlock:(SCLForceHideBlock)forceHideBlock
{
    _forceHideBlock = forceHideBlock;
    
    if (_forceHideBlock)
    {
        [self hideView];
    }
    return _forceHideBlock;
}

- (CGRect)mainScreenFrame
{
    return [self isAppExtension] ? _extensionBounds : [SCLAlertView scl_currentKeyWindow].bounds;
}

- (BOOL)isAppExtension
{
    return [[NSBundle mainBundle].executablePath rangeOfString:@".appex/"].location != NSNotFound;
}

#pragma mark - Background Effects

- (void)makeShadowBackground
{
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundView.backgroundColor = [UIColor blackColor];
    _backgroundView.alpha = 0.7f;
    _backgroundOpacity = 0.7f;
}

- (void)makeBlurBackground
{
    UIView *fallbackView = _rootViewController.view;
    UIView *appView = _usingNewWindow ? (UIView *)[SCLAlertView scl_currentKeyWindow] : fallbackView;
    
    // Final fallback in case it still comes as nil
    if (!appView) {
        appView = [SCLAlertView scl_resolveAppViewWithFallback:fallbackView];
    }
    
    [appView layoutIfNeeded];
    
    UIImage *snapshot = [UIImage convertViewToImage:appView];
    if (snapshot) {
        UIImage *blurSnapshotImage = [snapshot applyBlurWithRadius:5.0f
                                                         tintColor:[UIColor colorWithWhite:0.2f
                                                                                     alpha:0.7f]
                                          saturationDeltaFactor:1.8f
                                                      maskImage:nil];
        
        _backgroundView.image = blurSnapshotImage;
    } else {
        _backgroundView.image = nil;
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    }
    _backgroundView.alpha = 0.0f;
    _backgroundOpacity = 1.0f;
}

- (void)makeTransparentBackground
{
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundView.backgroundColor = [UIColor clearColor];
    _backgroundView.alpha = 0.0f;
    _backgroundOpacity = 1.0f;
}

- (void)setBackground
{
    switch (_backgroundType)
    {
        case SCLAlertViewBackgroundShadow:
            [self makeShadowBackground];
            break;
            
        case SCLAlertViewBackgroundBlur:
            [self makeBlurBackground];
            break;
            
        case SCLAlertViewBackgroundTransparent:
            [self makeTransparentBackground];
            break;
    }
}

#pragma mark - Show Alert (Animations)

- (void)showView
{
    switch (_showAnimationType)
    {
        case SCLAlertViewShowAnimationFadeIn:
            [self fadeIn];
            break;
            
        case SCLAlertViewShowAnimationSlideInFromBottom:
            [self slideInFromBottom];
            break;
            
        case SCLAlertViewShowAnimationSlideInFromTop:
            [self slideInFromTop];
            break;
            
        case SCLAlertViewShowAnimationSlideInFromLeft:
            [self slideInFromLeft];
            break;
            
        case SCLAlertViewShowAnimationSlideInFromRight:
            [self slideInFromRight];
            break;
            
        case SCLAlertViewShowAnimationSlideInFromCenter:
            [self slideInFromCenter];
            break;
            
        case SCLAlertViewShowAnimationSlideInToCenter:
            [self slideInToCenter];
            break;
            
        case SCLAlertViewShowAnimationSimplyAppear:
            [self simplyAppear];
            break;
    }
}

#pragma mark - Hide Alert (Animations)

- (void)hideView
{
    switch (_hideAnimationType)
    {
        case SCLAlertViewHideAnimationFadeOut:
            [self fadeOut];
            break;
            
        case SCLAlertViewHideAnimationSlideOutToBottom:
            [self slideOutToBottom];
            break;
            
        case SCLAlertViewHideAnimationSlideOutToTop:
            [self slideOutToTop];
            break;
            
        case SCLAlertViewHideAnimationSlideOutToLeft:
            [self slideOutToLeft];
            break;
            
        case SCLAlertViewHideAnimationSlideOutToRight:
            [self slideOutToRight];
            break;
            
        case SCLAlertViewHideAnimationSlideOutToCenter:
            [self slideOutToCenter];
            break;
            
        case SCLAlertViewHideAnimationSlideOutFromCenter:
            [self slideOutFromCenter];
            break;
        
        case SCLAlertViewHideAnimationSimplyDisappear:
            [self simplyDisappear];
            break;
    }
    
    if (_activityIndicatorView)
    {
        [_activityIndicatorView stopAnimating];
    }
    
    if (durationTimer)
    {
        [durationTimer invalidate];
    }
    
    if (self.dismissBlock)
    {
        self.dismissBlock();
    }
    
    if (_usingNewWindow)
    {
        // Restore the previous key window after hiding the alert
        [self.previousWindow makeKeyAndVisible];
        self.previousWindow = nil;
    }
    
    for (SCLButton *btn in _buttons)
    {
        btn.actionBlock = nil;
        btn.target = nil;
        btn.selector = nil;
    }
}

#pragma mark - Hide Animations

- (void)fadeOut
{
    [self fadeOutWithDuration:0.3f];
}

- (void)fadeOutWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundView.alpha = 0.0f;
        self.view.alpha = 0.0f;
    } completion:^(BOOL completed) {
        [self.backgroundView removeFromSuperview];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        if (self.usingNewWindow) {
            // Remove current alert window
            [self.SCLAlertWindow setHidden:YES];
            self.SCLAlertWindow = nil;
        }
        if ( self.dismissAnimationCompletionBlock ){
            self.dismissAnimationCompletionBlock();
        }
    }];
}

- (void)slideOutToBottom
{
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y += self.backgroundView.frame.size.height;
        self.view.frame = frame;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)slideOutToTop
{
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y -= self.backgroundView.frame.size.height;
        self.view.frame = frame;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)slideOutToLeft
{
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.view.frame;
        frame.origin.x -= self.backgroundView.frame.size.width;
        self.view.frame = frame;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)slideOutToRight
{
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.view.frame;
        frame.origin.x += self.backgroundView.frame.size.width;
        self.view.frame = frame;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)slideOutToCenter
{
    [UIView animateWithDuration:0.3f animations:^{
        self.view.transform =
        CGAffineTransformConcat(CGAffineTransformIdentity,
                                CGAffineTransformMakeScale(0.1f, 0.1f));
        self.view.alpha = 0.0f;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)slideOutFromCenter
{
    [UIView animateWithDuration:0.3f animations:^{
        self.view.transform =
        CGAffineTransformConcat(CGAffineTransformIdentity,
                                CGAffineTransformMakeScale(3.0f, 3.0f));
        self.view.alpha = 0.0f;
    } completion:^(BOOL completed) {
        [self fadeOut];
    }];
}

- (void)simplyDisappear
{
    self.backgroundView.alpha = self.backgroundOpacity;
    self.view.alpha = 1.0f;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fadeOutWithDuration:0];
    });
}

#pragma mark - Show Animations

- (void)fadeIn
{
    self.backgroundView.alpha = 0.0f;
    self.view.alpha = 0.0f;
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.backgroundView.alpha = self.backgroundOpacity;
                         self.view.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         if ( self.showAnimationCompletionBlock ){
                             self.showAnimationCompletionBlock();
                         }
                     }];
}

- (void)slideInFromTop
{
    // From frame
    CGRect frame = self.backgroundView.frame;
    frame.origin.y = -self.backgroundView.frame.size.height;
    self.view.frame = frame;
    
    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:0 animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        CGRect frame = self.backgroundView.frame;
        frame.origin.y = 0.0f;
        self.view.frame = frame;
        
        self.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if ( self.showAnimationCompletionBlock ){
            self.showAnimationCompletionBlock();
        }
    }];
}

- (void)slideInFromBottom
{
    // From frame
    CGRect frame = self.backgroundView.frame;
    frame.origin.y = self.backgroundView.frame.size.height;
    self.view.frame = frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        CGRect frame = self.backgroundView.frame;
        frame.origin.y = 0.0f;
        self.view.frame = frame;
        
        self.view.alpha = 1.0f;
    } completion:^(BOOL completed) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.center = self.backgroundView.center;
        } completion:^(BOOL finished) {
            if ( self.showAnimationCompletionBlock ){
                self.showAnimationCompletionBlock();
            }
        }];
    }];
}

- (void)slideInFromLeft
{
    // From frame
    CGRect frame = self.backgroundView.frame;
    frame.origin.x = -self.backgroundView.frame.size.width;
    self.view.frame = frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        CGRect frame = self.backgroundView.frame;
        frame.origin.x = 0.0f;
        self.view.frame = frame;
        
        self.view.alpha = 1.0f;
    } completion:^(BOOL completed) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.center = self.backgroundView.center;
        } completion:^(BOOL finished) {
            if ( self.showAnimationCompletionBlock ){
                self.showAnimationCompletionBlock();
            }
        }];
    }];
}

- (void)slideInFromRight
{
    // From frame
    CGRect frame = self.backgroundView.frame;
    frame.origin.x = self.backgroundView.frame.size.width;
    self.view.frame = frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        CGRect frame = self.backgroundView.frame;
        frame.origin.x = 0.0f;
        self.view.frame = frame;
        
        self.view.alpha = 1.0f;
    } completion:^(BOOL completed) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.center = self.backgroundView.center;
        } completion:^(BOOL finished) {
            if ( self.showAnimationCompletionBlock ){
                self.showAnimationCompletionBlock();
            }
        }];
    }];
}

- (void)slideInFromCenter
{
    // From frame
    self.view.transform = CGAffineTransformConcat(CGAffineTransformIdentity,
                                                  CGAffineTransformMakeScale(3.0f, 3.0f));
    self.view.alpha = 0.0f;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        self.view.transform = CGAffineTransformConcat(CGAffineTransformIdentity,
                                                      CGAffineTransformMakeScale(1.0f, 1.0f));
        self.view.alpha = 1.0f;
    } completion:^(BOOL completed) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.center = self.backgroundView.center;
        } completion:^(BOOL finished) {
            if ( self.showAnimationCompletionBlock ){
                self.showAnimationCompletionBlock();
            }
        }];
    }];
}

- (void)slideInToCenter
{
    // From frame
    self.view.transform = CGAffineTransformConcat(CGAffineTransformIdentity,
                                                  CGAffineTransformMakeScale(0.1f, 0.1f));
    self.view.alpha = 0.0f;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = self.backgroundOpacity;
        
        // To frame
        self.view.transform = CGAffineTransformConcat(CGAffineTransformIdentity,
                                                      CGAffineTransformMakeScale(1.0f, 1.0f));
        self.view.alpha = 1.0f;
    } completion:^(BOOL completed) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.center = self.backgroundView.center;
        } completion:^(BOOL finished) {
            if ( self.showAnimationCompletionBlock ){
                self.showAnimationCompletionBlock();
            }
        }];
    }];
}

- (void)simplyAppear
{
    self.backgroundView.alpha = 0.0f;
    self.view.alpha = 0.0f;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.backgroundView.alpha = self.backgroundOpacity;
        self.view.alpha = 1.0f;
        if ( self.showAnimationCompletionBlock ){
            self.showAnimationCompletionBlock();
        }
    });
}

@end

@implementation SCLAlertViewBuilder__WithFluent
- (instancetype)init {
    if (self = [super init]) {
        [self setupFluent];
    }
    return self;
}
- (void)setupFluent {}
@end

@interface SCLALertViewTextFieldBuilder()
#pragma mark - Parameters
@property(copy, nonatomic) NSString *parameterTitle;
@property(copy, nonatomic) NSString *parameterDefaultText;

#pragma mark - Available later after adding
@property(weak, nonatomic) SCLTextView *textField;

#pragma mark - Setters
@property(copy, nonatomic) SCLALertViewTextFieldBuilder *(^title) (NSString *title);
@property(copy, nonatomic) SCLALertViewTextFieldBuilder *(^defaultText) (NSString *defaultText);
@end

@implementation SCLALertViewTextFieldBuilder
- (void)setupFluent {
    __weak __auto_type weakSelf = self;
    self.title = ^(NSString *title){
        weakSelf.parameterTitle = title;
        return weakSelf;
    };
    self.defaultText = ^(NSString *defaultText){
        weakSelf.parameterDefaultText = defaultText;
        return weakSelf;
    };
}
@end

@interface SCLALertViewButtonBuilder()

#pragma mark - Parameters
@property(copy, nonatomic) NSString *parameterTitle;
@property(copy, nonatomic) NSString *parameterDefaultText;
@property(weak, nonatomic) id parameterTarget;
@property(assign, nonatomic) SEL parameterSelector;
@property(copy, nonatomic) void(^parameterActionBlock)(void);
@property(copy, nonatomic) BOOL(^parameterValidationBlock)(void);

#pragma mark - Available later after adding
@property(weak, nonatomic) SCLButton *button;

#pragma mark - Setters
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^title) (NSString *title);
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^defaultText) (NSString *defaultText);
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^target) (id target);
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^selector) (SEL selector);
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^actionBlock) (void(^actionBlock)(void));
@property(copy, nonatomic) SCLALertViewButtonBuilder *(^validationBlock) (BOOL(^validationBlock)(void));

@end

@implementation SCLALertViewButtonBuilder
- (void)setupFluent {
    __weak __auto_type weakSelf = self;
    self.title = ^(NSString *title){
        weakSelf.parameterTitle = title;
        return weakSelf;
    };
    self.defaultText = ^(NSString *defaultText){
        weakSelf.parameterDefaultText = defaultText;
        return weakSelf;
    };
    self.target = ^(id target){
        weakSelf.parameterTarget = target;
        return weakSelf;
    };
    self.selector = ^(SEL selector){
        weakSelf.parameterSelector = selector;
        return weakSelf;
    };
    self.actionBlock = ^(void(^actionBlock)(void)){
        weakSelf.parameterActionBlock = actionBlock;
        return weakSelf;
    };
    self.validationBlock = ^(BOOL(^validationBlock)(void)){
        weakSelf.parameterValidationBlock = validationBlock;
        return weakSelf;
    };
}

@end


@interface SCLAlertViewBuilder()

@property (strong, nonatomic) SCLAlertView *alertView;

@end

@implementation SCLAlertViewBuilder

- (void)setupFluent {
    __weak __auto_type weakSelf = self;
    self.cornerRadius = ^(CGFloat cornerRadius) {
        weakSelf.alertView.cornerRadius = cornerRadius;
        return weakSelf;
    };
    self.tintTopCircle = ^(BOOL tintTopCircle) {
        weakSelf.alertView.tintTopCircle = tintTopCircle;
        return weakSelf;
    };
    self.useLargerIcon = ^(BOOL useLargerIcon) {
        weakSelf.alertView.useLargerIcon = useLargerIcon;
        return weakSelf;
    };
    self.labelTitle = ^(UILabel *labelTitle) {
        weakSelf.alertView.labelTitle = labelTitle;
        return weakSelf;
    };
    self.viewText = ^(UITextView *viewText) {
        weakSelf.alertView.viewText = viewText;
        return weakSelf;
    };
    self.activityIndicatorView = ^(UIActivityIndicatorView *activityIndicatorView) {
        weakSelf.alertView.activityIndicatorView = activityIndicatorView;
        return weakSelf;
    };
    self.shouldDismissOnTapOutside = ^(BOOL shouldDismissOnTapOutside) {
        weakSelf.alertView.shouldDismissOnTapOutside = shouldDismissOnTapOutside;
        return weakSelf;
    };
    self.soundURL = ^(NSURL *soundURL) {
        weakSelf.alertView.soundURL = soundURL;
        return weakSelf;
    };
    self.attributedFormatBlock = ^(SCLAttributedFormatBlock attributedFormatBlock) {
        weakSelf.alertView.attributedFormatBlock = attributedFormatBlock;
        return weakSelf;
    };
    self.completeButtonFormatBlock = ^(CompleteButtonFormatBlock completeButtonFormatBlock) {
        weakSelf.alertView.completeButtonFormatBlock = completeButtonFormatBlock;
        return weakSelf;
    };
    self.buttonFormatBlock = ^(ButtonFormatBlock buttonFormatBlock) {
        weakSelf.alertView.buttonFormatBlock = buttonFormatBlock;
        return weakSelf;
    };
    self.forceHideBlock = ^(SCLForceHideBlock forceHideBlock) {
        weakSelf.alertView.forceHideBlock = forceHideBlock;
        return weakSelf;
    };
    self.hideAnimationType = ^(SCLAlertViewHideAnimation hideAnimationType) {
        weakSelf.alertView.hideAnimationType = hideAnimationType;
        return weakSelf;
    };
    self.showAnimationType = ^(SCLAlertViewShowAnimation showAnimationType) {
        weakSelf.alertView.showAnimationType = showAnimationType;
        return weakSelf;
    };
    self.backgroundType = ^(SCLAlertViewBackground backgroundType) {
        weakSelf.alertView.backgroundType = backgroundType;
        return weakSelf;
    };
    self.customViewColor = ^(UIColor *customViewColor) {
        weakSelf.alertView.customViewColor = customViewColor;
        return weakSelf;
    };
    self.backgroundViewColor = ^(UIColor *backgroundViewColor) {
        weakSelf.alertView.backgroundViewColor = backgroundViewColor;
        return weakSelf;
    };
    self.iconTintColor = ^(UIColor *iconTintColor) {
        weakSelf.alertView.iconTintColor = iconTintColor;
        return weakSelf;
    };
    self.circleIconHeight = ^(CGFloat circleIconHeight) {
        weakSelf.alertView.circleIconHeight = circleIconHeight;
        return weakSelf;
    };
    self.extensionBounds = ^(CGRect extensionBounds) {
        weakSelf.alertView.extensionBounds = extensionBounds;
        return weakSelf;
    };
    self.statusBarHidden = ^(BOOL statusBarHidden) {
        weakSelf.alertView.statusBarHidden = statusBarHidden;
        return weakSelf;
    };
    self.statusBarStyle = ^(UIStatusBarStyle statusBarStyle) {
        weakSelf.alertView.statusBarStyle = statusBarStyle;
        return weakSelf;
    };
    self.alertIsDismissed = ^(SCLDismissBlock dismissBlock) {
        [weakSelf.alertView alertIsDismissed:dismissBlock];
        return weakSelf;
    };
    self.alertDismissAnimationIsCompleted = ^(SCLDismissAnimationCompletionBlock dismissAnimationCompletionBlock) {
        [weakSelf.alertView alertDismissAnimationIsCompleted:dismissAnimationCompletionBlock];
        return weakSelf;
    };
    self.alertShowAnimationIsCompleted = ^(SCLShowAnimationCompletionBlock showAnimationCompletionBlock) {
        [weakSelf.alertView alertShowAnimationIsCompleted:showAnimationCompletionBlock];
        return weakSelf;
    };
    self.removeTopCircle = ^(void) {
        [weakSelf.alertView removeTopCircle];
        return weakSelf;
    };
    self.addCustomView = ^(UIView *view) {
        [weakSelf.alertView addCustomView:view];
        return weakSelf;
    };
    self.addTextField = ^(NSString *title, NSString *defaultText) {
        [weakSelf.alertView addTextField:title setDefaultText:defaultText];
        return weakSelf;
    };
    self.addCustomTextField = ^(UITextField *textField) {
        [weakSelf.alertView addCustomTextField:textField];
        return weakSelf;
    };
    self.addSwitchViewWithLabelTitle = ^(NSString *title) {
        [weakSelf.alertView addSwitchViewWithLabel:title];
        return weakSelf;
    };
    self.addTimerToButtonIndex = ^(NSInteger buttonIndex, BOOL reverse) {
        [weakSelf.alertView addTimerToButtonIndex:buttonIndex reverse:reverse];
        return weakSelf;
    };
    self.setTitleFontFamily = ^(NSString *titleFontFamily, CGFloat size) {
        [weakSelf.alertView setTitleFontFamily:titleFontFamily withSize:size];
        return weakSelf;
    };
    self.setBodyTextFontFamily = ^(NSString *bodyTextFontFamily, CGFloat size) {
        [weakSelf.alertView setBodyTextFontFamily:bodyTextFontFamily withSize:size];
        return weakSelf;
    };
    self.setButtonsTextFontFamily = ^(NSString *buttonsFontFamily, CGFloat size) {
        [weakSelf.alertView setButtonsTextFontFamily:buttonsFontFamily withSize:size];
        return weakSelf;
    };
    self.addButtonWithActionBlock = ^(NSString *title, SCLActionBlock action) {
        [weakSelf.alertView addButton:title actionBlock:action];
        return weakSelf;
    };
    self.addButtonWithValidationBlock = ^(NSString *title, SCLValidationBlock validationBlock, SCLActionBlock action) {
        [weakSelf.alertView addButton:title validationBlock:validationBlock actionBlock:action];
        return weakSelf;
    };
    self.addButtonWithTarget = ^(NSString *title, id target, SEL selector) {
        [weakSelf.alertView addButton:title target:target selector:selector];
        return weakSelf;
    };
    
    self.addButtonWithBuilder = ^(SCLALertViewButtonBuilder *builder){
        SCLButton *button = nil;
        if (builder.parameterTarget && builder.parameterSelector) {
            button = [weakSelf.alertView addButton:builder.parameterTitle target:builder.parameterTarget selector:builder.parameterSelector];
        }
        else if (builder.parameterValidationBlock && builder.parameterActionBlock) {
            button = [weakSelf.alertView addButton:builder.parameterTitle validationBlock:builder.parameterValidationBlock actionBlock:builder.parameterActionBlock];
        }
        else if (builder.parameterActionBlock) {
            button = [weakSelf.alertView addButton:builder.parameterTitle actionBlock:builder.parameterActionBlock];
        }
        builder.button = button;
        return weakSelf;
    };
    
    self.addTextFieldWithBuilder = ^(SCLALertViewTextFieldBuilder *builder){
        builder.textField = [weakSelf.alertView addTextField:builder.parameterTitle setDefaultText:builder.parameterDefaultText];
        return weakSelf;
    };
}

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        self.alertView = [[SCLAlertView alloc] init];
    }
    return self;
}
- (instancetype)initWithNewWindow {
    self = [super init];
    if (self) {
        self.alertView = [[SCLAlertView alloc] initWithNewWindow];
    }
    return self;
}

- (instancetype)initWithNewWindowWidth:(CGFloat)width {
    self = [super init];
    if (self) {
        self.alertView = [[SCLAlertView alloc] initWithNewWindowWidth:width];
    }
    return self;
}
@end

@interface SCLAlertViewShowBuilder()

@property(weak, nonatomic) UIViewController *parameterViewController;
@property(copy, nonatomic) UIImage *parameterImage;
@property(copy, nonatomic) UIColor *parameterColor;
@property(copy, nonatomic) NSString *parameterTitle;
@property(copy, nonatomic) NSString *parameterDefaultText;
@property(copy, nonatomic) NSString *parameterSubTitle;
@property(copy, nonatomic) NSString *parameterCompleteText;
@property(copy, nonatomic) NSString *parameterCloseButtonTitle;
@property(assign, nonatomic) SCLAlertViewStyle parameterStyle;
@property(assign, nonatomic) NSTimeInterval parameterDuration;

#pragma mark - Setters
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^viewController)(UIViewController *viewController);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^image)(UIImage *image);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^color)(UIColor *color);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^title)(NSString *title);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^subTitle)(NSString *subTitle);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^completeText)(NSString *completeText);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^style)(SCLAlertViewStyle style);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^closeButtonTitle)(NSString *closeButtonTitle);
@property(copy, nonatomic) SCLAlertViewShowBuilder *(^duration)(NSTimeInterval duration);

#pragma mark - Show
@property(copy, nonatomic) void (^show)(SCLAlertView *view, UIViewController *controller);
@end

@implementation SCLAlertViewShowBuilder

- (void)setupFluent {
    __weak __auto_type weakSelf = self;
    self.viewController = ^(UIViewController *viewController){
        weakSelf.parameterViewController = viewController;
        return weakSelf;
    };
    self.image = ^(UIImage *image) {
        weakSelf.parameterImage = image;
        return weakSelf;
    };
    self.color = ^(UIColor *color) {
        weakSelf.parameterColor = color;
        return weakSelf;
    };
    self.title = ^(NSString *title){
        weakSelf.parameterTitle = title;
        return weakSelf;
    };
    self.subTitle = ^(NSString *subTitle){
        weakSelf.parameterSubTitle = subTitle;
        return weakSelf;
    };
    self.completeText = ^(NSString *completeText){
        weakSelf.parameterCompleteText = completeText;
        return weakSelf;
    };
    self.style = ^(SCLAlertViewStyle style){
        weakSelf.parameterStyle = style;
        return weakSelf;
    };
    self.closeButtonTitle = ^(NSString *closeButtonTitle){
        weakSelf.parameterCloseButtonTitle = closeButtonTitle;
        return weakSelf;
    };
    self.duration = ^(NSTimeInterval duration){
        weakSelf.parameterDuration = duration;
        return weakSelf;
    };
    self.show = ^(SCLAlertView *view, UIViewController *controller) {
        [weakSelf showAlertView:view onViewController:controller];
    };
}

#pragma mark - Setters

- (void)showAlertView:(SCLAlertView *)alertView {
    [self showAlertView:alertView onViewController:self.parameterViewController];
}

- (void)showAlertView:(SCLAlertView *)alertView onViewController:(UIViewController *)controller {
    UIViewController *targetController = controller ? controller : self.parameterViewController;
    
    if (self.parameterImage || self.parameterColor) {
        [alertView showTitle:targetController image:self.parameterImage color:self.parameterColor title:self.parameterTitle subTitle:self.parameterSubTitle duration:self.parameterDuration completeText:self.parameterCloseButtonTitle style:self.parameterStyle];
    }
    else {
        [alertView showTitle:targetController title:self.parameterTitle subTitle:self.parameterSubTitle style:self.parameterStyle closeButtonTitle:self.parameterCloseButtonTitle duration:self.parameterDuration];
    }
}

@end

