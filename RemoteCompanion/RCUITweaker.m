#import "RCUITweaker.h"
#import "RCConfigManager.h"

@interface RCUITweakerView : UIView
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *minimizeButton;
@property (nonatomic, strong) UIButton *btnCopySettings;
@property (nonatomic, strong) UIStackView *slidersStack;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL isMinimized;
@property (nonatomic, assign) CGRect expandedFrame;
@end

@implementation RCUITweakerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        self.layer.borderWidth = 1.0;
        
        [self setupHeader];
        [self setupScrollView];
        [self buildSliders];
        
        // Drag gesture
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.headerView addGestureRecognizer:pan];
    }
    return self;
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 40)];
    self.headerView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.headerView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 40)];
    self.titleLabel.text = @"UI Tweaker";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.headerView addSubview:self.titleLabel];
    
    self.minimizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.minimizeButton.frame = CGRectMake(self.bounds.size.width - 40, 0, 40, 40);
    [self.minimizeButton setImage:[UIImage systemImageNamed:@"minus"] forState:UIControlStateNormal];
    self.minimizeButton.tintColor = [UIColor whiteColor];
    [self.minimizeButton addTarget:self action:@selector(toggleMinimize) forControlEvents:UIControlEventTouchUpInside];
    self.minimizeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.headerView addSubview:self.minimizeButton];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.bounds.size.width, self.bounds.size.height - 40)];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.scrollView];
    
    self.slidersStack = [[UIStackView alloc] initWithFrame:CGRectMake(10, 10, self.bounds.size.width - 20, 0)];
    self.slidersStack.axis = UILayoutConstraintAxisVertical;
    self.slidersStack.spacing = 15;
    self.slidersStack.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.scrollView addSubview:self.slidersStack];
}

- (void)buildSliders {
    NSArray *tweaks = @[
        @{@"key": @"mainBackground", @"name": @"Main BG", @"default": @(0.0)},
        @{@"key": @"blockBackground", @"name": @"Block BG", @"default": @(0.1)},
        @{@"key": @"separators", @"name": @"Separators", @"default": @(0.2)},
        @{@"key": @"borders", @"name": @"Borders", @"default": @(0.3)},
        @{@"key": @"navBar", @"name": @"Nav Bar BG", @"default": @(0.05)},
        @{@"key": @"selectionHighlight", @"name": @"Selection Highlight", @"default": @(0.2)},
        @{@"key": @"shadowBrightness", @"name": @"Shadow Brightness", @"default": @(0.0)},
        @{@"key": @"shadowOpacity", @"name": @"Shadow Opacity", @"default": @(0.5)}
    ];
    
    for (NSDictionary *info in tweaks) {
        NSString *key = info[@"key"];
        NSString *name = info[@"name"];
        CGFloat def = [info[@"default"] floatValue];
        
        CGFloat currentVal = [[RCConfigManager sharedManager] tweakValueForKey:key defaultVal:def];
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.slidersStack.bounds.size.width, 50)];
        
        UILabel *lblName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
        lblName.text = name;
        lblName.textColor = [UIColor lightGrayColor];
        lblName.font = [UIFont systemFontOfSize:12];
        [container addSubview:lblName];
        
        UILabel *lblVal = [[UILabel alloc] initWithFrame:CGRectMake(container.bounds.size.width - 50, 0, 50, 20)];
        lblVal.text = [NSString stringWithFormat:@"%.2f", currentVal];
        lblVal.textColor = [UIColor whiteColor];
        lblVal.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
        lblVal.textAlignment = NSTextAlignmentRight;
        lblVal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [container addSubview:lblVal];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 20, container.bounds.size.width, 30)];
        slider.minimumValue = 0.0;
        slider.maximumValue = 1.0;
        slider.value = currentVal;
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // Attach info using associated objects or subclass? 
        // We can use the accessibilityIdentifier as a hack to store the key
        slider.accessibilityIdentifier = key;
        [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        [container addSubview:slider];
        
        [self.slidersStack addArrangedSubview:container];
        
        // Store label reference to update text
        slider.accessibilityElements = @[lblVal]; 
    }
    
    // Add Copy button
    self.btnCopySettings = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnCopySettings setTitle:@"Copy Settings" forState:UIControlStateNormal];
    [self.btnCopySettings setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnCopySettings.backgroundColor = [UIColor systemBlueColor];
    self.btnCopySettings.layer.cornerRadius = 8;
    [self.btnCopySettings addTarget:self action:@selector(copySettings) forControlEvents:UIControlEventTouchUpInside];
    
    [self.slidersStack addArrangedSubview:self.btnCopySettings];
    
    // Update stack layout
    [self.slidersStack layoutIfNeeded];
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, self.slidersStack.frame.size.height + 20);
}

- (void)sliderChanged:(UISlider *)slider {
    NSString *key = slider.accessibilityIdentifier;
    CGFloat val = slider.value;
    
    UILabel *lblVal = slider.accessibilityElements.firstObject;
    lblVal.text = [NSString stringWithFormat:@"%.2f", val];
    
    NSDictionary *currentTweaks = [[RCConfigManager sharedManager] colorTweaks];
    NSMutableDictionary *mutTweaks = [currentTweaks mutableCopy];
    mutTweaks[key] = @(val);
    
    [[RCConfigManager sharedManager] setColorTweaks:mutTweaks];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCConfigTweaksChangedNotification" object:nil];
}

- (void)copySettings {
    NSDictionary *tweaks = [[RCConfigManager sharedManager] colorTweaks];
    NSMutableString *str = [NSMutableString stringWithString:@"Current UI Color Tweaks:\n"];
    for (NSString *key in tweaks) {
        [str appendFormat:@"- %@: %@\n", key, tweaks[key]];
    }
    
    [UIPasteboard generalPasteboard].string = str;
    
    [self.btnCopySettings setTitle:@"Copied!" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.btnCopySettings setTitle:@"Copy Settings" forState:UIControlStateNormal];
    });
}



- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
    [pan setTranslation:CGPointZero inView:self.superview];
    
    if (!self.isMinimized) {
        self.expandedFrame = self.frame;
    }
}

- (void)toggleMinimize {
    self.isMinimized = !self.isMinimized;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isMinimized) {
            self.expandedFrame = self.frame;
            CGRect newFrame = self.frame;
            newFrame.size.height = 40;
            self.frame = newFrame;
            self.scrollView.alpha = 0;
            [self.minimizeButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        } else {
            self.frame = self.expandedFrame;
            self.scrollView.alpha = 1;
            [self.minimizeButton setImage:[UIImage systemImageNamed:@"minus"] forState:UIControlStateNormal];
        }
    }];
}

@end

static RCUITweakerView *sharedTweakerView = nil;

@implementation RCUITweaker

+ (void)show {
    if (sharedTweakerView) {
        [sharedTweakerView removeFromSuperview];
    }
    
    UIWindow *window = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) {
            window = w;
            break;
        }
    }
    
    if (!window) return;
    
    CGFloat width = 280;
    CGFloat height = 400;
    sharedTweakerView = [[RCUITweakerView alloc] initWithFrame:CGRectMake(window.bounds.size.width - width - 20, 100, width, height)];
    sharedTweakerView.expandedFrame = sharedTweakerView.frame;
    [window addSubview:sharedTweakerView];
}

+ (void)hide {
    if (sharedTweakerView) {
        [sharedTweakerView removeFromSuperview];
        sharedTweakerView = nil;
    }
}

@end
