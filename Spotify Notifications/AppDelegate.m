//
//  AppDelegate.m
//  Spotify Notifications
//

#import "AppDelegate.h"
#import "GBLaunchAtLogin.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"

@implementation AppDelegate

@synthesize statusBar;
@synthesize statusMenu;
@synthesize openPrefences;
@synthesize soundToggle;
@synthesize window;
@synthesize iconToggle;
@synthesize startupToggle;
@synthesize showTracksToggle;
@synthesize shortcutView;

NSString *artist;
NSString *track;
NSString *album;
NSImage *art;
NSString *lastTrackId;

SInt32 OSXversionMajor, OSXversionMinor;

- (void)applicationDidFinishLaunching:(NSNotification *)notification{
    
    lastTrackId = @"";
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(eventOccured:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
    [self setIcon];
    
    NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    self.shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;
    
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = track;
        notification.subtitle = album;
        notification.informativeText = artist;
        
        if(Gestalt(gestaltSystemVersionMajor, &OSXversionMajor) == noErr && Gestalt(gestaltSystemVersionMinor, &OSXversionMinor) == noErr)
        {
            if(OSXversionMajor == 10 && OSXversionMinor >= 9)
            {
                if (art)
                    notification.contentImage = art;
                
            }
        }
        
        if ([self getProperty:@"notificationSound"] == 0){
            notification.soundName = NSUserNotificationDefaultSoundName;
        }
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }];
    
    [soundToggle selectItemAtIndex:[self getProperty:@"notificationSound"]];
    [iconToggle selectItemAtIndex:[self getProperty:@"iconSelection"]];
    [startupToggle selectItemAtIndex:[self getProperty:@"startupSelection"]];
    [showTracksToggle selectItemAtIndex:[self getProperty:@"showTracks"]];
    
    if ([self getProperty:@"startupSelection"] == 0){
        [GBLaunchAtLogin addAppAsLoginItem];
    }
    
    if ([self getProperty:@"startupSelection"] == 1){
        [GBLaunchAtLogin removeAppFromLoginItems];
    }

}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    if (!flag) {
        // This makes it so you can open the preferences by reopning the app
        // This way you can get to the preferences even when the status item is hidden
        [self showPrefences:nil];
    }
    
    return YES;
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
        
        artist = [information objectForKey: @"Artist"];
        album = [information objectForKey: @"Album"];
        track = [information objectForKey: @"Name"];
        
        NSString *trackId = [information objectForKey:@"Track ID"];
        
        if (![lastTrackId isEqualToString:trackId] || [self getProperty:@"showTracks"] == 0) {
            lastTrackId = trackId;
            if (trackId){
                NSString *metaLoc = [NSString stringWithFormat:@"https://embed.spotify.com/oembed/?url=%@",trackId];
                NSURL *metaReq = [NSURL URLWithString:metaLoc];
                NSData *metaD = [NSData dataWithContentsOfURL:metaReq];
                
                if (metaD){
                    NSError *error;
                    NSDictionary *meta = [NSJSONSerialization JSONObjectWithData:metaD options:NSJSONReadingAllowFragments error:&error];
                    NSURL *artReq = [NSURL URLWithString:[meta objectForKey:@"thumbnail_url"]];
                    NSData *artD = [NSData dataWithContentsOfURL:artReq];
                    if (artD)
                        art = [[NSImage alloc] initWithData:artD];
                }
            }
        
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = track;
            notification.subtitle = album;
            notification.informativeText = artist;
            
            if(Gestalt(gestaltSystemVersionMajor, &OSXversionMajor) == noErr && Gestalt(gestaltSystemVersionMinor, &OSXversionMinor) == noErr)
            {
                if(OSXversionMajor == 10 && OSXversionMinor >= 9)
                {
                    if (art)
                        notification.contentImage = art;

                }
            }
            
            if ([self getProperty:@"notificationSound"] == 0){
                notification.soundName = NSUserNotificationDefaultSoundName;
            }

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
        }
    }
}

- (IBAction)toggleSound:(id)sender{
    
    [self saveProperty:@"notificationSound" :(int)[soundToggle indexOfSelectedItem]];
    
}

- (IBAction)toggleShowTracks:(id)sender{
    
    [self saveProperty:@"showTracks" :(int)[showTracksToggle indexOfSelectedItem]];
    
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