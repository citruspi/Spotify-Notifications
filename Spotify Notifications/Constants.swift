//
//  Constants.swift
//  Spotify Notifications
//
//  Created by Sebastian Jachec on 12/11/2016.
//  Copyright © 2016 citruspi. All rights reserved.
//

import Foundation

struct Constants {
    static let PreferenceGlobalShortcut = "ShowCurrentTrack"
    
    static let SpotifyBundleID = "com.spotify.client"
    static let SpotifyNotificationName = "com.spotify.client.PlaybackStateChanged"
    
    static let NotificationsKey = "notifications"
    static let PlayPauseNotificationsKey = "playpausenotifs"
    static let ShowOnlyCurrentSongKey = "onlycurrentsong"
    static let NotificationSoundKey = "notificationSound"
    static let NotificationIncludeAlbumArtKey = "includeAlbumArt"
    static let DisableWhenSpotifyHasFocusKey = "disableWhenSpotifyHasFocus"
    
    static let LaunchAtLoginKey = "startupSelection"
    static let IconSelectionKey = "iconSelection"
}
