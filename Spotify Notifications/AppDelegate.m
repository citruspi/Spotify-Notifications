//
//  AppDelegate.m
//  Spotify Notifications
//

#import "SharedKeys.h"
#import "AppDelegate.h"
#import "GBLaunchAtLogin.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"
#import "SNXTrack.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    userNotificationContentImagePropertyAvailable = (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9);
    track = [SNXTrack new];
    previousTrack = @"";

    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];

    [NSDistributedNotificationCenter.defaultCenter addObserver:self
                                                        selector:@selector(eventOccured:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [self setIcon];
    [self setupGlobalShortcutForNotifications];
    
    [_iconToggle selectItemAtIndex:[self getProperty:kIconSelectionKey]];
    
    if (!userNotificationContentImagePropertyAvailable) _albumArtToggle.enabled = NO;
    
    
    if ([self getProperty:kLaunchAtLoginKey] == 0) {
        [GBLaunchAtLogin addAppAsLoginItem];
        
    } else {
        [GBLaunchAtLogin removeAppFromLoginItems];
    }
}

- (void)setupGlobalShortcutForNotifications {

    NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    _shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{

        NSUserNotification *notification = [NSUserNotification new];

        if (track.title.length == 0) {

            notification.title = @"No Song Playing";

            if ([self getProperty:kNotificationSoundKey] == 0)
                notification.soundName = NSUserNotificationDefaultSoundName;
            
            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
            
            if ([self getProperty:kShowOnlyCurrentSongKey] == 0)
                [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
            
        } else {

            notification.title = track.title;
            notification.subtitle = track.album;
            notification.informativeText = track.artist;

            if (userNotificationContentImagePropertyAvailable &&
                ([self getProperty:kNotificationIncludeAlbumArtKey] == 0)) {

                [track fetchAlbumArt];
                notification.contentImage = track.albumArt;

            }

            if ([self getProperty:kNotificationSoundKey] == 0)
                notification.soundName = NSUserNotificationDefaultSoundName;

            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
            track.albumArt = nil;
            
            if ([self getProperty:kShowOnlyCurrentSongKey] == 0) {
                NSArray *notifs = NSUserNotificationCenter.defaultUserNotificationCenter.deliveredNotifications;
                for (int i=1; i<notifs.count; i++) {
                    [NSUserNotificationCenter.defaultUserNotificationCenter removeDeliveredNotification:notifs[i]];
                }
            }
        }
        
    }];
}

- (IBAction)showLastFM:(id)sender {

    //Artist - we always need at least this
    NSString *urlText = [NSString stringWithFormat:@"http://last.fm/music/%@", track.artist];

    if ([sender tag] == 1) {
        //Album
        urlText = [urlText stringByAppendingString:[NSString stringWithFormat:@"/%@", track.album]];
        
    } else if ([sender tag] == 2) {
        //Track
        urlText = [urlText stringByAppendingString:[NSString stringWithFormat:@"/%@/%@", track.album, track.title]];
    }

    urlText = [urlText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:urlText]];

}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [NSWorkspace.sharedWorkspace launchApplication:@"Spotify"];
}

- (void)eventOccured:(NSNotification *)notification {

    NSDictionary *information = notification.userInfo;

    NSString *playerState = [information objectForKey: @"Player State"];
    
    if ([playerState isEqualToString:@"Playing"]) {
        
        NSRunningApplication *frontmostApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
        
        if ([frontmostApplication.bundleIdentifier isEqualToString:SpotifyBundleID] &&
            [self getProperty:kDisableWhenSpotifyHasFocusKey] == 0) return;

        track.artist = [information objectForKey:@"Artist"];
        track.album = [information objectForKey:@"Album"];
        track.title = [information objectForKey:@"Name"];
        track.trackID = [information objectForKey:@"Track ID"];

        if (!_openLastFMMenu.isEnabled && [track.artist isNotEqualTo:NULL])
            [_openLastFMMenu setEnabled:YES];

        if ([self getProperty:kNotificationsKey] == 0 && (![previousTrack isEqualToString:track.trackID] || [self getProperty:kPlayPauseNotificationsKey] == 0) ) {

            previousTrack = track.trackID;
            track.albumArt = nil;

            NSUserNotification *notification = [NSUserNotification new];
            notification.title = track.title;
            notification.subtitle = track.album;
            notification.informativeText = track.artist;

            if ((userNotificationContentImagePropertyAvailable) &&
                ([self getProperty:kNotificationIncludeAlbumArtKey] == 0)) {

                [track fetchAlbumArt];
                notification.contentImage = track.albumArt;

            }

            if ([self getProperty:kNotificationSoundKey] == 0)
                notification.soundName = NSUserNotificationDefaultSoundName;

            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
            
            if ([self getProperty:kShowOnlyCurrentSongKey] == 0) {
                NSArray *notifs = NSUserNotificationCenter.defaultUserNotificationCenter.deliveredNotifications;
                for (int i=1; i<notifs.count; i++) {
                    [NSUserNotificationCenter.defaultUserNotificationCenter removeDeliveredNotification:notifs[i]];
                }
            }

        }
    } else if ([self getProperty:kShowOnlyCurrentSongKey] == 0 && [self getProperty:kPlayPauseNotificationsKey] == 0 && [playerState isEqualToString:@"Paused"]) {
        [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
    }

}

#pragma mark - Preferences

- (void)saveProperty:(NSString*)key value:(int)value {
    
    NSUserDefaults *standardUserDefaults = NSUserDefaults.standardUserDefaults;
    
    if (standardUserDefaults) {
        [standardUserDefaults setInteger:value forKey:key];
        [standardUserDefaults synchronize];
    }
}

- (BOOL)getProperty:(NSString*)key {
    
    NSUserDefaults *standardUserDefaults = NSUserDefaults.standardUserDefaults;
    
    int val = 0;
    if (standardUserDefaults) val = (int)[standardUserDefaults integerForKey:key];
    
    return val;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    
    // This makes it so you can open the preferences by re-opening the app
    // This way you can get to the preferences even when the status item is hidden
    if (!flag) [self showPreferences:nil];
    
    return YES;
    
}

- (IBAction)showPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_prefsWindow makeKeyAndOrderFront:nil];
}

- (IBAction)toggleNotifications:(NSButton *)sender {
    [self saveProperty:kNotificationsKey value:(int)sender.state];
}

- (IBAction)togglePlayPauseNotif:(NSButton *)sender {
    [self saveProperty:kPlayPauseNotificationsKey value:(int)sender.state];
}

- (IBAction)toggleOnlyCurrentSong:(NSButton *)sender {
    [self saveProperty:kShowOnlyCurrentSongKey value:(int)sender.state];
}

- (IBAction)toggleSound:(NSButton *)sender {
    [self saveProperty:kNotificationSoundKey value:(int)sender.state];
}

- (IBAction)toggleAlbumArt:(NSButton *)sender {
    [self saveProperty:kNotificationIncludeAlbumArtKey value:(int)sender.state];
}

- (IBAction)toggleDisabledWhenSpotifyHasFocus:(NSButton *)sender {
    [self saveProperty:kDisableWhenSpotifyHasFocusKey value:(int)sender.state];
}

- (void)setIcon {
    
    int iconSelection = [self getProperty:kIconSelectionKey];
    
    if (iconSelection == 0 || iconSelection == 1) {
        
        _statusBar = nil;
        _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        
        NSString *imageName = (iconSelection == 0)? @"status_bar_colour.tiff" : @"status_bar_black.tiff";
        _statusBar.image = [NSImage imageNamed: imageName];
        
        _statusBar.menu = _statusMenu;
        _statusBar.image.template = YES;
        _statusBar.highlightMode = YES;
        
    } else if (iconSelection == 2) {
        _statusBar = nil;
    }
}

- (IBAction)toggleIcons:(id)sender {
    [self saveProperty:kIconSelectionKey value:(int)_iconToggle.indexOfSelectedItem];
    [self setIcon];
}

- (IBAction)toggleStartup:(NSButton *)sender {

    [self saveProperty:kLaunchAtLoginKey value:(int)sender.state];

    if ([self getProperty:kLaunchAtLoginKey] == 0) {
        [GBLaunchAtLogin addAppAsLoginItem];
        
    } else {
        [GBLaunchAtLogin removeAppFromLoginItems];
    }

}

#pragma mark - Preferences Info Buttons

- (IBAction)showHome:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"http://spotify-notifications.citruspi.io"]];
}

- (IBAction)showSource:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/citruspi/Spotify-Notifications"]];
}

- (IBAction)showContributors:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/citruspi/Spotify-Notifications/graphs/contributors"]];
    
}

@end
