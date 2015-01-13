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
    ---------------------------------------------------------------------------------------
    NotificationSound   playSoundOnNotification     Play a sound before each notification.
    */

    @IBOutlet weak var NotificationSoundButton: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationSoundButton.selectItemAtIndex(fetchPreference("playSoundOnNotification", fallback: 0))
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func PreferenceSet(sender: NSPopUpButton) {
        var identifier : String = sender.identifier
        setPreference(identifier, value: sender.indexOfSelectedItem)
    }

    func setPreference(key: String, value: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(value, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func fetchPreference(key: String, fallback: Int) -> Int {
        if let preference: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(key) {
            return preference as Int
        } else {
            return fallback
        }
    }

}

