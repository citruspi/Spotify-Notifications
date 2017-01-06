//
//  AboutPreferencesController.swift
//  Spotify Notifications
//
//  Created by Sebastian Jachec on 02/01/2017.
//  Copyright © 2017 citruspi. All rights reserved.
//

import Cocoa
import MASShortcut

class AboutPreferencesController : NSObject {
    
    @IBOutlet var appDelegate: AppDelegate!
    
    @IBOutlet var aboutWindow: NSWindow!
    
    @IBOutlet var preferencesWindow: NSWindow!
    @IBOutlet var shortcutView: MASShortcutView!
    
    override func awakeFromNib() {
        setupPreferencesWindow()
        setupAboutWindow()
    }
    
    //MARK: - Preferences
    private func setupPreferencesWindow() {
        shortcutView.associatedUserDefaultsKey = Constants.PreferenceGlobalShortcut;
        shortcutView.style = .texturedRect
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Constants.PreferenceGlobalShortcut, toAction: (() -> Void)! {
            self.appDelegate.showCurrentTrackNotification(forceDelivery: true)
        })
    }
    
    @IBAction func showPreferencesWindow(_ sender: AnyObject?) {
        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func toggleIcons(_ sender: AnyObject) {
        appDelegate.updateStatusIcon()
    }
    
    @IBAction func toggleStartup(_ sender: NSButton) {
        let launchAtLogin = (sender.state == 1)
        UserDefaults.standard.set(launchAtLogin, forKey: Constants.LaunchAtLoginKey)
        LaunchAtLogin.setAppIsLoginItem(launchAtLogin)
    }
    
    //MARK: - About
    private func setupAboutWindow() {
        aboutWindow.backgroundColor = NSColor.white
        aboutWindow.titlebarAppearsTransparent = true
        aboutWindow.titleVisibility = .hidden
        aboutWindow.styleMask.insert(.fullSizeContentView)
    }
    
    @IBAction func showAboutWindow(_ sender: AnyObject) {
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func openWebsite(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://spotify-notifications.citruspi.io")!)
    }
}
