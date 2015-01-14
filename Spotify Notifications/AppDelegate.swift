//
//  AppDelegate.swift
//  Spotify Notifications
//
//  Created by Mihir Singh on 1/7/15.
//  Copyright (c) 2015 citruspi. All rights reserved.
//

import Cocoa
import Foundation
import Alamofire

struct Track {
    var title: String? = nil
    var artist: String? = nil
    var album: String? = nil
    var artwork: NSImage? = nil
    var id: String? = nil
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var track = Track()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "playbackStateChanged:", name: "com.spotify.client.PlaybackStateChanged", object: nil)
    }
    
    func playbackStateChanged(aNotification: NSNotification) {
        let information : [NSObject : AnyObject] = aNotification.userInfo!
        let playbackState : String = information["Player State"] as NSString
        
        if playbackState == "Playing" {
            track.title = information["Name"] as NSString
            track.artist = information["Artist"] as NSString
            track.album = information["Album"] as NSString
            track.id = information["Track ID"] as NSString

            if fetchPreference("embedAlbumArtwork") == 0 {
                let apiUri = "https://embed.spotify.com/oembed/?url=" + track.id!
            
                Alamofire.request(.GET, apiUri, parameters: nil)
                    .responseJSON { (req, res, json, error) in
                        if(error != nil) {
                            NSLog("Error: \(error)")
                        }
                        else {
                            var json = JSON(json!)
                        
                            let artworkLocation: NSURL = NSURL(string: json["thumbnail_url"].stringValue)!
                        
                            let artwork = NSImage(contentsOfURL: artworkLocation)
                            self.track.artwork = artwork
                        }
                }
            }

            var frontmostApplication : NSRunningApplication? = NSWorkspace.sharedWorkspace().frontmostApplication

            if frontmostApplication != nil {
                if frontmostApplication?.bundleIdentifier == "com.spotify.client" {
                    if fetchPreference("disableWhenSpotifyHasFocus") == 1 {
                        presentNotification()
                    }
                } else {
                    presentNotification()
                }
            }
        }
    }

    func presentNotification() {
        var notification:NSUserNotification = NSUserNotification()
        
        notification.title = track.title
        notification.subtitle = track.album
        notification.informativeText = track.artist
        
        if track.artwork != nil {
            notification.contentImage = track.artwork
        }
        
        if (self.fetchPreference("playSoundOnNotification") == 0) {
            notification.soundName = NSUserNotificationDefaultSoundName
        }

        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    func fetchPreference(key: String, fallback: Int = 0) -> Int {
        if let preference: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(key) {
            return preference as Int
        } else {
            return fallback
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}