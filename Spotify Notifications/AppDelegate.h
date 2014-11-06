//
//  AppDelegate.h
//  Spotify Notifications
//

@class MASShortcutView;

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusBar;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) IBOutlet NSMenuItem *openPreferences;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMMenu;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMArtist;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMAlbum;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMTrack;
@property (strong, nonatomic) IBOutlet NSPopUpButton *showNotificationsToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *showPlayPauseNotifToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *showOnlyCurrentSongToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *soundToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *iconToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *startupToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *albumArtToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *disabledWhenSpotifyHasFocusToggle;
@property (weak, nonatomic) IBOutlet MASShortcutView *shortcutView;

- (IBAction)showHome:(id)sender;
- (IBAction)showSource:(id)sender;
- (IBAction)showContributors:(id)sender;

- (IBAction)showLastFM:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (IBAction)toggleNotifications:(id)sender;
- (IBAction)togglePlayPauseNotif:(id)sender;
- (IBAction)toggleOnlyCurrentSong:(id)sender;
- (IBAction)toggleSound:(id)sender;
- (IBAction)toggleIcons:(id)sender;
- (IBAction)toggleStartup:(id)sender;
- (IBAction)toggleAlbumArt:(id)sender;
- (IBAction)toggleDisabledWhenSpotifyHasFocus:(id)sender;
@end
