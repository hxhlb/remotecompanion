#import "RCWiFiTriggerViewController.h"
#import "RCConfigManager.h"
#import "RCActionsViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface RCWiFiTriggerViewController () <UITextFieldDelegate>
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, assign) BOOL isDisconnectTrigger;
@property (nonatomic, strong) UITextField *ssidField;
@end

@implementation RCWiFiTriggerViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WiFi Trigger";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.ssid = [self currentWiFiSSID] ?: @"";
    self.isDisconnectTrigger = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(saveTrigger)];
}

- (NSString *)currentWiFiSSID {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    return [info objectForKey:@"SSID"];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2; // Connect / Disconnect
    return 1; // SSID Field
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Trigger Event";
    return @"Network Name (SSID)";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TypeCell"];
        }
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Connected to Network";
            cell.accessoryType = !self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"Disconnected from Network";
            cell.accessoryType = self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        if (!self.ssidField) {
            self.ssidField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, tableView.bounds.size.width - 40, 44)];
            self.ssidField.placeholder = @"Enter SSID";
            self.ssidField.text = self.ssid;
            self.ssidField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.ssidField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.ssidField.delegate = self;
            self.ssidField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }
        [cell.contentView addSubview:self.ssidField];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        self.isDisconnectTrigger = (indexPath.row == 1);
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)saveTrigger {
    NSString *finalSSID = [self.ssidField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (finalSSID.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name Required" message:@"Please enter a WiFi network name." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *prefix = self.isDisconnectTrigger ? @"wifi_disconnect_" : @"wifi_connect_";
    NSString *triggerKey = [prefix stringByAppendingString:finalSSID];
    
    RCConfigManager *config = [RCConfigManager sharedManager];
    
    // Create friendly name
    NSString *subTitle = self.isDisconnectTrigger ? @"Disconnected from" : @"Connected to";
    NSString *friendlyName = [NSString stringWithFormat:@"%@ %@", subTitle, finalSSID];
    
    NSDictionary *triggerData = @{
        @"name": friendlyName,
        @"enabled": @YES,
        @"actions": @[]
    };
    
    [config updateTrigger:triggerKey withData:triggerData];
    
    // Redirect to action picker for the new trigger
    RCActionsViewController *vc = [[RCActionsViewController alloc] initWithTriggerKey:triggerKey];
    NSMutableArray *vcs = [self.navigationController.viewControllers mutableCopy];
    [vcs removeLastObject]; // Remove self
    [vcs addObject:vc];
    [self.navigationController setViewControllers:vcs animated:YES];
}

@end
