//
//  AppDelegate.m
//  Spotify Notifications
//

#import "AppDelegate.h"
#import "GBLaunchAtLogin.h"

@implementation AppDelegate

@synthesize statusBar;
@synthesize statusMenu;
@synthesize openPrefences;
@synthesize soundToggle;
@synthesize window;
@synthesize iconToggle;
@synthesize startupToggle;

- (void)applicationDidFinishLaunching:(NSNotification *)notification{
        
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(eventOccured:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
    
    [self setIcon];
    
    [soundToggle selectItemAtIndex:[self getProperty:@"notificationSound"]];
    [iconToggle selectItemAtIndex:[self getProperty:@"iconSelection"]];
    [startupToggle selectItemAtIndex:[self getProperty:@"startupSelection"]];
    
    if ([self getProperty:@"startupSelection"] == 0){
        [GBLaunchAtLogin addAppAsLoginItem];
    }
    
    if ([self getProperty:@"startupSelection"] == 1){
        [GBLaunchAtLogin removeAppFromLoginItems];
    }

}

- (IBAction)showSource:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://github.com/citruspi/Spotify-Notifications"]];
}

- (IBAction)showHome:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://mihirsingh.com/Spotify-Notifications"]];
}

- (IBAction)showAuthor:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://mihirsingh.com"]];
}

- (IBAction)showPrefences:(id)sender{
    [NSApp activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:nil];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
    shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSLog(@"Clicked");
    [[NSWorkspace sharedWorkspace] launchApplication:@"Spotify"];
}

- (void)eventOccured:(NSNotification *)notification{
    
    NSDictionary *information = [notification userInfo];
    
    if ([[information objectForKey: @"Player State"]isEqualToString:@"Playing"]){
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [information objectForKey: @"Name"];
        notification.subtitle = [information objectForKey: @"Album"];
        notification.informativeText = [information objectForKey: @"Artist"];

        if ([self getProperty:@"notificationSound"] == 0){
            notification.soundName = NSUserNotificationDefaultSoundName;
        }

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

    }
}

- (IBAction)toggleSound:(id)sender{
    
    [self saveProperty:@"notificationSound" :(int)[soundToggle indexOfSelectedItem]];
    
}

- (IBAction)toggleStartup:(id)sender{
    
    [self saveProperty:@"startupSelection" :(int)[startupToggle indexOfSelectedItem]];
    
    if ([self getProperty:@"startupSelection"] == 0){
        [GBLaunchAtLogin addAppAsLoginItem];
    }
    
    if ([self getProperty:@"startupSelection"] == 1){
        [GBLaunchAtLogin removeAppFromLoginItems];
    }

}

- (void)setIcon{
    
    if ([self getProperty:@"iconSelection"] == 0){
        self.statusBar = nil;
        self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusBar.image = [NSImage imageNamed:@"status_bar_colour.tiff"];
        self.statusBar.menu = self.statusMenu;
        self.statusBar.highlightMode = YES;
    }
    
    if ([self getProperty:@"iconSelection"] == 1){
        self.statusBar = nil;
        self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusBar.image = [NSImage imageNamed:@"status_bar_black.tiff"];
        self.statusBar.menu = self.statusMenu;
        self.statusBar.highlightMode = YES;
    }
    
    if ([self getProperty:@"iconSelection"] == 2){
        self.statusBar = nil;
     }
}

- (IBAction)toggleIcons:(id)sender{
    
    [self saveProperty:@"iconSelection" :(int)[iconToggle indexOfSelectedItem]];
    [self setIcon];
    
}

- (void)saveProperty:(NSString*)key:(int)value{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
	if (standardUserDefaults) {
		[standardUserDefaults setInteger:value forKey:key];
		[standardUserDefaults synchronize];
	}
}

- (Boolean)getProperty:(NSString*)key{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
    
	if (standardUserDefaults){
		val = (int)[standardUserDefaults integerForKey:key];
    }
    
	return val;
}

@end