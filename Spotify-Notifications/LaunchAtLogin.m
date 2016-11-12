//
//  LaunchAtLogin.m
//  Spotify-Notifications
//

#import "LaunchAtLogin.h"

@implementation LaunchAtLogin

+ (void)setAppIsLoginItem:(BOOL)value {
    NSString *appPath = NSBundle.mainBundle.bundlePath;
    
    //Reference to the shared file list
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItems) {
        
        //Path to application (e.g. /Applications/test.app)
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
        
        if (value) {
            //Add login item..
            
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
            if (item) CFRelease(item);
            
        } else {
            //Remove login item if it exists..
            
            UInt32 seedValue;
            
            //Retrieve the list of Login Items and cast them to a NSArray so that it will be easier to iterate.
            NSArray  *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
            for (int i=0 ; i < loginItemsArray.count; i++) {
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)loginItemsArray[i];
                //Resolve the item with URL
                if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *)&url, NULL) == noErr) {
                    NSString *urlPath = [(__bridge NSURL *)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame && !value) {
                        LSSharedFileListItemRemove(loginItems, itemRef);
                        break;
                    }
                }
            }
        }
        
        CFRelease(loginItems);
    }
    
    
}

@end
