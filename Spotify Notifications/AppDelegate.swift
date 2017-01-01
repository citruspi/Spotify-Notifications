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
    

    var previousTrack: SpotifyTrack?
    var currentTrack: SpotifyTrack?
    
    var spotify: SpotifyApplication!

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //Register default preferences values
        let defaultsPath = Bundle.main.path(forResource: "UserDefaults", ofType: "plist")
        let defaults = NSDictionary.init(contentsOfFile: defaultsPath!) as! [String : Any]
        UserDefaults.standard.register(defaults: defaults)
        
        spotify = SBApplication(bundleIdentifier: Constants.SpotifyBundleID) as! SpotifyApplication
        
        NSUserNotificationCenter.default.delegate = self
        
        //Observe Spotify player state changes
        let notificationName = Notification.Name(Constants.SpotifyNotificationName)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(spotifyPlaybackStateChanged(_:)), name: notificationName, object: nil)
        
        setIcon()
        setupGlobalShortcutForNotifications()
        
        LaunchAtLogin.setAppIsLoginItem(UserDefaults.standard.bool(forKey: Constants.LaunchAtLoginKey))
        
        if spotify.running && spotify.playerState == .playing {
            currentTrack = spotify.currentTrack
            
            let notification = userNotificationForCurrentTrack()
            deliverUserNotification(notification, force: true)
            
            if let current = currentTrack {
                updateLastFMMenu(currentTrack: current)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    func setupGlobalShortcutForNotifications() {
        
        shortcutView.associatedUserDefaultsKey = Constants.PreferenceGlobalShortcut;
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Constants.PreferenceGlobalShortcut, toAction: (() -> Void)! {
            
            let notification = self.userNotificationForCurrentTrack()
            if UserDefaults.standard.bool(forKey: Constants.NotificationSoundKey) {
                notification.soundName = "Pop"
            }
            
            self.deliverUserNotification(notification, force: true)
        })
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        //Allow opening preferences by re-opening the app
        //This allows accessing preferences even when the status item is hidden
        if !flag {
            showPreferences(nil)
        }
        
        return true;
    }
    
    @IBAction func openSpotify(_ sender: NSMenuItem) {
        spotify.activate()
    }
    
    @IBAction func showLastFM(_ sender: NSMenuItem) {
        
        if let track = currentTrack {
            //Artist - we always need at least this
            let urlText = NSMutableString(string: "http://last.fm/music/")
            
            if let artist = track.artist?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                urlText.appendFormat("%@/",artist);
            }
            if let album = track.album?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), sender.tag >= 1 {
                urlText.appendFormat("%@/", album)
            }
            
            if let trackName = track.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), sender.tag == 2 {
                urlText.appendFormat("%@/", trackName)
            }
            
            if let url = URL(string: urlText as String) {
                NSWorkspace.shared().open(url)
            }
        }
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
        
        let notification = NSUserNotification()
        notification.title = "No Song Playing"
        
        if let track = currentTrack {
            
            if (track.spotifyUrl?.hasPrefix("spotify:ad"))! || track.name?.characters.count == 0 {
                return notification
            }
            
            notification.title = track.name!;
            notification.subtitle = track.album!
            notification.informativeText = track.artist!
            
            if UserDefaults.standard.bool(forKey: Constants.NotificationIncludeAlbumArtKey) {
                notification.contentImage = albumArtForTrack(track)
            }
            
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
                if (notification.contentImage?.isValid)! {
                    notification.setValue(notification.contentImage, forKey: "_identityImage")
                    notification.contentImage = nil;
                }
                
            } catch {}
        }
        
        return notification
    }
    
    func deliverUserNotification(_ notification: NSUserNotification, force: Bool) {
        let frontmost = NSWorkspace.shared().frontmostApplication?.bundleIdentifier == Constants.SpotifyBundleID
        
        if frontmost && UserDefaults.standard.bool(forKey: Constants.DisableWhenSpotifyHasFocusKey) {
            return
        }
        
        var deliver = force
        
        if let current = currentTrack, !deliver {
            
            var isNewTrack = false
            if let previous = previousTrack {
                isNewTrack = previous.id!() != current.id!()
            }
            
            
            let notificationsEnabled = UserDefaults.standard.bool(forKey: Constants.NotificationsKey)
            
            if isNewTrack || notificationsEnabled {
                //If only showing notification for current song, remove all other notifications..
                if UserDefaults.standard.bool(forKey: Constants.ShowOnlyCurrentSongKey) {
                    NSUserNotificationCenter.default.removeAllDeliveredNotifications()
                }
                
                //..then make sure this one is delivered
                deliver = true;
            }
        }
        
        if spotify.running && deliver {
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    func updateLastFMMenu(currentTrack: SpotifyTrack) {
        if !openLastFMMenu.isEnabled && currentTrack.artist != nil {
            openLastFMMenu.isEnabled = true
        }
    }
    
    func notPlaying() {
        openSpotifyMenuItem.title = "Open Spotify (Not Playing)"
        
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    }
    
    func spotifyPlaybackStateChanged(_ notification: NSNotification) {
        if notification.userInfo?["Player State"] as! String != "Playing" {
            notPlaying()
            return //To stop us from checking accessing spotify (spotify.playerState below)..
            //..and then causing it to re-open
        }
        
        if spotify.playerState == .playing {
            openSpotifyMenuItem.title = "Open Spotify (Playing)"
            
            if let current = currentTrack {
                
                updateLastFMMenu(currentTrack: current)
                
                if let previous = previousTrack, previous.id!() != current.id!() {
                    previousTrack = current
                    currentTrack = spotify.currentTrack
                }
            }
            
            deliverUserNotification(userNotificationForCurrentTrack(), force: false)
        }
    }
    
    //MARK: - Preferences
    
    @IBAction func showPreferences(_ sender: NSMenuItem?) {
        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setIcon() {
        let iconSelection = UserDefaults.standard.integer(forKey: Constants.IconSelectionKey)
        
        if iconSelection == 2 && statusItem != nil {
            statusItem = nil
            
        } else if iconSelection == 0 || iconSelection ==  1{
            let imageName = iconSelection == 0 ? "status_bar_colour" : "status_bar_black"
            if statusItem == nil {
                statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
                statusItem!.menu = statusMenu
                statusItem!.highlightMode = true
            }
            
            if statusItem!.image?.name() != imageName {
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
    
    //MARK: - Preferences Info Buttons
    
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
