//
//  AppDelegate.m
//  Spotify Notifications
//

#import <ScriptingBridge/ScriptingBridge.h>
#import "Spotify.h"
#import "AppDelegate.h"
#import "SharedKeys.h"
#import "GBLaunchAtLogin.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    //Register default preferences values
    [NSUserDefaults.standardUserDefaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"UserDefaults" ofType:@"plist"]]];
    
    spotify =  [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];

    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];
    
    //Observe Spotify player state changes
    [NSDistributedNotificationCenter.defaultCenter addObserver:self
                                                        selector:@selector(spotifyPlayerStateChanged:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [self setIcon];
    [self setupGlobalShortcutForNotifications];
    
    //User notification content images on 10.9+
    userNotificationContentImagePropertyAvailable = (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9);
    if (!userNotificationContentImagePropertyAvailable) _albumArtToggle.enabled = NO;
    
    //Add/remove login item as necessary
    if ([NSUserDefaults.standardUserDefaults boolForKey:kLaunchAtLoginKey]) {
        [GBLaunchAtLogin addAppAsLoginItem];
        
    } else {
        [GBLaunchAtLogin removeAppFromLoginItems];
    }
    
    //Check in case user opened application but Spotify already playing
    if (spotify.playerState == SpotifyEPlSPlaying) {
        currentTrack = spotify.currentTrack;
        
        NSUserNotification *notification = [self userNotificationForCurrentTrack];
        [self deliverUserNotification:notification Force:YES];
    }
}

- (void)setupGlobalShortcutForNotifications {

    static NSString *const kPreferenceGlobalShortcut = @"ShowCurrentTrack";
    _shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;
    
    [MASShortcutBinder.sharedBinder
     bindShortcutWithDefaultsKey:kPreferenceGlobalShortcut
     toAction:^{
         
         NSUserNotification *notification = [self userNotificationForCurrentTrack];
         
         if (currentTrack.name.length == 0) {
             
             notification.title = @"No Song Playing";
             
             if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationSoundKey])
                 notification.soundName = @"Pop";
         }
         
         [self deliverUserNotification:notification Force:YES];
     }];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // This makes it so you can open the preferences by re-opening the app
    // This way you can get to the preferences even when the status item is hidden
    if (!flag) [self showPreferences:nil];
    return YES;
}

- (IBAction)openSpotify:(NSMenuItem*)sender {
    [spotify activate];
}

- (IBAction)showLastFM:(NSMenuItem*)sender {
    
    //Artist - we always need at least this
    NSMutableString *urlText = [NSMutableString new];
    [urlText appendFormat:@"http://last.fm/music/%@/", currentTrack.artist];
    
    if (sender.tag >= 1) [urlText appendFormat:@"%@/", currentTrack.album];
    if (sender.tag == 2) [urlText appendFormat:@"%@/", currentTrack.name];
    
    NSString *url = [urlText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:url]];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    
    NSUserNotificationActivationType actionType = notification.activationType;
    
    if (actionType == NSUserNotificationActivationTypeContentsClicked) {
        [spotify activate];
        
    } else if (actionType == NSUserNotificationActivationTypeActionButtonClicked) {
        [spotify nextTrack];
    }
}

- (NSImage*)albumArtForTrack:(SpotifyTrack*)track {
    if (track.id) {
        // Accessing embed.spotify.com over HTTPS appears to cause an error with App Transport Security.
        // It logs an (kCFStreamErrorDomainSSL, -9802) error which appears to deal with Perfect Forward
        // Secrecy. We need to enable NSAllowsArbitraryLoads for NSAppTransportSecurity. I attempted to use
        // NSTemporaryExceptionRequiresForwardSecrecy but it continued to cause an error.
        // Because of the error connecting to the Spotify server, without enabling NSAllowsArbitraryLoads
        // users lack artwork.
        NSString *metaLoc = [NSString stringWithFormat:@"https://embed.spotify.com/oembed/?url=%@",track.id];
        NSURL *metaReq = [NSURL URLWithString:metaLoc];
        NSData *metaD = [NSData dataWithContentsOfURL:metaReq];
        
        if (metaD) {
            NSError *error;
            NSDictionary *meta = [NSJSONSerialization JSONObjectWithData:metaD options:NSJSONReadingAllowFragments error:&error];
            NSURL *artReq = [NSURL URLWithString:meta[@"thumbnail_url"]];
            NSData *artD = [NSData dataWithContentsOfURL:artReq];
            
            if (artD) return [[NSImage alloc] initWithData:artD];
        }
    }
    return nil;
}

- (NSUserNotification*)userNotificationForCurrentTrack {
    NSString *title = spotify.currentTrack.name;
    NSString *album = spotify.currentTrack.album;
    NSString *artist = spotify.currentTrack.artist;
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = (title.length > 0)? title : @"No Song Playing";
    if (album.length > 0) notification.subtitle = album;
    if (artist.length > 0) notification.informativeText = artist;
    
    BOOL includeAlbumArt = (userNotificationContentImagePropertyAvailable &&
                           [NSUserDefaults.standardUserDefaults boolForKey:kNotificationIncludeAlbumArtKey]);
    
    if (includeAlbumArt) notification.contentImage = [self albumArtForTrack:currentTrack];
    
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
        if (includeAlbumArt && notification.contentImage.isValid) {
            [notification setValue:notification.contentImage forKey:@"_identityImage"];
            notification.contentImage = nil;
        }
        
    } @catch (NSException *exception) {}
    
    return notification;
}

- (void)deliverUserNotification:(NSUserNotification*)notification Force:(BOOL)force {
    if (spotify.frontmost
        && [NSUserDefaults.standardUserDefaults boolForKey:kDisableWhenSpotifyHasFocusKey]) return;
    
    BOOL deliver = force;
    
    //If notifications enabled, and current track isn't the same as the previous track
    if ([NSUserDefaults.standardUserDefaults boolForKey:kNotificationsKey] &&
        (![previousTrack.id isEqualToString:currentTrack.id] || [NSUserDefaults.standardUserDefaults boolForKey:kPlayPauseNotificationsKey])) {
        
        //If only showing notification for current song, remove all other notifications..
        if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey])
            [NSUserNotificationCenter.defaultUserNotificationCenter removeAllDeliveredNotifications];
        
        //..then deliver this one
        deliver = YES;
    }
    
    if (deliver) [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
}

- (void)spotifyPlayerStateChanged:(NSNotification *)notification {
    
    if (spotify.playerState == SpotifyEPlSPlaying) {
        
        _openSpotifyMenuItem.title = @"Open Spotify (Playing)";

        if (!_openLastFMMenu.isEnabled && [currentTrack.artist isNotEqualTo:NULL])
            [_openLastFMMenu setEnabled:YES];
        
        NSUserNotification *userNotification = [self userNotificationForCurrentTrack];
        [self deliverUserNotification:userNotification Force:NO];
        
        previousTrack = currentTrack;
        currentTrack = spotify.currentTrack;
        
    } else if ([NSUserDefaults.standardUserDefaults boolForKey:kShowOnlyCurrentSongKey]
               && [NSUserDefaults.standardUserDefaults boolForKey:kPlayPauseNotificationsKey]
               && (spotify.playerState == SpotifyEPlSPaused || spotify.playerState == SpotifyEPlSStopped)) {
        
        _openSpotifyMenuItem.title = @"Open Spotify (Not Playing)";
        
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
