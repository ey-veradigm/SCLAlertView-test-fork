//
//  SCLAlertViewTests.m
//  SCLAlertViewTests
//
//  Created by Diogo Autilio on 9/26/14.
//  Copyright (c) 2014-2016 AnyKey Entertainment. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "../SCLAlertView/SCLAlertView.h"
#import "../SCLAlertView/SCLAlertView+WindowResolver.h"
#import "../SCLAlertView/SCLTimerDisplay.h"

@interface SCLAlertView (DynamicTypeTesting)
@property (strong, nonatomic, readonly) UIView *contentView;
@property (strong, nonatomic, readonly) UIScrollView *contentScrollView;
@property (strong, nonatomic, readonly) UIView *circleViewBackground;
@property (strong, nonatomic, readonly) NSArray<SCLButton *> *buttons;
@end

@interface SCLAlertViewTests : XCTestCase
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIWindow *previousWindow;
@property (strong, nonatomic) UIViewController *host;
@property (strong, nonatomic) NSMutableArray<SCLAlertView *> *alerts;
@property (nonatomic) BOOL animationsEnabled;
@end

@implementation SCLAlertViewTests

- (void)setUp {
    [super setUp];
    self.animationsEnabled = UIView.areAnimationsEnabled;
    [UIView setAnimationsEnabled:NO];
    self.previousWindow = [SCLAlertView scl_currentKeyWindow];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
    if (@available(iOS 13.0, *)) {
        self.window.windowScene = self.previousWindow.windowScene;
    }
    self.host = [UIViewController new];
    self.host.additionalSafeAreaInsets = UIEdgeInsetsMake(20, 0, 16, 0);
    self.window.rootViewController = self.host;
    [self.window makeKeyAndVisible];
    self.alerts = [NSMutableArray array];
}

- (void)tearDown {
    for (SCLAlertView *alert in self.alerts.reverseObjectEnumerator) {
        [alert hideView];
    }
    self.window.hidden = YES;
    self.window.rootViewController = nil;
    [self.previousWindow makeKeyAndVisible];
    self.alerts = nil;
    self.host = nil;
    self.window = nil;
    self.previousWindow = nil;
    [UIView setAnimationsEnabled:self.animationsEnabled];
    [super tearDown];
}

- (SCLAlertView *)alertWithWidth:(CGFloat)width {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithWidth:width];
    alert.showAnimationType = SCLAlertViewShowAnimationFadeIn;
    [self.alerts addObject:alert];
    return alert;
}

- (void)showAlert:(SCLAlertView *)alert title:(NSString *)title message:(NSString *)message {
    [alert showInfo:self.host title:title subTitle:message closeButtonTitle:@"Done" duration:0];
    [self setCategory:UIContentSizeCategoryLarge forAlert:alert];
}

- (void)setCategory:(UIContentSizeCategory)category forAlert:(SCLAlertView *)alert {
    UITraitCollection *traits = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:category];
    [alert.parentViewController setOverrideTraitCollection:traits forChildViewController:alert];
    [alert.view setNeedsLayout];
    [alert.view layoutIfNeeded];
}

- (void)deliverContentSizeChange {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIContentSizeCategoryDidChangeNotification object:nil];
    [center postNotificationName:UIContentSizeCategoryDidChangeNotification object:nil];
    XCTestExpectation *delivered = [self expectationWithDescription:@"Content size notifications laid out"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [delivered fulfill];
    });
    [self waitForExpectations:@[delivered] timeout:2];
}

- (void)assertFont:(UIFont *)font base:(UIFont *)base style:(UIFontTextStyle)style alert:(SCLAlertView *)alert {
    UIFont *expected = [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:base compatibleWithTraitCollection:alert.traitCollection];
    XCTAssertEqualObjects(font.fontName, base.fontName);
    XCTAssertEqualWithAccuracy(font.pointSize, expected.pointSize, 0.01);
}

- (void)assertLastButtonIsReachable:(SCLAlertView *)alert {
    UIScrollView *scroll = alert.contentScrollView;
    SCLButton *last = alert.buttons.lastObject;
    [scroll scrollRectToVisible:last.frame animated:NO];
    CGRect visible = (CGRect){scroll.contentOffset, scroll.bounds.size};
    XCTAssertTrue(CGRectContainsRect(CGRectInset(visible, -0.5, -0.5), last.frame));
    CGPoint point = [last convertPoint:CGPointMake(CGRectGetMidX(last.bounds), CGRectGetMidY(last.bounds)) toView:alert.view];
    UIView *hit = [alert.view hitTest:point withEvent:nil];
    XCTAssertTrue(hit == last || [hit isDescendantOfView:last]);
}

- (void)testEveryTextSizeScalesAllBuiltInControlsWithoutAccumulation {
    SCLAlertView *alert = [self alertWithWidth:240];
    SCLTextView *field = [alert addTextField:@"Name" setDefaultText:@"Typed text"];
    SCLButton *button = [alert addButton:@"Continue" actionBlock:^{}];
    [self showAlert:alert title:@"A title" message:@"An alert message"];
    NSArray<NSString *> *categories = @[
        UIContentSizeCategoryExtraSmall, UIContentSizeCategorySmall, UIContentSizeCategoryMedium,
        UIContentSizeCategoryLarge, UIContentSizeCategoryExtraLarge, UIContentSizeCategoryExtraExtraLarge,
        UIContentSizeCategoryExtraExtraExtraLarge, UIContentSizeCategoryAccessibilityMedium,
        UIContentSizeCategoryAccessibilityLarge, UIContentSizeCategoryAccessibilityExtraLarge,
        UIContentSizeCategoryAccessibilityExtraExtraLarge, UIContentSizeCategoryAccessibilityExtraExtraExtraLarge,
        UIContentSizeCategoryLarge
    ];
    for (UIContentSizeCategory category in categories) {
        [self setCategory:category forAlert:alert];
        [self deliverContentSizeChange];
        [self assertFont:alert.labelTitle.font base:[UIFont fontWithName:@"HelveticaNeue" size:20] style:UIFontTextStyleTitle2 alert:alert];
        [self assertFont:alert.viewText.font base:[UIFont fontWithName:@"HelveticaNeue" size:14] style:UIFontTextStyleBody alert:alert];
        [self assertFont:button.titleLabel.font base:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14] style:UIFontTextStyleHeadline alert:alert];
        [self assertFont:alert.buttons.lastObject.titleLabel.font base:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14] style:UIFontTextStyleHeadline alert:alert];
        [self assertFont:field.font base:[UIFont fontWithName:@"HelveticaNeue" size:14] style:UIFontTextStyleBody alert:alert];
        XCTAssertGreaterThanOrEqual(CGRectGetHeight(field.frame), ceil(field.font.lineHeight + 16));
        XCTAssertGreaterThanOrEqual(CGRectGetHeight(button.frame), 44);
        XCTAssertFalse(alert.labelTitle.adjustsFontForContentSizeCategory);
        XCTAssertFalse(alert.viewText.adjustsFontForContentSizeCategory);
        XCTAssertFalse(button.titleLabel.adjustsFontForContentSizeCategory);
        XCTAssertFalse(field.adjustsFontForContentSizeCategory);
        XCTAssertEqualObjects(field.text, @"Typed text");
        XCTAssertEqualObjects(field.placeholder, @"Name");
    }
}

- (void)testCustomFontAPIsAndPerButtonAndFieldFontsSurviveLiveChanges {
    SCLAlertView *alert = [self alertWithWidth:280];
    [alert setTitleFontFamily:@"Courier-Bold" withSize:24];
    [alert setBodyTextFontFamily:@"Courier" withSize:18];
    [alert setButtonsTextFontFamily:@"Courier-Bold" withSize:19];
    UIFont *buttonFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16];
    alert.buttonFormatBlock = ^NSDictionary *{
        return @{@"font": buttonFont, @"textColor": UIColor.redColor};
    };
    SCLButton *button = [alert addButton:@"Custom action" actionBlock:^{}];
    [alert addSwitchViewWithLabel:@"A switch before the field"];
    SCLTextView *field = [alert addTextField:@"Code" setDefaultText:@"123"];
    UIFont *fieldFont = [UIFont fontWithName:@"Courier-Oblique" size:15];
    field.font = fieldFont;
    UITextField *customField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    customField.font = [UIFont fontWithName:@"Georgia" size:17];
    [alert addCustomTextField:customField];
    [self showAlert:alert title:@"Custom fonts" message:@"Custom body"];

    for (UIContentSizeCategory category in @[UIContentSizeCategoryAccessibilityExtraExtraExtraLarge, UIContentSizeCategoryLarge]) {
        [self setCategory:category forAlert:alert];
        [self deliverContentSizeChange];
        [self assertFont:alert.labelTitle.font base:[UIFont fontWithName:@"Courier-Bold" size:24] style:UIFontTextStyleTitle2 alert:alert];
        [self assertFont:alert.viewText.font base:[UIFont fontWithName:@"Courier" size:18] style:UIFontTextStyleBody alert:alert];
        [self assertFont:button.titleLabel.font base:buttonFont style:UIFontTextStyleHeadline alert:alert];
        [self assertFont:field.font base:fieldFont style:UIFontTextStyleBody alert:alert];
        XCTAssertEqualObjects(button.titleLabel.textColor, UIColor.redColor);
        XCTAssertEqualObjects(customField.font.fontName, @"Georgia");
        XCTAssertEqualWithAccuracy(customField.font.pointSize, 17, 0.01);
    }

    [alert setTitleFontFamily:@"Georgia-Bold" withSize:22];
    [alert setBodyTextFontFamily:@"Georgia" withSize:16];
    [alert setButtonsTextFontFamily:@"Georgia-Bold" withSize:18];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraLarge forAlert:alert];
    [self assertFont:alert.labelTitle.font base:[UIFont fontWithName:@"Georgia-Bold" size:22] style:UIFontTextStyleTitle2 alert:alert];
    [self assertFont:alert.viewText.font base:[UIFont fontWithName:@"Georgia" size:16] style:UIFontTextStyleBody alert:alert];
    [self assertFont:alert.buttons.lastObject.titleLabel.font base:[UIFont fontWithName:@"Georgia-Bold" size:18] style:UIFontTextStyleHeadline alert:alert];
    [self assertFont:button.titleLabel.font base:buttonFont style:UIFontTextStyleHeadline alert:alert];
}

- (void)testPreferredFontsAreNotScaledAgain {
    SCLAlertView *alert = [self alertWithWidth:240];
    SCLTextView *field = [alert addTextField:@"Name" setDefaultText:nil];
    [self showAlert:alert title:@"Title" message:@"Body"];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:alert.traitCollection];
    alert.labelTitle.font = font;
    alert.viewText.font = font;
    alert.buttons.lastObject.titleLabel.font = font;
    field.font = font;
    [self deliverContentSizeChange];
    XCTAssertEqualWithAccuracy(alert.labelTitle.font.pointSize, font.pointSize, 0.01);
    XCTAssertEqualWithAccuracy(alert.viewText.font.pointSize, font.pointSize, 0.01);
    XCTAssertEqualWithAccuracy(alert.buttons.lastObject.titleLabel.font.pointSize, font.pointSize, 0.01);
    XCTAssertEqualWithAccuracy(field.font.pointSize, font.pointSize, 0.01);
}

- (void)testLiveChangesPreserveEditingAndSelection {
    SCLAlertView *alert = [self alertWithWidth:240];
    SCLTextView *field = [alert addTextField:@"Name" setDefaultText:@"Typed text"];
    [self showAlert:alert title:@"Edit" message:@"Keep editing while text size changes"];
    XCTAssertTrue([field becomeFirstResponder]);
    UITextPosition *start = [field positionFromPosition:field.beginningOfDocument offset:1];
    UITextPosition *end = [field positionFromPosition:field.beginningOfDocument offset:4];
    field.selectedTextRange = [field textRangeFromPosition:start toPosition:end];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];
    [self deliverContentSizeChange];
    XCTAssertTrue(field.isFirstResponder);
    XCTAssertEqualObjects(field.text, @"Typed text");
    XCTAssertEqual([field offsetFromPosition:field.beginningOfDocument toPosition:field.selectedTextRange.start], 1);
    XCTAssertEqual([field offsetFromPosition:field.beginningOfDocument toPosition:field.selectedTextRange.end], 4);
    [field resignFirstResponder];
}

- (void)testAttributedBodyScalesOriginalRunsAndPreservesOtherAttributes {
    SCLAlertView *alert = [self alertWithWidth:240];
    UIFont *emphasis = [UIFont fontWithName:@"Courier-Bold" size:18];
    NSURL *link = [NSURL URLWithString:@"https://example.com"];
    alert.attributedFormatBlock = ^NSAttributedString *(NSString *value) {
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:value];
        [text addAttributes:@{NSFontAttributeName: emphasis, NSForegroundColorAttributeName: UIColor.redColor,
                              NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSLinkAttributeName: link}
                      range:NSMakeRange(0, 4)];
        return text;
    };
    [self showAlert:alert title:@"Attributed" message:@"Bold and default text"];
    for (UIContentSizeCategory category in @[UIContentSizeCategoryAccessibilityExtraExtraExtraLarge, UIContentSizeCategorySmall, UIContentSizeCategoryLarge]) {
        [self setCategory:category forAlert:alert];
        [self deliverContentSizeChange];
        NSAttributedString *text = alert.viewText.attributedText;
        [self assertFont:[text attribute:NSFontAttributeName atIndex:0 effectiveRange:nil] base:emphasis style:UIFontTextStyleBody alert:alert];
        [self assertFont:[text attribute:NSFontAttributeName atIndex:5 effectiveRange:nil] base:[UIFont fontWithName:@"HelveticaNeue" size:14] style:UIFontTextStyleBody alert:alert];
        XCTAssertEqualObjects([text attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil], UIColor.redColor);
        XCTAssertEqualObjects([text attribute:NSUnderlineStyleAttributeName atIndex:0 effectiveRange:nil], @(NSUnderlineStyleSingle));
        XCTAssertEqualObjects([text attribute:NSLinkAttributeName atIndex:0 effectiveRange:nil], link);
        XCTAssertEqualObjects(text.string, @"Bold and default text");
    }
}

- (void)testLongContentScrollsWithoutOverlapsInSmallPortraitAndLandscapeHosts {
    SCLAlertView *alert = [self alertWithWidth:600];
    SCLTextView *field = [alert addTextField:@"Enter a value" setDefaultText:nil];
    [alert addButton:@"Continue to the next step with this information" actionBlock:^{}];
    [alert addButton:@"Review the information before continuing" actionBlock:^{}];
    NSString *paragraph = @"A longer message must remain readable at the largest accessibility text size. ";
    NSString *message = [@"" stringByPaddingToLength:paragraph.length * 12 withString:paragraph startingAtIndex:0];
    [self showAlert:alert title:@"A long alert title that must wrap to more than two lines without clipping" message:message];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];

    for (NSValue *size in @[[NSValue valueWithCGSize:CGSizeMake(320, 568)], [NSValue valueWithCGSize:CGSizeMake(568, 320)]]) {
        self.window.frame = (CGRect){CGPointZero, size.CGSizeValue};
        self.host.view.frame = self.window.bounds;
        alert.view.frame = self.host.view.bounds;
        [alert.view setNeedsLayout];
        [alert.view layoutIfNeeded];
        CGRect safe = UIEdgeInsetsInsetRect(alert.view.bounds, alert.view.safeAreaInsets);
        XCTAssertTrue(CGRectContainsRect(safe, alert.contentView.frame));
        if (!alert.circleViewBackground.hidden) {
            XCTAssertGreaterThanOrEqual(CGRectGetMinY(alert.circleViewBackground.frame), CGRectGetMinY(safe));
        }
        XCTAssertGreaterThan(CGRectGetHeight(alert.labelTitle.frame), alert.labelTitle.font.lineHeight * 2);
        XCTAssertGreaterThan(alert.contentScrollView.contentSize.height, CGRectGetHeight(alert.contentScrollView.bounds));
        XCTAssertFalse(alert.viewText.scrollEnabled);
        CGFloat bottom = 0;
        NSMutableArray<UIView *> *ordered = [NSMutableArray arrayWithObjects:alert.labelTitle, alert.viewText, field, nil];
        [ordered addObjectsFromArray:alert.buttons];
        for (UIView *view in ordered) {
            XCTAssertGreaterThanOrEqual(CGRectGetMinY(view.frame), bottom);
            bottom = CGRectGetMaxY(view.frame);
        }
        for (SCLButton *button in alert.buttons) {
            [button layoutIfNeeded];
            CGSize title = [button.titleLabel sizeThatFits:CGSizeMake(CGRectGetWidth(button.titleLabel.bounds), CGFLOAT_MAX)];
            XCTAssertGreaterThanOrEqual(CGRectGetHeight(button.titleLabel.bounds) + 1, title.height);
            XCTAssertGreaterThanOrEqual(CGRectGetHeight(button.frame), 44);
        }
        [self assertLastButtonIsReachable:alert];
    }
}

- (void)testHorizontalButtonsFallBackAndTimerFollowsResizedButton {
    SCLAlertView *alert = [self alertWithWidth:300];
    alert.horizontalButtons = YES;
    SCLButton *first = [alert addButton:@"Yes" actionBlock:^{}];
    SCLButton *second = [alert addButton:@"No" actionBlock:^{}];
    [self showAlert:alert title:@"Choose" message:@"Pick an action"];
    XCTAssertEqualWithAccuracy(CGRectGetMinY(first.frame), CGRectGetMinY(second.frame), 0.01);
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];
    XCTAssertGreaterThan(CGRectGetMinY(second.frame), CGRectGetMaxY(first.frame));
    SCLTimerDisplay *timer = [[SCLTimerDisplay alloc] initWithOrigin:CGPointZero radius:13 lineWidth:4];
    first.timer = timer;
    [self setCategory:UIContentSizeCategoryLarge forAlert:alert];
    [first setTitle:@"A long action that cannot fit in a horizontal button" forState:UIControlStateNormal];
    [alert.view setNeedsLayout];
    [alert.view layoutIfNeeded];
    [first layoutIfNeeded];
    XCTAssertGreaterThan(CGRectGetMinY(second.frame), CGRectGetMaxY(first.frame));
    XCTAssertLessThanOrEqual(CGRectGetMaxX(first.titleLabel.frame), CGRectGetMinX(timer.frame));
    XCTAssertEqualWithAccuracy(CGRectGetMidY(timer.frame), CGRectGetMidY(first.bounds), 0.5);
}

- (void)testKeyboardFrameChangesKeepThePanelAndButtonsReachable {
    SCLAlertView *alert = [self alertWithWidth:240];
    [alert addTextField:@"First" setDefaultText:nil];
    [alert addTextField:@"Second" setDefaultText:nil];
    [self showAlert:alert title:@"Edit information" message:@"A message above the input fields."];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];
    CGFloat shortViewportKeyboardHeight = CGRectGetHeight(self.window.bounds) - alert.view.safeAreaInsets.top - 120;
    for (NSNumber *keyboardHeight in @[@216, @280, @(shortViewportKeyboardHeight)]) {
        CGRect keyboard = CGRectMake(0, CGRectGetHeight(self.window.bounds) - keyboardHeight.doubleValue, CGRectGetWidth(self.window.bounds), keyboardHeight.doubleValue);
        CGRect screenKeyboard = [self.window convertRect:keyboard toCoordinateSpace:self.window.screen.coordinateSpace];
        NSDictionary *info = @{UIKeyboardFrameEndUserInfoKey: [NSValue valueWithCGRect:screenKeyboard],
                               UIKeyboardAnimationDurationUserInfoKey: @0, UIKeyboardAnimationCurveUserInfoKey: @0};
        [NSNotificationCenter.defaultCenter postNotificationName:UIKeyboardWillChangeFrameNotification object:nil userInfo:info];
        XCTAssertLessThanOrEqual(CGRectGetMaxY(alert.contentView.frame), CGRectGetMinY(keyboard));
        if (!alert.circleViewBackground.hidden) {
            XCTAssertGreaterThanOrEqual(CGRectGetMinY(alert.circleViewBackground.frame), alert.view.safeAreaInsets.top);
        }
        [self assertLastButtonIsReachable:alert];
    }
    XCTAssertTrue(alert.circleViewBackground.hidden);
    [NSNotificationCenter.defaultCenter postNotificationName:UIKeyboardWillHideNotification object:nil userInfo:@{UIKeyboardAnimationDurationUserInfoKey: @0}];
    [self setCategory:UIContentSizeCategoryLarge forAlert:alert];
    XCTAssertEqualWithAccuracy(alert.contentScrollView.contentOffset.y, 0, 0.01);
    [self assertLastButtonIsReachable:alert];
}

- (void)testNewWindowWithMissingTextAndRemovedCircleUsesHostBounds {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindowWidth:1000];
    alert.showAnimationType = SCLAlertViewShowAnimationFadeIn;
    [self.alerts addObject:alert];
    [alert removeTopCircle];
    [alert showInfo:@"" subTitle:@"" closeButtonTitle:@"Close" duration:0];
    [alert setTitleFontFamily:@"Courier" withSize:22];
    [alert setBodyTextFontFamily:@"Courier" withSize:18];
    [self setCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge forAlert:alert];
    XCTAssertNil(alert.labelTitle);
    XCTAssertNil(alert.viewText);
    XCTAssertNil(alert.circleViewBackground.superview);
    XCTAssertTrue(CGRectContainsRect(UIEdgeInsetsInsetRect(alert.view.bounds, alert.view.safeAreaInsets), alert.contentView.frame));
    [self assertLastButtonIsReachable:alert];
}

@end
