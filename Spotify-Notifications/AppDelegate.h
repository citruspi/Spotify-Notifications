//
//  AppDelegate.h
//  Spotify Notifications
//

#import <Cocoa/Cocoa.h>
#import <MASShortcut/Shortcut.h>

@class SpotifyApplication, SpotifyTrack;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate> {
    
    BOOL userNotificationContentImagePropertyAvailable;
    
    SpotifyApplication *spotify;
    
    SpotifyTrack *currentTrack;
    SpotifyTrack *previousTrack;
}

//Status Bar
@property (strong, nonatomic) NSStatusItem *statusBar;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (strong, nonatomic) IBOutlet NSMenuItem *openSpotifyMenuItem;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMMenu;
@property (strong, nonatomic) IBOutlet NSMenuItem *openPreferences;

//Preferences
@property (assign) IBOutlet NSWindow *prefsWindow;

@property (strong, nonatomic) IBOutlet NSButton *albumArtToggle;
@property (strong, nonatomic) IBOutlet NSButton *startupToggle;
@property (weak, nonatomic)   IBOutlet MASShortcutView *shortcutView;

- (IBAction)openSpotify:(NSMenuItem*)sender;
- (IBAction)showLastFM:(NSMenuItem*)sender;
- (IBAction)showPreferences:(NSMenuItem*)sender;

- (IBAction)toggleStartup:(NSButton *)sender;

- (IBAction)showHome:(id)sender;
- (IBAction)showSource:(id)sender;
- (IBAction)showContributors:(id)sender;

@end
