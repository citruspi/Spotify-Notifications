//
//  AppDelegate.swift
//  Spotify Notifications
//
//  Created by Mihir Singh on 1/7/15.
//  Copyright (c) 2015 citruspi. All rights reserved.
//

import Cocoa
import Foundation

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
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}