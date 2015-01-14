//
//  ViewController.swift
//  Spotify Notifications
//
//  Created by Mihir Singh on 1/7/15.
//  Copyright (c) 2015 citruspi. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    /*
    Button              Preferency Key              Purpose
    -----------------------------------------------------------------------------------------
    notificationSound   playSoundOnNotification     Play a sound before each notification.
    embedAlbumArtwork   embedAlbumArtwork           Embed the album artwork in notifications.
    spotifyHasFocus     disableWhenSpotifyHasFocus  Disable notifications when the Spotify
                                                    has focus
    launchOnLogin       n/a                         Automatically launch the application on
                                                    login
    
    */

    @IBOutlet weak var notificationSoundButton: NSPopUpButton!
    @IBOutlet weak var embedAlbumArtworkButton: NSPopUpButton!
    @IBOutlet weak var spotifyHasFocusButton: NSPopUpButton!
    @IBOutlet weak var launchOnLoginButton: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        notificationSoundButton.selectItemAtIndex(fetchPreference("playSoundOnNotification"))
        embedAlbumArtworkButton.selectItemAtIndex(fetchPreference("embedAlbumArtwork"))
        spotifyHasFocusButton.selectItemAtIndex(fetchPreference("disableWhenSpotifyHasFocus"))
        
        if NSBundle.mainBundle().isLoginItemEnabled() {
            launchOnLoginButton.selectItemAtIndex(0)
        } else {
            launchOnLoginButton.selectItemAtIndex(1)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func PreferenceSet(sender: NSPopUpButton) {
        var identifier : String = sender.identifier
        
        if identifier == "launchOnLogin" {
            if sender.indexOfSelectedItem == 0 {
                NSBundle.mainBundle().enableLoginItem()
            } else {
                NSBundle.mainBundle().disableLoginItem()
            }
        } else {
            setPreference(identifier, value: sender.indexOfSelectedItem)
        }
    }

    func setPreference(key: String, value: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(value, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func fetchPreference(key: String, fallback: Int = 0) -> Int {
        if let preference: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(key) {
            return preference as Int
        } else {
            return fallback
        }
    }

}

