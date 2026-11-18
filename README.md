SCLAlertView-Objective-C
============

Animated Alert View written in Swift but ported to Objective-C, which can be used as a `UIAlertView` or `UIAlertController` replacement.

### Private FollowMyHealth copy

This **private** repository imports the complete Git ancestry of
[dogo/SCLAlertView](https://github.com/dogo/SCLAlertView) through stable release
`1.4.2` (`09d5749dc3acfe0be3d6779845058252b83b9e59`), the latest stable release
checked on November 18, 2026. Upstream commit history, the original authorship, the
MIT [license](LICENSE), and the acknowledgements below are preserved. Private
podspec version `1.4.3-fmh.1` adds Dynamic Type; upstream release `1.4.2` does
**not** contain these changes. This copy uses a commit pin, not a fork release tag.
Do not publish this copy or its podspec to CocoaPods trunk.

FMHmobile-iOS has not been changed and does not consume this copy yet. See
[private CocoaPods consumption](#followmyhealth-private-cocoapods-consumption)
for a future, separately reviewed dependency change.

### Dynamic Type

Titles, body text, action/close buttons, and fields created by `addTextField:setDefaultText:`
follow the alert's iOS content-size-category traits, including all accessibility
sizes. Changes while visible remeasure the existing controls without dismissing
the alert or replacing its text fields.

The existing font-family/size APIs still work. Sizes and custom `font` entries in
button formatting dictionaries are **unscaled base fonts at the Large category**.
The same applies to font attributes returned by `attributedFormatBlock`; other
attributes, such as links, colors, and emphasis, are retained. The alert retains
unscaled sources and applies `UIFontMetrics` once per update, rather than scaling
the previously displayed font. Attribute-only edits to a displayed message retain
the original font bases; genuine font edits supply new unscaled fonts.
Do not pre-scale these base-font inputs or also enable automatic scaling on
library-managed controls. Standard preferred fonts assigned directly to controls
are left to UIKit instead of being scaled twice.

Text wraps without a line limit. The panel stays within its host's safe area and
above a docked keyboard; its contents, including the buttons, scroll together
when necessary. Buttons and built-in fields have a minimum 44-point height.
The scroll viewport starts below fixed circle clearance, so text and controls
cannot pass underneath the circle at nonzero scroll offsets.
The decorative circle hides temporarily if it would leave less than a line of
text or a control's minimum height visible in a short keyboard-constrained host.
`horizontalButtons` remains a preference: accessibility sizes or titles that do
not fit side by side use a vertical stack. Custom views, switch labels, and
fields supplied through `addCustomTextField:` retain caller-managed typography
and sizing.

The following badges describe **upstream**, not validation of this private copy.

![Upstream Build Status](https://github.com/dogo/SCLAlertView/workflows/Building/badge.svg)
[![Cocoapods](http://img.shields.io/cocoapods/v/SCLAlertView-Objective-C.svg)](http://cocoapods.org/?q=SCLAlertView-Objective-C)
[![Pod License](http://img.shields.io/cocoapods/l/SCLAlertView-Objective-C.svg)](https://github.com/dogo/SCLAlertView/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot.png)_
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot2.png) 
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot3.png)_ 
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot4.png) 
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot5.png)_
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot6.png)
![BackgroundImage](https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot7.png)

### Fluent style

```Objective-C

SCLAlertViewBuilder *builder = [SCLAlertViewBuilder new]
.addButtonWithActionBlock(@"Send", ^{ /*work here*/ });
SCLAlertViewShowBuilder *showBuilder = [SCLAlertViewShowBuilder new]
.style(SCLAlertViewStyleWarning)
.title(@"Title")
.subTitle(@"Subtitle")
.duration(0);
[showBuilder showAlertView:builder.alertView onViewController:self.window.rootViewController];
// or even
showBuilder.show(builder.alertView, self.window.rootViewController);
```

#### Complex
```Objective-C
    NSString *title = @"Title";
    NSString *message = @"Message";
    NSString *cancel = @"Cancel";
    NSString *done = @"Done";
    
    SCLALertViewTextFieldBuilder *textField = [SCLALertViewTextFieldBuilder new].title(@"Code");
    SCLALertViewButtonBuilder *doneButton = [SCLALertViewButtonBuilder new].title(done)
    .validationBlock(^BOOL{
        NSString *code = [textField.textField.text copy];
        return [code isVisible];
    })
    .actionBlock(^{
        NSString *code = [textField.textField.text copy];
        [self confirmPhoneNumberWithCode:code];
    });
    
    SCLAlertViewBuilder *builder = [SCLAlertViewBuilder new]
    .showAnimationType(SCLAlertViewShowAnimationFadeIn)
    .hideAnimationType(SCLAlertViewHideAnimationFadeOut)
    .shouldDismissOnTapOutside(NO)
    .addTextFieldWithBuilder(textField)
    .addButtonWithBuilder(doneButton);
    
    SCLAlertViewShowBuilder *showBuilder = [SCLAlertViewShowBuilder new]
    .style(SCLAlertViewStyleCustom)
    .image([SCLAlertViewStyleKit imageOfInfo])
    .color([UIColor blueColor])
    .title(title)
    .subTitle(message)
    .closeButtonTitle(cancel)
    .duration(0.0f);

    [showBuilder showAlertView:builder.alertView onViewController:self];
```

### Easy to use
```Objective-C
// Get started
SCLAlertView *alert = [[SCLAlertView alloc] init];

[alert showSuccess:self title:@"Hello World" subTitle:@"This is a more descriptive text." closeButtonTitle:@"Done" duration:0.0f];

// Alternative alert types
[alert showError:self title:@"Hello Error" subTitle:@"This is a more descriptive error text." closeButtonTitle:@"OK" duration:0.0f]; // Error
[alert showNotice:self title:@"Hello Notice" subTitle:@"This is a more descriptive notice text." closeButtonTitle:@"Done" duration:0.0f]; // Notice
[alert showWarning:self title:@"Hello Warning" subTitle:@"This is a more descriptive warning text." closeButtonTitle:@"Done" duration:0.0f]; // Warning
[alert showInfo:self title:@"Hello Info" subTitle:@"This is a more descriptive info text." closeButtonTitle:@"Done" duration:0.0f]; // Info
[alert showEdit:self title:@"Hello Edit" subTitle:@"This is a more descriptive info text with a edit textbox" closeButtonTitle:@"Done" duration:0.0f]; // Edit
[alert showCustom:self image:[UIImage imageNamed:@"git"] color:color title:@"Custom" subTitle:@"Add a custom icon and color for your own type of alert!" closeButtonTitle:@"OK" duration:0.0f]; // Custom
[alert showWaiting:self title:@"Waiting..." subTitle:@"Blah de blah de blah, blah. Blah de blah de" closeButtonTitle:nil duration:5.0f];
[alert showQuestion:self title:@"Question?" subTitle:kSubtitle closeButtonTitle:@"Dismiss" duration:0.0f];


// Using custom alert width
SCLAlertView *alert = [[SCLAlertView alloc] initWithWindowWidth:300.0f];
```

### SCLAlertview in a new window. (No UIViewController)
```Objective-C

SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];

[alert showSuccess:@"Hello World" subTitle:@"This is a more descriptive text." closeButtonTitle:@"Done" duration:0.0f];

// Alternative alert types
[alert showError:@"Hello Error" subTitle:@"This is a more descriptive error text." closeButtonTitle:@"OK" duration:0.0f]; // Error
[alert showNotice:@"Hello Notice" subTitle:@"This is a more descriptive notice text." closeButtonTitle:@"Done" duration:0.0f]; // Notice
[alert showWarning:@"Hello Warning" subTitle:@"This is a more descriptive warning text." closeButtonTitle:@"Done" duration:0.0f]; // Warning
[alert showInfo:@"Hello Info" subTitle:@"This is a more descriptive info text." closeButtonTitle:@"Done" duration:0.0f]; // Info
[alert showEdit:@"Hello Edit" subTitle:@"This is a more descriptive info text with a edit textbox" closeButtonTitle:@"Done" duration:0.0f]; // Edit
[alert showCustom:[UIImage imageNamed:@"git"] color:color title:@"Custom" subTitle:@"Add a custom icon and color for your own type of alert!" closeButtonTitle:@"OK" duration:0.0f]; // Custom
[alert showWaiting:@"Waiting..." subTitle:@"Blah de blah de blah, blah. Blah de blah de" closeButtonTitle:nil duration:5.0f];
[alert showQuestion:@"Question?" subTitle:kSubtitle closeButtonTitle:@"Dismiss" duration:0.0f];

// Using custom alert width
SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindowWidth:300.0f];
```

### Add buttons
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];

//Using Selector
[alert addButton:@"First Button" target:self selector:@selector(firstButton)];

//Using Block
[alert addButton:@"Second Button" actionBlock:^(void) {
    NSLog(@"Second button tapped");
}];

//Using Blocks With Validation
[alert addButton:@"Validate" validationBlock:^BOOL {
    BOOL passedValidation = ....
    return passedValidation;

} actionBlock:^{
    // handle successful validation here
}];

[alert showSuccess:self title:@"Button View" subTitle:@"This alert view has buttons" closeButtonTitle:@"Done" duration:0.0f];
```

### Add button timer
```Objective-C
//The index of the button to add the timer display to.
[alert addTimerToButtonIndex:0 reverse:NO];
```

Example:

```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];
[alert addTimerToButtonIndex:0 reverse:YES];
[alert showInfo:self title:@"Countdown Timer" subTitle:@"This alert has a duration set, and a countdown timer on the Dismiss button to show how long is left." closeButtonTitle:@"Dismiss" duration:10.0f];
```


### Add Text Attributes
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];

alert.attributedFormatBlock = ^NSAttributedString* (NSString *value)
{
    NSMutableAttributedString *subTitle = [[NSMutableAttributedString alloc]initWithString:value];

    NSRange redRange = [value rangeOfString:@"Attributed" options:NSCaseInsensitiveSearch];
    [subTitle addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:redRange];

    NSRange greenRange = [value rangeOfString:@"successfully" options:NSCaseInsensitiveSearch];
    [subTitle addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:greenRange];

    NSRange underline = [value rangeOfString:@"completed" options:NSCaseInsensitiveSearch];
    [subTitle addAttributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)} range:underline];

    return subTitle;
};

[alert showSuccess:self title:@"Button View" subTitle:@"Attributed string operation successfully completed." closeButtonTitle:@"Done" duration:0.0f];
```

### Add a text field
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];

UITextField *textField = [alert addTextField:@"Enter your name" setDefaultText:nil];

[alert addButton:@"Show Name" actionBlock:^(void) {
    NSLog(@"Text value: %@", textField.text);
}];

[alert showEdit:self title:@"Edit View" subTitle:@"This alert view shows a text box" closeButtonTitle:@"Done" duration:0.0f];
```

### Indeterminate progress
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];
    
[alert showWaiting:self title:@"Waiting..." subTitle:@"Blah de blah de blah, blah. Blah de blah de" closeButtonTitle:nil duration:5.0f];
```

### Add a switch button
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];
    
SCLSwitchView *switchView = [alert addSwitchViewWithLabel:@"Don't show again".uppercaseString];
switchView.tintColor = [UIColor brownColor];
    
[alert addButton:@"Done" actionBlock:^(void) {
    NSLog(@"Show again? %@", switchView.isSelected ? @"-No": @"-Yes");
}];
    
[alert showCustom:self image:[UIImage imageNamed:@"switch"] color:[UIColor brownColor] title:kInfoTitle subTitle:kSubtitle closeButtonTitle:nil duration:0.0f];
```

### Add custom view
```Objective-C
SCLAlertView *alert = [[SCLAlertView alloc] init];

UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 215.0f, 80.0f)];
customView.backgroundColor = [UIColor redColor];

[alert addCustomView:customView];

[alert showNotice:self title:@"Title" subTitle:@"This alert view shows a custom view" closeButtonTitle:@"Done" duration:0.0f];
```

### SCLAlertView properties
```Objective-C
//Dismiss on tap outside (Default is NO)
alert.shouldDismissOnTapOutside = YES;

//Hide animation type (Default is SCLAlertViewHideAnimationFadeOut)
alert.hideAnimationType = SCLAlertViewHideAnimationSlideOutToBottom;

//Show animation type (Default is SCLAlertViewShowAnimationSlideInFromTop)
alert.showAnimationType =  SCLAlertViewShowAnimationSlideInFromLeft;

//Set background type (Default is SCLAlertViewBackgroundShadow)
alert.backgroundType = SCLAlertViewBackgroundBlur;

//Overwrite SCLAlertView (Buttons, top circle and borders) colors
alert.customViewColor = [UIColor purpleColor];

//Set custom tint color for icon image.
alert.iconTintColor = [UIColor purpleColor];

//Override top circle tint color with background color
alert.tintTopCircle = NO;

//Set custom corner radius for SCLAlertView
alert.cornerRadius = 13.0f;

//Overwrite SCLAlertView background color
alert.backgroundViewColor = [UIColor cyanColor];

//Returns if the alert is visible or not.
alert.isVisible;

//Make the top circle icon larger
alert.useLargerIcon = YES;

//Using sound
alert.soundURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/right_answer.mp3", [[NSBundle mainBundle] resourcePath]]];


```

### Helpers
```Objective-C
//Receiving information that SCLAlertView is dismissed
[alert alertIsDismissed:^{
    NSLog(@"SCLAlertView dismissed!");
}];
```

#### Alert View Styles
```Objective-C
typedef NS_ENUM(NSInteger, SCLAlertViewStyle)
{
    SCLAlertViewStyleSuccess,
    SCLAlertViewStyleError,
    SCLAlertViewStyleNotice,
    SCLAlertViewStyleWarning,
    SCLAlertViewStyleInfo,
    SCLAlertViewStyleEdit,
    SCLAlertViewStyleWaiting,
    SCLAlertViewStyleQuestion,
    SCLAlertViewStyleCustom
};
```
#### Alert View hide animation styles
```Objective-C
typedef NS_ENUM(NSInteger, SCLAlertViewHideAnimation)
{
    SCLAlertViewHideAnimationFadeOut,
    SCLAlertViewHideAnimationSlideOutToBottom,
    SCLAlertViewHideAnimationSlideOutToTop,
    SCLAlertViewHideAnimationSlideOutToLeft,
    SCLAlertViewHideAnimationSlideOutToRight,
    SCLAlertViewHideAnimationSlideOutToCenter,
    SCLAlertViewHideAnimationSlideOutFromCenter,
    SCLAlertViewHideAnimationSimplyDisappear
};
```
#### Alert View show animation styles
```Objective-C
typedef NS_ENUM(NSInteger, SCLAlertViewShowAnimation)
{
    SCLAlertViewShowAnimationFadeIn,
    SCLAlertViewShowAnimationSlideInFromBottom,
    SCLAlertViewShowAnimationSlideInFromTop,
    SCLAlertViewShowAnimationSlideInFromLeft,
    SCLAlertViewShowAnimationSlideInFromRight,
    SCLAlertViewShowAnimationSlideInFromCenter,
    SCLAlertViewShowAnimationSlideInToCenter,
    SCLAlertViewShowAnimationSimplyAppear
};
```

#### Alert View background styles
```Objective-C
typedef NS_ENUM(NSInteger, SCLAlertViewBackground)
{
    SCLAlertViewBackgroundShadow,
    SCLAlertViewBackgroundBlur,
    SCLAlertViewBackgroundTransparent
};
```

### Installation

#### FollowMyHealth private CocoaPods consumption

In a **future** FMHmobile-iOS change, replace the existing declaration of the same
pod with this immutable private implementation commit (do not add a second copy):

```ruby
pod 'SCLAlertView-Objective-C',
    :git => 'git@github.com:ey-veradigm/SCLAlertView-test-fork.git',
    :commit => '1161af717d8e2eaf3e4d0005a1b61072bfd56802'
```

Keep the existing pod name, imports, and iOS 12.0-or-newer deployment target. No
private specs repository or fork release tag is required: CocoaPods uses the
Podfile's explicit Git/commit override. Developers need
repository read access and GitHub SSH authentication; CI needs a read-only deploy
key or appropriately scoped GitHub App credentials. HTTPS with an authenticated
Git credential helper is also supported by the podspec. Never put tokens or
private keys in a Podfile, URL, or source file.

From that application's existing Bundler/CocoaPods environment, run
`bundle exec pod update SCLAlertView-Objective-C --no-repo-update`, inspect the
targeted Podfile.lock diff, and commit both Podfile and Podfile.lock. The lockfile
must identify this private remote and the exact implementation commit above.
Pin future updates to a newly reviewed implementation SHA rather than a floating
branch. Validate the application's alerts before adopting it; this repository
does not perform that dependency switch.

The remaining installation examples refer to the **public upstream** package
and do not install the private Dynamic Type changes.

SCLAlertView-Objective-C is available through :

### [CocoaPods](https://cocoapods.org)

To install add the following line to your Podfile:

    pod 'SCLAlertView-Objective-C'
    
### [Carthage](https://github.com/Carthage/Carthage)

```
github "dogo/SCLAlertView"
```    

### Validation

The existing `SCLAlertView` XCTest target covers every text-size category,
repeated live changes, custom and attributed fonts, small portrait/landscape
hosts, scrolling and button hit testing, horizontal fallback, timer placement,
keyboard frame changes, retained editing/selection, attribute-only message edits,
nonzero-offset circle clearance, and new-window alerts with absent title/body text.
The build workflow is configured to run that target, build the framework, and
lint the pod. It uses an Intel macOS runner and selects an installed iPhone
simulator instead of depending on a particular simulator OS image.

On macOS with Xcode and an installed simulator (adjust the destination as needed):

```sh
xcrun simctl list devices available
xcodebuild -project SCLAlertView.xcodeproj -scheme SCLAlertView \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  clean build test CODE_SIGNING_ALLOWED=NO
xcodebuild -project SCLAlertView.xcodeproj -scheme SCLAlertViewFramework \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
bundle install
bundle exec pod lib lint SCLAlertView-Objective-C.podspec --allow-warnings
```

Linux cannot compile UIKit, run these XCTest/simulator tests, or perform the
Xcode build stage of CocoaPods lint. Ruby/podspec and project-structure checks
are not substitutes for those Apple-tooling checks.

Before FMH adoption, manually check VoiceOver focus/scrolling, the smallest
supported device in both orientations, iPad split-screen/modal presentation,
new-window alerts, keyboard editing, and changing per-app Text Size while an
alert is visible. Include the largest Accessibility Text Size and confirm typed
text, selection, and first responder are retained.

### Collaboration
I tried to build an easy to use API, while beeing flexible enough for multiple variations, but I'm sure there are ways of improving and adding more features, so feel free to collaborate with ideas, issues and/or pull requests.

### Incoming improvements
- More animations
- Performance tests
- Remove some hardcode values

### Plugin integrations

- [nativescript-fancyalert for NativeScript](https://github.com/NathanWalker/nativescript-fancyalert)
  - Use SCLAlertView with [NativeScript](https://www.nativescript.org/)

### Thanks to the original team
- Design [@SherzodMx](https://twitter.com/SherzodMx) Sherzod Max
- Development [@hackua](https://twitter.com/hackua) Viktor Radchenko
- Improvements by [@bih](http://github.com/bih) Bilawal Hameed, [@rizjoj](http://github.com/rizjoj) Riz Joj

https://github.com/vikmeup/SCLAlertView-Swift
