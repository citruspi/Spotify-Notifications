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
#import "SNXTrack.h"

@implementation AppDelegate

@synthesize window;
@synthesize statusBar;
@synthesize statusMenu;
@synthesize openPreferences;
@synthesize openLastFMMenu;
@synthesize openLastFMArtist;
@synthesize openLastFMAlbum;
@synthesize openLastFMTrack;

@synthesize showNotificationsToggle;
@synthesize showPlayPauseNotifToggle;
@synthesize showOnlyCurrentSongToggle;
@synthesize soundToggle;
@synthesize iconToggle;
@synthesize startupToggle;
@synthesize albumArtToggle;
@synthesize shortcutView;

BOOL UserNotificationContentImagePropertyAvailable;

SNXTrack *track;

NSString *previousTrack;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    NSInteger major;
    NSInteger minor;
    NSInteger patch;

    major = minor = patch = -1;

    NSString* productVersion = [[NSDictionary dictionaryWithContentsOfFile:
                                @"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];

    NSArray* productVersionSeparated = [productVersion componentsSeparatedByString:@"."];

    if (productVersionSeparated.count >= 1 ) {

        major = [productVersionSeparated[0] integerValue];

        if ( productVersionSeparated.count >= 2 ) {

            minor = [productVersionSeparated[1] integerValue];

            if ( productVersionSeparated.count >= 3 ) {

                patch = [productVersionSeparated[2] integerValue];

            }
        }
    }

    if ((major == 10) &&
        (minor >= 9)) {

        UserNotificationContentImagePropertyAvailable = YES;

    }

    else {

        UserNotificationContentImagePropertyAvailable = NO;

    }

    track = [[SNXTrack alloc] init];

    previousTrack = @"";

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(eventOccured:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [self setIcon];
    [self setupGlobalShortcutForNotifications];

    [showNotificationsToggle selectItemAtIndex:[self getProperty:@"notifications"]];
    [showPlayPauseNotifToggle selectItemAtIndex:[self getProperty:@"playpausenotifs"]];
    [showOnlyCurrentSongToggle selectItemAtIndex:[self getProperty:@"onlycurrentsong"]];
    [soundToggle selectItemAtIndex:[self getProperty:@"notificationSound"]];
    [iconToggle selectItemAtIndex:[self getProperty:@"iconSelection"]];
    [startupToggle selectItemAtIndex:[self getProperty:@"startupSelection"]];
    [albumArtToggle selectItemAtIndex:[self getProperty:@"includeAlbumArt"]];

    if (!(UserNotificationContentImagePropertyAvailable)) {

        albumArtToggle.enabled = NO;
        [albumArtToggle selectItemAtIndex:1];

    }

    if ([self getProperty:@"startupSelection"] == 0) {

        [GBLaunchAtLogin addAppAsLoginItem];

    }

    if ([self getProperty:@"startupSelection"] == 1) {

        [GBLaunchAtLogin removeAppFromLoginItems];

    }

}

- (void)setupGlobalShortcutForNotifications {

    NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    self.shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{

        NSUserNotification *notification = [[NSUserNotification alloc] init];

        if ([track.title length] == 0) {

            notification.title = @"No Song Playing";

            if ([self getProperty:@"notificationSound"] == 0) {

                notification.soundName = NSUserNotificationDefaultSoundName;

            }

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
            if ([self getProperty:@"onlycurrentsong"] == 0) {
                [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
            }
        }

        else {

            notification.title = track.title;
            notification.subtitle = track.album;
            notification.informativeText = track.artist;

            if ((UserNotificationContentImagePropertyAvailable) &&
                ([self getProperty:@"includeAlbumArt"] == 0)) {

                [track fetchAlbumArt];
                notification.contentImage = track.albumArt;

            }

            if ([self getProperty:@"notificationSound"] == 0) {

                notification.soundName = NSUserNotificationDefaultSoundName;

            }

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            track.albumArt = nil;
            
            if ([self getProperty:@"onlycurrentsong"] == 0) {
                NSArray *notifs = [NSUserNotificationCenter defaultUserNotificationCenter].deliveredNotifications;
                for (int i=1; i<[notifs count]; i++) {
                    [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notifs[i]];
                }
            }

        }

    }];

}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {

    if (!flag) {

        // This makes it so you can open the preferences by re-opening the app
        // This way you can get to the preferences even when the status item is hidden
        [self showPreferences:nil];

    }

    return YES;

}

- (IBAction)showHome:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://spotify-notifications.citruspi.io"]];

}

- (IBAction)showSource:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/citruspi/Spotify-Notifications"]];

}

- (IBAction)showContributors:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/citruspi/Spotify-Notifications/graphs/contributors"]];

}

- (IBAction)showPreferences:(id)sender {

    [NSApp activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:nil];

}

- (IBAction)showLastFM:(id)sender {

    //Artist - we always need at least this
    NSString* urlText = [NSString stringWithFormat:@"http://last.fm/music/%@", track.artist];

    if ([sender tag] == 1) {
        //Album
        urlText = [urlText stringByAppendingString:[NSString stringWithFormat:@"/%@", track.album]];
    }
    else if ([sender tag] == 2) {
        //Track
        urlText = [urlText stringByAppendingString:[NSString stringWithFormat:@"/%@/%@", track.album, track.title]];
    }

    urlText = [urlText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: urlText]];

}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
    shouldPresentNotification:(NSUserNotification *)notification {

    return YES;

}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {

    [[NSWorkspace sharedWorkspace] launchApplication:@"Spotify"];

}

- (void)eventOccured:(NSNotification *)notification {

    NSDictionary *information = [notification userInfo];

    NSString *playerState = [information objectForKey: @"Player State"];
    
    if ([playerState isEqualToString:@"Playing"]) {

        track.artist = [information objectForKey: @"Artist"];
        track.album = [information objectForKey: @"Album"];
        track.title = [information objectForKey: @"Name"];
        track.trackID = [information objectForKey:@"Track ID"];

        if (![openLastFMMenu isEnabled] && [track.artist isNotEqualTo:NULL]) {
            [openLastFMMenu setEnabled:YES];
        }

        if ( [self getProperty:@"notifications"] == 0 && (![previousTrack isEqualToString:track.trackID] || [self getProperty:@"playpausenotifs"] == 0) ) {

            previousTrack = track.trackID;
            track.albumArt = nil;

            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = track.title;
            notification.subtitle = track.album;
            notification.informativeText = track.artist;

            if ((UserNotificationContentImagePropertyAvailable) &&
                ([self getProperty:@"includeAlbumArt"] == 0)) {

                [track fetchAlbumArt];
                notification.contentImage = track.albumArt;

            }

            if ([self getProperty:@"notificationSound"] == 0) {

                notification.soundName = NSUserNotificationDefaultSoundName;

            }

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
            if ([self getProperty:@"onlycurrentsong"] == 0) {
                NSArray *notifs = [NSUserNotificationCenter defaultUserNotificationCenter].deliveredNotifications;
                for (int i=1; i<[notifs count]; i++) {
                    [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notifs[i]];
                }
            }

        }
    } else if ([self getProperty:@"onlycurrentsong"] == 0 && [self getProperty:@"playpausenotifs"] == 0 && [playerState isEqualToString:@"Paused"]) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    }

}

- (IBAction)toggleNotifications:(id)sender {

    [self saveProperty:@"notifications" value:(int)[showNotificationsToggle indexOfSelectedItem]];

}

- (IBAction)togglePlayPauseNotif:(id)sender {

    [self saveProperty:@"playpausenotifs" value:(int)[showPlayPauseNotifToggle indexOfSelectedItem]];

}

- (IBAction)toggleOnlyCurrentSong:(id)sender {
    
    [self saveProperty:@"onlycurrentsong" value:(int)[showOnlyCurrentSongToggle indexOfSelectedItem]];
    
}

- (IBAction)toggleSound:(id)sender {

    [self saveProperty:@"notificationSound" value:(int)[soundToggle indexOfSelectedItem]];

}

- (void)setIcon {

    if ([self getProperty:@"iconSelection"] == 0) {

        self.statusBar = nil;
        self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusBar.image = [NSImage imageNamed:@"status_bar_colour.tiff"];
        self.statusBar.menu = self.statusMenu;
        self.statusBar.highlightMode = YES;

    }

    if ([self getProperty:@"iconSelection"] == 1) {

        self.statusBar = nil;
        self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusBar.image = [NSImage imageNamed:@"status_bar_black.tiff"];
        self.statusBar.menu = self.statusMenu;
        self.statusBar.highlightMode = YES;

    }

    if ([self getProperty:@"iconSelection"] == 2) {

        self.statusBar = nil;

    }

}

- (IBAction)toggleIcons:(id)sender {

    [self saveProperty:@"iconSelection" value:(int)[iconToggle indexOfSelectedItem]];
    [self setIcon];

}

- (IBAction)toggleStartup:(id)sender {

    [self saveProperty:@"startupSelection" value:(int)[startupToggle indexOfSelectedItem]];

    if ([self getProperty:@"startupSelection"] == 0) {

        [GBLaunchAtLogin addAppAsLoginItem];

    }

    if ([self getProperty:@"startupSelection"] == 1) {

        [GBLaunchAtLogin removeAppFromLoginItems];

    }

}

- (IBAction)toggleAlbumArt:(id)sender {

    [self saveProperty:@"includeAlbumArt" value:(int)[albumArtToggle indexOfSelectedItem]];

}

- (void)saveProperty:(NSString*)key value:(int)value {

	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

	if (standardUserDefaults) {

		[standardUserDefaults setInteger:value forKey:key];
		[standardUserDefaults synchronize];

	}

}

- (Boolean)getProperty:(NSString*)key {

	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

	int val = 0;

	if (standardUserDefaults) {

        val = (int)[standardUserDefaults integerForKey:key];

    }

	return val;

}

@end
