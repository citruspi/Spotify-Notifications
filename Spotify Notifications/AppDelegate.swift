//
//  AppDelegate.swift
//  Spotify Notifications
//
//  Created by Mihir Singh on 1/7/15.
//  Copyright (c) 2015 citruspi. All rights reserved.
//

import Cocoa
import ScriptingBridge

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    //Menu Bar
    var statusItem: NSStatusItem?
    @IBOutlet var statusMenu: NSMenu!
    
    @IBOutlet var openSpotifyMenuItem: NSMenuItem!
    @IBOutlet var openLastFMMenu: NSMenuItem!
    
    @IBOutlet var aboutPrefsController: AboutPreferencesController!

    var previousTrack: SpotifyTrack?
    var currentTrack: SpotifyTrack?
    
    var spotify: SpotifyApplication!
    
    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession(configuration: config)
        return session
    }()
    
    var albumArtTask: URLSessionDataTask?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //Register default preferences values
        let defaultsPath = Bundle.main.path(forResource: "UserDefaults", ofType: "plist")
        let defaults = NSDictionary.init(contentsOfFile: defaultsPath!) as! [String : Any]
        UserDefaults.standard.register(defaults: defaults)
        
        spotify = SBApplication(bundleIdentifier: Constants.SpotifyBundleID) as! SpotifyApplication
        
        NSUserNotificationCenter.default.delegate = self
        
        //Observe Spotify player state changes
        let notificationName = Notification.Name(Constants.SpotifyNotificationName)
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(spotifyPlaybackStateChanged),
                                                            name: notificationName,
                                                            object: nil)
        
        setIcon()
        
        LaunchAtLogin.setAppIsLoginItem(UserDefaults.standard.bool(forKey: Constants.LaunchAtLoginKey))
        
        if spotify.running {
            let playerState = spotify.playerState
            
            if playerState == .playing || playerState == .paused {
                currentTrack = spotify.currentTrack
                
                if let current = currentTrack {
                    updateLastFMMenu(currentTrack: current)
                }
            }
            
            if playerState == .playing {
                showCurrentTrackNotification(forceDelivery: true)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if albumArtTask != nil {
            albumArtTask?.cancel()
        }
        
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        //Allow opening preferences by re-opening the app
        //This allows accessing preferences even when the status item is hidden
        if !flag {
            aboutPrefsController.showPreferencesWindow(nil)
        }
        
        return true;
    }
    
    //MARK: - Spotify State
    
    func notPlaying() {
        openSpotifyMenuItem.title = "Open Spotify (Not Playing)"
        
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    }
    
    func spotifyPlaybackStateChanged(_ notification: NSNotification) {
        if notification.userInfo?["Player State"] as! String != "Playing" {
            notPlaying()
            return //To stop us from checking accessing spotify (spotify.playerState below)..
            //..and then causing it to re-open
            
        } else if spotify.playerState == .playing {
            openSpotifyMenuItem.title = "Open Spotify (Playing)"
            
            previousTrack = currentTrack
            currentTrack = spotify.currentTrack
            
            //If track has different album art to previous, and album art task ongoing
            if previousTrack != nil && previousTrack!.album! != currentTrack!.album! && albumArtTask != nil {
                albumArtTask?.cancel()
            }
            
            updateLastFMMenu(currentTrack: currentTrack!)
            
            showCurrentTrackNotification(forceDelivery: false)
        }
    }
    
    //MARK: - UI
    func updateLastFMMenu(currentTrack: SpotifyTrack) {
        openLastFMMenu.isEnabled = (currentTrack.artist != nil)
    }
    
    func setIcon() {
        let iconSelection = UserDefaults.standard.integer(forKey: Constants.IconSelectionKey)
        
        if iconSelection == 2 && statusItem != nil {
            statusItem = nil
            
        } else if iconSelection < 2 {
            if statusItem == nil {
                statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
                statusItem!.menu = statusMenu
                statusItem!.highlightMode = true
            }
            
            let imageName = iconSelection == 0 ? "status_bar_colour" : "status_bar_black"
            
            if statusItem!.image?.name() != imageName {
                statusItem!.image = NSImage(named: imageName)
            }
            
            statusItem!.image?.isTemplate = (iconSelection == 1)
        }
    }
    
    @IBAction func openSpotify(_ sender: NSMenuItem) {
        spotify.activate()
    }
    
    @IBAction func openLastFM(_ sender: NSMenuItem) {
        
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
    
    //MARK: - Notifications
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let actionType = notification.activationType
        
        if actionType == .contentsClicked {
            spotify.activate()
            
        } else if actionType == .actionButtonClicked && spotify.playerState == .playing {
            spotify.nextTrack!()
        }
    }
    
    func getAlbumArtForTrack(_ track: SpotifyTrack, completionHandler: @escaping (SpotifyTrack, NSImage?) -> ()) {
        if let url = track.artworkUrl {
            let urlHTTPS = url.replacingOccurrences(of: "http:", with: "https:")
            
            albumArtTask = urlSession.dataTask(with: URL(string: urlHTTPS)!) { data, response, error in
                if data != nil, let image = NSImage.init(data: data!), error == nil {
                    completionHandler(track, image)
                } else {
                    completionHandler(track, nil)
                }
            }
            albumArtTask?.resume()
            
        } else {
            completionHandler(track, nil)
        }
    }
    
    func showCurrentTrackNotification(forceDelivery: Bool) {
        
        let notification = NSUserNotification()
        notification.title = "No Song Playing"
        
        if let track = currentTrack {
            
            if UserDefaults.standard.bool(forKey: Constants.NotificationSoundKey) {
                notification.soundName = "Pop"
            }
            
            if (track.spotifyUrl?.hasPrefix("spotify:ad"))! || track.name?.characters.count == 0 {
                deliverNotification(notification, force: forceDelivery)
                return
            }
            
            notification.title = track.name!
            notification.subtitle = track.album!
            notification.informativeText = track.artist!
            
            notification.hasActionButton = true
            notification.actionButtonTitle = "Skip"
            
            //Private API: Force showing buttons even if "Banner" alert style chosen by user
            notification.setValue(true, forKey: "_showsButtons")
            
            if UserDefaults.standard.bool(forKey: Constants.NotificationIncludeAlbumArtKey) {
                
                getAlbumArtForTrack(track, completionHandler: { (albumArtTrack, image) in
                    
                    //Check album art matches up to current song
                    //(in case of network error/etc)
                    if track.id!() == albumArtTrack.id!() && image != nil {
                        notification.contentImage = image
                        
                        //Private API: Show album art on the left side of the notification
                        //(where app icon normally is) like iTunes does
                        if notification.contentImage?.isValid ?? false {
                            notification.setValue(notification.contentImage, forKey: "_identityImage")
                            notification.contentImage = nil;
                        }
                    }
                    
                    self.deliverNotification(notification, force: forceDelivery)
                })
                
            } else {
                deliverNotification(notification, force: forceDelivery)
            }
        }
        
    }
    
    
    func deliverNotification(_ notification: NSUserNotification, force: Bool) {
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
        
        if deliver {
            NSUserNotificationCenter.default.deliver(notification)
        }
        
        albumArtTask = nil
    }
}
