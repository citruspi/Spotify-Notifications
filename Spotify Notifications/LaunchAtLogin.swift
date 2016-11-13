//
//  LaunchAtLogin.swift
//  Spotify Notifications
//
//  Created by Sebastian Jachec on 12/11/2016.
//  Copyright © 2016 citruspi. All rights reserved.
//

import Cocoa

//Based on http://stackoverflow.com/a/27442962/447697

class LaunchAtLogin: NSObject {
    
    class var isAppLoginItem: Bool {
        return itemReferencesInLoginItems.existingReference != nil
    }
    
    private class var itemReferencesInLoginItems: (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
        if let appUrl : NSURL = NSURL.fileURL(withPath: Bundle.main.bundlePath) as NSURL? {
            
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileList?
            
            if loginItemsRef != nil {
                
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                
                if loginItems.count > 0 {
                    let lastItemRef: LSSharedFileListItem = loginItems.lastObject as! LSSharedFileListItem
                    
                    for i in 0 ..< loginItems.count {
                        
                        let currentItemRef: LSSharedFileListItem = loginItems.object(at: i) as! LSSharedFileListItem
                        
                        let currentItemUrlRef: NSURL = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil).takeRetainedValue()
                        
                        if currentItemUrlRef.isEqual(appUrl) {
                            return (currentItemRef, lastItemRef)
                        }
                    }
                    //The application was not found in the startup list
                    return (nil, lastItemRef)
                }
            }
        }
        return (nil, nil)
    }
    
    class func setAppIsLoginItem(_ launch: Bool) {
        
        let itemReferences = itemReferencesInLoginItems
        let isSet = itemReferences.existingReference != nil
        let type = kLSSharedFileListSessionLoginItems.takeUnretainedValue()
        
        if let loginItemsRef = LSSharedFileListCreate(nil, type, nil).takeRetainedValue() as LSSharedFileList? {
            
            if launch && !isSet {
                let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
                LSSharedFileListInsertItemURL(loginItemsRef, itemReferences.lastReference, nil, nil, appUrl, nil, nil)
                
            } else if !launch && isSet, let itemRef = itemReferences.existingReference {
                LSSharedFileListItemRemove(loginItemsRef, itemRef)
            }
        }
    }

}
