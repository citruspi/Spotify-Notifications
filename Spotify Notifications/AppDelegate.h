//
//  AppDelegate.h
//  Spotify Notifications
//

#import <Cocoa/Cocoa.h>

@class MASShortcutView, SNXTrack;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate> {
    
    BOOL userNotificationContentImagePropertyAvailable;
    
    SNXTrack *track;
    NSString *previousTrack;
}

//Status Bar
@property (strong, nonatomic) NSStatusItem *statusBar;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (strong, nonatomic) IBOutlet NSMenuItem *openPreferences;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMMenu;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMArtist;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMAlbum;
@property (strong, nonatomic) IBOutlet NSMenuItem *openLastFMTrack;

//Preferences
@property (assign) IBOutlet NSWindow *prefsWindow;

@property (strong, nonatomic) IBOutlet NSButton *albumArtToggle;
@property (strong, nonatomic) IBOutlet NSButton *startupToggle;
@property (weak, nonatomic) IBOutlet MASShortcutView *shortcutView;


- (IBAction)showLastFM:(NSMenuItem*)sender;
- (IBAction)showPreferences:(NSMenuItem*)sender;

- (IBAction)toggleStartup:(NSButton *)sender;

- (IBAction)showHome:(id)sender;
- (IBAction)showSource:(id)sender;
- (IBAction)showContributors:(id)sender;

@end
