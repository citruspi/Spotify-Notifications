//
//  AppDelegate.swift
//  Spotify Notifications
//
//  Created by Mihir Singh on 1/7/15.
//  Copyright (c) 2015 citruspi. All rights reserved.
//

import Cocoa
import ScriptingBridge
import MASShortcut


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    //Menu Bar
    var statusItem: NSStatusItem?
    @IBOutlet var statusMenu: NSMenu!
    
    @IBOutlet var openSpotifyMenuItem: NSMenuItem!
    @IBOutlet var openLastFMMenu: NSMenuItem!
    @IBOutlet var openPreferences: NSMenuItem!
    
    //Preferences
    @IBOutlet var preferencesWindow: NSWindow!
    
    @IBOutlet var albumArtToggle: NSButton!
    @IBOutlet var startupToggle: NSButton!
    @IBOutlet var shortcutView: MASShortcutView!
    

    var previousTrack: SpotifyTrack!
    var currentTrack: SpotifyTrack!
    
    var spotify: SpotifyApplication!

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //Register default preferences values
        UserDefaults.standard.register(defaults: NSDictionary.init(contentsOfFile: Bundle.main.path(forResource: "UserDefaults", ofType: "plist")!) as! [String : Any])
        
        let spotify = SBApplication(bundleIdentifier: Constants.SpotifyBundleID) as! SpotifyApplication
        
        NSUserNotificationCenter.default.delegate = self
        
        //Observe Spotify player state changes
        let notificationName = Notification.Name(Constants.SpotifyNotificationName)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(spotifyPlaybackStateChanged(_:)), name: notificationName, object: nil)
        
        setIcon()
        setupGlobalShortcutForNotifications()
        
        LaunchAtLogin.setAppIsLoginItem(UserDefaults.standard.bool(forKey: Constants.LaunchAtLoginKey))
        
        if (spotify.running && spotify.playerState == .playing) {
            currentTrack = spotify.currentTrack
            
            let notification = userNotificationForCurrentTrack()
            deliverUserNotification(notification, force: true)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    func setupGlobalShortcutForNotifications() {
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Constants.PreferenceGlobalShortcut, toAction: (() -> Void)! {
            
            let notification = self.userNotificationForCurrentTrack()
            if (self.currentTrack.name?.characters.count == 0) {
                notification.title = "No Song Playing"
                
                if (UserDefaults.standard.bool(forKey: Constants.NotificationSoundKey)) {
                    notification.soundName = "Pop"
                }
            }
            
            self.deliverUserNotification(notification, force: true)
        })
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Allow opening preferences by re-opening the app
        // This allows accessing preferences even when the status item is hidden
        if (!flag) {
            showPreferences(nil)
        }
        
        return true;
    }
    
    @IBAction func openSpotify(_ sender: NSMenuItem) {
        spotify.activate()
    }
    
    @IBAction func showLastFM(_ sender: NSMenuItem) {
        
        //Artist - we always need at least this
        let urlText = NSMutableString()
        urlText.appendFormat("http://last.fm/music/%@/", currentTrack.artist!)
        
        if (sender.tag >= 1) {
            urlText.appendFormat("%@/", currentTrack.album!)
        }
        if (sender.tag == 2) {
            urlText.appendFormat("%@/", currentTrack.name!)
        }
        
        let url = urlText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        NSWorkspace.shared().open(URL(string: url)!)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let actionType = notification.activationType
        
        if (actionType == .contentsClicked) {
            spotify.activate()
            
        } else if (actionType == .actionButtonClicked && spotify.playerState == .playing) {
            spotify.nextTrack!()
        }
    }
    
    func albumArtForTrack(_ track: SpotifyTrack) -> NSImage? {
        //Looks hacky, but appears to work
        if let artworkUrl = track.artworkUrl {
            let artworkUrlHTTPS = artworkUrl.replacingOccurrences(of: "http:", with: "https:")
            
            do {
                let artData = try Data.init(contentsOf: URL(string: artworkUrlHTTPS)!)
                return NSImage.init(data: artData)
            } catch { }
        }
        
        return nil
    }
    
    func userNotificationForCurrentTrack() -> NSUserNotification {
        let isAdvert = (currentTrack.spotifyUrl?.hasPrefix("spotify:ad"))!
        
        let notification = NSUserNotification()
        
        if isAdvert {
            notification.title = "No Song Playing"
            return notification
            
        } else {
            notification.title = currentTrack.name!;
            notification.subtitle = currentTrack.album!
            notification.informativeText = currentTrack.artist!
            
            let includeAlbumArt = UserDefaults.standard.bool(forKey: Constants.NotificationIncludeAlbumArtKey) && !isAdvert
            
            if includeAlbumArt {
                notification.contentImage = albumArtForTrack(currentTrack)
            }
            
            if !isAdvert {
                if UserDefaults.standard.bool(forKey: Constants.NotificationSoundKey) {
                    notification.soundName = "Pop"
                }
                
                notification.hasActionButton = true
                notification.actionButtonTitle = "Skip"
                
                //Private APIs – remove if publishing to Mac App Store
                do {
                    //Force showing buttons even if "Banner" alert style is chosen by user
                    notification.setValue(true, forKey: "_showsButtons")
                    
                    //Show album art on the left side of the notification (where app icon normally is),
                    //like iTunes does
                    if (includeAlbumArt && (notification.contentImage?.isValid)!) {
                        notification.setValue(notification.contentImage, forKey: "_identityImage")
                        notification.contentImage = nil;
                    }
                    
                } catch {}
            }
        }
        
        return notification
    }
    
    func deliverUserNotification(_ notification: NSUserNotification, force: Bool) {
        let frontmost = NSWorkspace.shared().frontmostApplication?.bundleIdentifier == Constants.SpotifyBundleID
        
        if frontmost && UserDefaults.standard.bool(forKey: Constants.DisableWhenSpotifyHasFocusKey) {
            return
        }
        
        var deliver = force
        
        //If notifications enabled, and current track isn't the same as the previous track
        if (UserDefaults.standard.bool(forKey: Constants.NotificationsKey) &&
            !((previousTrack.id!() == currentTrack.id!()) || UserDefaults.standard.bool(forKey: Constants.PlayPauseNotificationsKey))) {
            
            //If only showing notification for current song, remove all other notifications..
            if UserDefaults.standard.bool(forKey: Constants.ShowOnlyCurrentSongKey) {
                NSUserNotificationCenter.default.removeAllDeliveredNotifications()
            }
            
            //..then deliver this one
            deliver = true;
        }
        
        if (spotify.running && deliver) {
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    func notPlaying() {
        openSpotifyMenuItem.title = "Open Spotify (Not Playing)"
        
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    }
    
    func spotifyPlaybackStateChanged(_ notification: NSNotification) {
        
        if notification.userInfo?["Player State"] as! String == "Stopped" {
            notPlaying()
            return //To stop us from checking accessing spotify (spotify.playerState below)..
            //..and then causing it to re-open
        }
        
        if (spotify.playerState == .playing) {
            openSpotifyMenuItem.title = "Open Spotify (Playing)"
            
            if (!openLastFMMenu.isEnabled && currentTrack.artist != nil) {
                openLastFMMenu.isEnabled = true
            }
            
            if !(previousTrack.id!() == currentTrack.id!()) {
                previousTrack = currentTrack
                currentTrack = spotify.currentTrack
            }
            
            deliverUserNotification(userNotificationForCurrentTrack(), force: false)
        }
    }
    
    // MARK: - Preferences
    
    @IBAction func showPreferences(_ sender: NSMenuItem?) {
        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setIcon() {
        let iconSelection = UserDefaults.standard.integer(forKey: Constants.IconSelectionKey)
        
        if iconSelection == 2 && statusItem != nil {
            statusItem = nil
            
        } else if iconSelection == 0 || iconSelection ==  1{
            let imageName = iconSelection == 0 ? "status_bar_colour.tiff" : "status_bar_black.tiff"
            if statusItem == nil {
                statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
                statusItem!.menu = statusMenu
                statusItem!.highlightMode = true
            }
            
            if !(statusItem!.image?.name() == imageName) {
                statusItem!.image = NSImage(named: imageName)
            }
            
            statusItem!.image?.isTemplate = (iconSelection == 1)
        }
    }
    
    @IBAction func toggleIcons(_ sender: AnyObject) {
        setIcon()
    }
    
    @IBAction func toggleStartup(_ sender: NSButton) {
        let launchAtLogin = (sender.state == 1)
        UserDefaults.standard.set(launchAtLogin, forKey: Constants.LaunchAtLoginKey)
        LaunchAtLogin.setAppIsLoginItem(launchAtLogin)
    }
    
    // MARK: - Preferences Info Buttons
    
    @IBAction func showHome(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "http://spotify-notifications.citruspi.io")!)
    }
    
    @IBAction func showSource(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://github.com/citruspi/Spotify-Notifications")!)
    }
    
    @IBAction func showContributors(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://github.com/citruspi/Spotify-Notifications/graphs/contributors")!)
    }

}
