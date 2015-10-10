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
    
    [NSUserDefaults.standardUserDefaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"UserDefaults" ofType:@"plist"]]];
    
    userNotificationContentImagePropertyAvailable = (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9);
    track = [SNXTrack new];
    previousTrack = @"";

    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];

    [NSDistributedNotificationCenter.defaultCenter addObserver:self
                                                        selector:@selector(eventOccurred:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [self setIcon];
    [self setupGlobalShortcutForNotifications];
    
    if (!userNotificationContentImagePropertyAvailable) _albumArtToggle.enabled = NO;
    
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:kLaunchAtLoginKey]) {
        [GBLaunchAtLogin addAppAsLoginItem];
        
    } else {
        [GBLaunchAtLogin removeAppFromLoginItems];
    }
}

- (void)setupGlobalShortcutForNotifications {

    NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    _shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{

        NSUserNotification *notification = [self userNotificationForCurrentTrack];

        if (track.title.length == 0) {

            notification.title = @"No Song Playing";

            if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationSoundKey])
                notification.soundName = @"Pop";
            
            if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey])
                [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
            
        } else {
            
            if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey])
                [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
            
            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
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
    
    NSUserNotificationActivationType actionType = notification.activationType;
    
    if (actionType == NSUserNotificationActivationTypeContentsClicked) {
        [NSWorkspace.sharedWorkspace launchApplication:@"Spotify"];
        
    } else if (actionType == NSUserNotificationActivationTypeActionButtonClicked) {
        
        @try {
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell application \"Spotify\" to next track"];
            [script executeAndReturnError:NULL];
        } @catch (NSException *exception) {
            //Oh well
        }
    }
}

- (NSUserNotification*)userNotificationForCurrentTrack {
    NSString *title = track.title;
    NSString *album = track.album;
    NSString *artist = track.artist;
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = (title > 0)? title : @"No Song Playing";
    if (album.length > 0) notification.subtitle = album;
    if (album.length > 0) notification.informativeText = artist;
    
    if (userNotificationContentImagePropertyAvailable &&
        [NSUserDefaults.standardUserDefaults boolForKey:kNotificationIncludeAlbumArtKey]) {
        
        [track fetchAlbumArt];
        notification.contentImage = track.albumArt;
    }
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationSoundKey])
        notification.soundName = @"Pop";
    
    [notification setHasActionButton:YES];
    [notification setActionButtonTitle:@"Skip Song"];
    
    //Hacky solution to force showing buttons even if "Banner" alert style is chosen by user
    @try {
        [notification setValue:@YES forKey:@"_showsButtons"];
    } @catch (NSException *exception) {
        //Oh well
    }
    
    return notification;
}

- (void)eventOccurred:(NSNotification *)notification {
    NSDictionary *information = notification.userInfo;

    NSString *playerState = [information objectForKey: @"Player State"];
    
    if ([playerState isEqualToString:@"Playing"]) {
        
        NSRunningApplication *frontmostApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
        
        if ([frontmostApplication.bundleIdentifier isEqualToString:SpotifyBundleID] &&
            [NSUserDefaults.standardUserDefaults boolForKey:kDisableWhenSpotifyHasFocusKey]) return;

        track.artist = [information objectForKey:@"Artist"];
        track.album = [information objectForKey:@"Album"];
        track.title = [information objectForKey:@"Name"];
        track.trackID = [information objectForKey:@"Track ID"];

        if (!_openLastFMMenu.isEnabled && [track.artist isNotEqualTo:NULL])
            [_openLastFMMenu setEnabled:YES];

        if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationsKey] && (![previousTrack isEqualToString:track.trackID] || [NSUserDefaults.standardUserDefaults boolForKey:kPlayPauseNotificationsKey]) ) {

            previousTrack = track.trackID;
            track.albumArt = nil;
            
            NSUserNotification *notification = [self userNotificationForCurrentTrack];
            
            if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey])
                [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
            
            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];

        }
        
    } else if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey] &&
               [NSUserDefaults.standardUserDefaults boolForKey:kPlayPauseNotificationsKey] &&
               [playerState isEqualToString:@"Paused"]) {
        [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
    }

}

#pragma mark - Preferences

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

- (void)setIcon {
    
    NSInteger iconSelection = [NSUserDefaults.standardUserDefaults integerForKey:kIconSelectionKey];
    
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
    [self setIcon];
}

- (IBAction)toggleStartup:(NSButton *)sender {
    
    [NSUserDefaults.standardUserDefaults setBool:sender.state forKey:kLaunchAtLoginKey];

    if ([NSUserDefaults.standardUserDefaults boolForKey:kLaunchAtLoginKey]) {
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
