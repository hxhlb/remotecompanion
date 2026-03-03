#import "RCBluetoothTriggerViewController.h"
#import "RCConfigManager.h"
#import "RCActionsViewController.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@interface BluetoothDevice : NSObject
- (NSString *)name;
- (NSString *)address;
@end

@interface BluetoothManager : NSObject
+ (instancetype)sharedInstance;
- (NSArray *)pairedDevices;
@end

@interface RCBluetoothTriggerViewController ()
@property (nonatomic, strong) NSArray *devices;
@property (nonatomic, assign) BOOL isDisconnectTrigger;
@property (nonatomic, strong) BluetoothManager *btManager;
@end

@implementation RCBluetoothTriggerViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Bluetooth Trigger";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Load BluetoothManager
    void *btHandle = dlopen("/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager", RTLD_NOW);
    if (btHandle) {
        Class btClass = objc_getClass("BluetoothManager");
        if (btClass) {
            self.btManager = [btClass sharedInstance];
            self.devices = [self.btManager pairedDevices];
            NSLog(@"[RCBluetoothTrigger] Found %lu paired devices", (unsigned long)self.devices.count);
        }
    }
    
    if (!self.devices || self.devices.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        emptyLabel.text = @"No Paired Devices Found";
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.textColor = [UIColor secondaryLabelColor];
        self.tableView.backgroundView = emptyLabel;
    }
    
    self.isDisconnectTrigger = NO;
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2; // Connect / Disconnect
    return self.devices.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Trigger Event";
    return @"Select Device";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Connected to Device";
            cell.accessoryType = !self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"Disconnected from Device";
            cell.accessoryType = self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        cell.detailTextLabel.text = nil;
    } else {
        BluetoothDevice *device = self.devices[indexPath.row];
        cell.textLabel.text = [device name];
        cell.detailTextLabel.text = [device address];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        self.isDisconnectTrigger = (indexPath.row == 1);
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        BluetoothDevice *device = self.devices[indexPath.row];
        [self saveTriggerForDevice:device];
    }
}

- (void)saveTriggerForDevice:(BluetoothDevice *)device {
    NSString *address = [device address];
    NSString *name = [device name];
    
    if (!address) return;
    
    NSString *prefix = self.isDisconnectTrigger ? @"bt_disconnect_" : @"bt_connect_";
    NSString *triggerKey = [prefix stringByAppendingString:address];
    
    RCConfigManager *config = [RCConfigManager sharedManager];
    
    // Create friendly name
    NSString *subTitle = self.isDisconnectTrigger ? @"Disconnected from" : @"Connected to";
    NSString *friendlyName = [NSString stringWithFormat:@"%@ %@", subTitle, name];
    
    NSDictionary *triggerData = @{
        @"name": friendlyName,
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

@end
