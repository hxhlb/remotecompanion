#import "RCNotificationTriggerViewController.h"
#import "RCConfigManager.h"
#import "RCActionsViewController.h"

@interface RCNotificationTriggerViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *bundleIdField;
@property (nonatomic, strong) UITextField *textMatchField;
@property (nonatomic, strong) UITextField *nameField;
@end

@implementation RCNotificationTriggerViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Notification Trigger";
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(applyTweaks) 
                                                 name:@"RCConfigTweaksChangedNotification" 
                                               object:nil];
    
    [self applyTweaks];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(saveTrigger)];
}

- (void)applyTweaks {
    RCConfigManager *cm = [RCConfigManager sharedManager];
    UIColor *bg = [cm tweakColorForKey:@"mainBackground" defaultVal:0.09];
    self.view.backgroundColor = bg;
    self.navigationController.navigationBar.backgroundColor = bg;
    self.tableView.backgroundColor = bg;
    self.tableView.separatorColor = [cm tweakColorForKey:@"separators" defaultVal:0.30];
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"App Bundle Identifier (e.g. com.apple.MobileSMS)";
    if (section == 1) return @"Text Match (Optional)";
    return @"Trigger Name";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"Leave empty to match notifications from ALL apps.";
    if (section == 1) return @"Matches text in the title, subtitle, or body (case-insensitive).";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, tableView.bounds.size.width - 40, 44)];
    field.delegate = self;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    if (indexPath.section == 0) {
        field.placeholder = @"com.apple.MobileSMS";
        self.bundleIdField = field;
    } else if (indexPath.section == 1) {
        field.placeholder = @"Keyword to match";
        self.textMatchField = field;
    } else {
        field.placeholder = @"My Trigger Name";
        field.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.nameField = field;
    }
    
    [cell.contentView addSubview:field];
    return cell;
}

- (void)saveTrigger {
    NSString *bundleId = [self.bundleIdField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *textMatch = [self.textMatchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (name.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name Required" message:@"Please enter a name for this trigger." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    RCConfigManager *config = [RCConfigManager sharedManager];
    NSString *uniqueId = [[NSUUID UUID].UUIDString substringToIndex:8];
    NSString *triggerKey = [NSString stringWithFormat:@"notif_%@", uniqueId];
    
    NSDictionary *notificationEntry = @{
        @"triggerKey": triggerKey,
        @"bundleId": bundleId ?: @"",
        @"textMatch": textMatch ?: @"",
        @"enabled": @YES,
        @"name": name
    };
    
    NSMutableArray *notifTriggers = [[config notificationTriggers] mutableCopy];
    [notifTriggers addObject:notificationEntry];
    [config setNotificationTriggers:notifTriggers];
    
    NSDictionary *triggerData = @{
        @"name": name,
        @"enabled": @YES,
        @"actions": @[]
    };
    
    [config updateTrigger:triggerKey withData:triggerData];
    
    // Redirect to action picker
    RCActionsViewController *vc = [[RCActionsViewController alloc] initWithTriggerKey:triggerKey];
    NSMutableArray *vcs = [self.navigationController.viewControllers mutableCopy];
    [vcs removeLastObject]; // Remove self
    [vcs addObject:vc];
    [self.navigationController setViewControllers:vcs animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
