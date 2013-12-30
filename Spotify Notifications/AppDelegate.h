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
@property (strong, nonatomic) IBOutlet NSMenuItem *openPrefences;
@property (strong, nonatomic) IBOutlet NSPopUpButton *soundToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *iconToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *startupToggle;
@property (strong, nonatomic) IBOutlet NSPopUpButton *showTracksToggle;
@property (weak, nonatomic) IBOutlet MASShortcutView *shortcutView;

- (IBAction)showHome:(id)sender;
- (IBAction)showAuthor:(id)sender;
- (IBAction)showSource:(id)sender;

- (IBAction)toggleIcons:(id)sender;
- (IBAction)toggleSound:(id)sender;
- (IBAction)toggleStartup:(id)sender;
- (IBAction)toggleShowTracks:(id)sender;

@end