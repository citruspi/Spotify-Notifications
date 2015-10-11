//
//  AppDelegate.m
//  Spotify Notifications
//

#import "AppDelegate.h"
#import "SharedKeys.h"
#import "GBLaunchAtLogin.h"
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

    static NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    _shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;
    
    [MASShortcutBinder.sharedBinder
     bindShortcutWithDefaultsKey:kPreferenceGlobalShortcut
     toAction:^{
         
         NSUserNotification *notification = [self userNotificationForCurrentTrack];
         
         if (track.title.length == 0) {
             
             notification.title = @"No Song Playing";
             
             if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationSoundKey])
                 notification.soundName = @"Pop";
         }
         
         if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey])
             [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
         
         [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
     }];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // This makes it so you can open the preferences by re-opening the app
    // This way you can get to the preferences even when the status item is hidden
    if (!flag) [self showPreferences:nil];
    return YES;
}

- (IBAction)openSpotify:(NSMenuItem*)sender {
    [NSWorkspace.sharedWorkspace launchApplication:@"Spotify"];
}

- (IBAction)showLastFM:(NSMenuItem*)sender {
    
    //Artist - we always need at least this
    NSMutableString *urlText = [NSMutableString new];
    [urlText appendFormat:@"http://last.fm/music/%@/", track.artist];
    
    if (sender.tag >= 1) [urlText appendFormat:@"%@/", track.album];
    if (sender.tag == 2) [urlText appendFormat:@"%@/", track.title];
    
    NSString *url = [urlText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:url]];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    
    NSUserNotificationActivationType actionType = notification.activationType;
    
    if (actionType == NSUserNotificationActivationTypeContentsClicked) {
        [self openSpotify:nil];
        
    } else if (actionType == NSUserNotificationActivationTypeActionButtonClicked) {
        
        @try {
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell application \"Spotify\" to next track"];
            [script executeAndReturnError:NULL];
        } @catch (NSException *exception) {}
    }
}

- (NSUserNotification*)userNotificationForCurrentTrack {
    NSString *title = track.title;
    NSString *album = track.album;
    NSString *artist = track.artist;
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = (title.length > 0)? title : @"No Song Playing";
    if (album.length > 0) notification.subtitle = album;
    if (artist.length > 0) notification.informativeText = artist;
    
    BOOL includeAlbumArt = (userNotificationContentImagePropertyAvailable &&
                           [NSUserDefaults.standardUserDefaults boolForKey:kNotificationIncludeAlbumArtKey]);
    
    if (includeAlbumArt) {
        [track fetchAlbumArt];
        notification.contentImage = track.albumArt;
    }
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationSoundKey])
        notification.soundName = @"Pop";
    
    notification.hasActionButton = YES;
    notification.actionButtonTitle = @"Skip";
    
    
    //Private APIs – remove if publishing to Mac App Store for example
    @try {
        //Force showing buttons even if "Banner" alert style is chosen by user
        [notification setValue:@YES forKey:@"_showsButtons"];
        
        //Show album art on the left side of the notification (where app icon normally is),
        //like iTunes does
        if (includeAlbumArt && track.albumArt.isValid) {
            [notification setValue:track.albumArt forKey:@"_identityImage"];
            notification.contentImage = nil;
        }
        
    } @catch (NSException *exception) {}
    
    return notification;
}

- (void)eventOccurred:(NSNotification *)notification {
    NSDictionary *information = notification.userInfo;

    NSString *playerState = information[@"Player State"];
    
    if ([playerState isEqualToString:@"Playing"]) {
        
        _openSpotifyMenuItem.title = @"Open Spotify (Playing)";
        
        NSRunningApplication *frontmostApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
        
        if ([frontmostApplication.bundleIdentifier isEqualToString:SpotifyBundleID] &&
            [NSUserDefaults.standardUserDefaults boolForKey:kDisableWhenSpotifyHasFocusKey]) return;

        track.artist = information[@"Artist"];
        track.album = information[@"Album"];
        track.title = information[@"Name"];
        track.trackID = information[@"Track ID"];

        if (!_openLastFMMenu.isEnabled && [track.artist isNotEqualTo:NULL])
            [_openLastFMMenu setEnabled:YES];
        
        if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationsKey] &&
            (![previousTrack isEqualToString:track.trackID] || [NSUserDefaults.standardUserDefaults boolForKey:kPlayPauseNotificationsKey]) ) {

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
        
        _openSpotifyMenuItem.title = @"Open Spotify (Paused)";
        
        [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
    }

}

#pragma mark - Preferences

- (IBAction)showPreferences:(NSMenuItem*)sender {
    [_prefsWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)setIcon {
    
    NSInteger iconSelection = [NSUserDefaults.standardUserDefaults integerForKey:kIconSelectionKey];
    
    if (iconSelection == 0 || iconSelection == 1) {
        
        _statusBar = nil;
        _statusBar = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
        
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
