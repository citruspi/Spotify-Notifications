//
//  AppDelegate.m
//  Spotify Notifications
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize statusBar;
@synthesize statusMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(eventOccured:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    self.statusBar.image = [NSImage imageNamed:@"status_bar.tiff"];
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)eventOccured:(NSNotification *)notification{
    
    NSDictionary *information = [notification userInfo];
    
    if ([[information objectForKey: @"Player State"]isEqualToString:@"Playing"]){
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [information objectForKey: @"Name"];
        notification.subtitle = [information objectForKey: @"Album"];
        notification.informativeText = [information objectForKey: @"Artist"];
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
    }
}

- (IBAction)showAbout:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://spotifynotifications.mihirsingh.com"]];
}

@end