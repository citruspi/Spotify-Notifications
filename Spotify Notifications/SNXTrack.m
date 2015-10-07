//
//  Track.m
//  Spotify Notifications
//
//  Created by Mihir Singh on 12/30/13.
//  Copyright (c) 2013 Mihir Singh. All rights reserved.
//

#import "SNXTrack.h"

@implementation SNXTrack

@synthesize title = _track;
@synthesize artist = _artist;
@synthesize album = _album;
@synthesize albumArt = _albumArt;
@synthesize trackID = _trackID;

- (void)fetchAlbumArt {

    if (_trackID) {
        
        // Accessing embed.spotify.com over HTTPS appears to cause an error with App Transport Security.
        // It logs an (kCFStreamErrorDomainSSL, -9802) error which appears to deal with Perfect Forward
        // Secrecy. We need to enable NSAllowsArbitraryLoads for NSAppTransportSecurity. I attempted to use
        // NSTemporaryExceptionRequiresForwardSecrecy but it continued to cause an error.
        // Because of the error connecting to the Spotify server, without enabling NSAllowsArbitraryLoads
        // users lack artwork.
        NSString *metaLoc = [NSString stringWithFormat:@"https://embed.spotify.com/oembed/?url=%@",_trackID];
        NSURL *metaReq = [NSURL URLWithString:metaLoc];
        NSData *metaD = [NSData dataWithContentsOfURL:metaReq];
        
        if (metaD) {
            
            NSError *error;
            NSDictionary *meta = [NSJSONSerialization JSONObjectWithData:metaD options:NSJSONReadingAllowFragments error:&error];
            NSURL *artReq = [NSURL URLWithString:[meta objectForKey:@"thumbnail_url"]];
            NSData *artD = [NSData dataWithContentsOfURL:artReq];
            
            if (artD) {
                
                _albumArt = [[NSImage alloc] initWithData:artD];
                
            }
        }
    }
    
}

@end
