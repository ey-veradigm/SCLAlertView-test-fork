//
//  SCLButton.m
//  SCLAlertView
//
//  Created by Diogo Autilio on 9/26/14.
//  Copyright (c) 2014-2017 AnyKey Entertainment. All rights reserved.
//

#import "SCLButton.h"
#import "SCLTimerDisplay.h"

#define MARGIN_BUTTON 12.0f
#define DEFAULT_WINDOW_WIDTH 240
#define MIN_HEIGHT 44.0f

@implementation SCLButton

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setupWithWindowWidth:DEFAULT_WINDOW_WIDTH];
    }
    return self;
}

- (instancetype)initWithWindowWidth:(CGFloat)windowWidth
{
    self = [super init];
    if (self)
    {
        [self setupWithWindowWidth:windowWidth];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self setupWithWindowWidth:DEFAULT_WINDOW_WIDTH];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupWithWindowWidth:DEFAULT_WINDOW_WIDTH];
    }
    return self;
}

- (void)setupWithWindowWidth:(CGFloat)windowWidth
{
    self.frame = CGRectMake(0.0f, 0.0f, windowWidth - (MARGIN_BUTTON * 2), MIN_HEIGHT);
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 12.0f, 10.0f, 12.0f);
    self.layer.cornerRadius = 3.0f;
}

- (void)adjustWidthWithWindowWidth:(CGFloat)windowWidth numberOfButtons:(NSUInteger)numberOfButtons
{
    CGFloat allButtonsWidth = windowWidth - (MARGIN_BUTTON * 2);
    CGFloat buttonWidth = (allButtonsWidth - ((numberOfButtons - 1) * 10)) / numberOfButtons;
    
    self.frame = CGRectMake(0.0f, 0.0f, buttonWidth, [self sizeThatFits:CGSizeMake(buttonWidth, CGFLOAT_MAX)].height);
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [super setTitle:title forState:state];
    CGRect frame = self.frame;
    frame.size.height = [self sizeThatFits:CGSizeMake(CGRectGetWidth(frame), CGFLOAT_MAX)].height;
    self.frame = frame;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    UIEdgeInsets content = self.contentEdgeInsets;
    UIEdgeInsets title = self.titleEdgeInsets;
    CGFloat accessoryWidth = _timer ? CGRectGetWidth(_timer.bounds) + 10.0f : 0.0f;
    CGFloat horizontalPadding = content.left + content.right + title.left + title.right + accessoryWidth;
    CGFloat labelWidth = MAX(1.0f, size.width - horizontalPadding);
    CGSize labelSize = [self.titleLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    CGFloat height = ceil(labelSize.height + content.top + content.bottom + title.top + title.bottom);
    return CGSizeMake(MIN(size.width, ceil(labelSize.width + horizontalPadding)), MAX(height, MIN_HEIGHT));
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    CGRect content = [super contentRectForBounds:bounds];
    if (_timer) {
        content.size.width = MAX(0.0f, content.size.width - CGRectGetWidth(_timer.bounds) - 10.0f);
    }
    return content;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_timer updateFrame:self.bounds.size];
}

- (void)setHighlighted:(BOOL)highlighted
{
    self.backgroundColor = (highlighted) ? [self darkerColorForColor:_defaultBackgroundColor] : _defaultBackgroundColor;
    [super setHighlighted:highlighted];
}

- (void)setDefaultBackgroundColor:(UIColor *)defaultBackgroundColor
{
    self.backgroundColor = _defaultBackgroundColor = defaultBackgroundColor;
}

- (void)setTimer:(SCLTimerDisplay *)timer
{
    if (_timer != timer) {
        [_timer removeFromSuperview];
    }
    _timer = timer;
    if (timer && !timer.superview) {
        [self addSubview:timer];
    }
    [timer updateFrame:self.frame.size];
    timer.color = self.titleLabel.textColor;
    [self setNeedsLayout];
}

#pragma mark - Button Apperance

- (void)parseConfig:(NSDictionary *)buttonConfig
{
    if (buttonConfig[@"backgroundColor"])
    {
        self.defaultBackgroundColor = buttonConfig[@"backgroundColor"];
    }
    if (buttonConfig[@"textColor"])
    {
        [self setTitleColor:buttonConfig[@"textColor"] forState:UIControlStateNormal];
    }
    if (buttonConfig[@"cornerRadius"])
    {
        self.layer.cornerRadius = [buttonConfig[@"cornerRadius"] floatValue];
    }
    if ((buttonConfig[@"borderColor"]) && (buttonConfig[@"borderWidth"]))
    {
        self.layer.borderColor = ((UIColor*)buttonConfig[@"borderColor"]).CGColor;
        self.layer.borderWidth = [buttonConfig[@"borderWidth"] floatValue];
    }
    else if (buttonConfig[@"borderWidth"])
    {
        self.layer.borderWidth = [buttonConfig[@"borderWidth"] floatValue];
    }
    
    // Add Button custom font with buttonConfig parameters
    if (buttonConfig[@"font"]) {
        self.titleLabel.font = buttonConfig[@"font"];
    }
}

#pragma mark - Helpers

- (UIColor *)darkerColorForColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MAX(r - 0.2f, 0.0f)
                               green:MAX(g - 0.2f, 0.0f)
                                blue:MAX(b - 0.2f, 0.0f)
                               alpha:a];
    }
    return color;
}

- (UIColor *)lighterColorForColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MIN(r + 0.2f, 1.0f)
                               green:MIN(g + 0.2f, 1.0f)
                                blue:MIN(b + 0.2f, 1.0f)
                               alpha:a];
    }
    return color;
}

@end
