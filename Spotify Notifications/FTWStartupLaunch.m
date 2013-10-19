//
//  SKStartupLaunch.h
//  FTW
//
//  Created by Soroush Khanlou on 7/16/12.
//  Copyright (c) 2012 FTW. All rights reserved.
//

#import "FTWStartupLaunch.h"

@interface FTWStartupLaunch()

+ (LSSharedFileListItemRef)itemRefInLoginItems;

@end

@implementation FTWStartupLaunch


// with code from from http://www.bdunagan.com/2010/09/25/cocoa-tip-enabling-launch-on-startup/
+ (BOOL) willLaunchAtStartup {
	// See if the app is currently in LoginItems.
	LSSharedFileListItemRef itemRef = [FTWStartupLaunch itemRefInLoginItems];
	// Store away that boolean.
	BOOL isInList = (itemRef != nil);
	// Release the reference if it exists.
	if (itemRef != nil) CFRelease(itemRef);
	
	return isInList;
}

+ (void) shouldLaunchAtStartup:(BOOL)shouldLaunchAtStartup {
	// Toggle the state.
	// Get the LoginItems list.
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItemsRef == nil) return;
	if (shouldLaunchAtStartup) {
		// Add the app to the LoginItems list.
		CFURLRef appUrl = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
		LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
		if (itemRef) CFRelease(itemRef);
	} else {
		// Remove the app from the LoginItems list.
		LSSharedFileListItemRef itemRef = [FTWStartupLaunch itemRefInLoginItems];
		LSSharedFileListItemRemove(loginItemsRef,itemRef);
		if (itemRef != nil) CFRelease(itemRef);
	}
	CFRelease(loginItemsRef);
}

+ (LSSharedFileListItemRef)itemRefInLoginItems {
	LSSharedFileListItemRef itemRef = nil;
	NSURL *itemUrl = nil;
	
	// Get the app's URL.
	NSURL *appUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	// Get the LoginItems list.
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItemsRef == nil) return nil;
	// Iterate over the LoginItems.
	NSArray *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
	for (int currentIndex = 0; currentIndex < [loginItems count]; currentIndex++) {
		// Get the current LoginItem and resolve its URL.
		LSSharedFileListItemRef currentItemRef = (LSSharedFileListItemRef)[loginItems objectAtIndex:currentIndex];
		if (LSSharedFileListItemResolve(currentItemRef, 0, (CFURLRef *) &itemUrl, NULL) == noErr) {
			// Compare the URLs for the current LoginItem and the app.
			if ([itemUrl isEqual:appUrl]) {
				// Save the LoginItem reference.
				itemRef = currentItemRef;
			}
		}
	}
	// Retain the LoginItem reference.
	if (itemRef != nil) CFRetain(itemRef);
	// Release the LoginItems lists.
	[loginItems release];
	CFRelease(loginItemsRef);
	
	return itemRef;
}

@end
