//
//  SKStartupLaunch.h
//  FTW
//
//  Created by Soroush Khanlou on 7/16/12.
//  Copyright (c) 2012 FTW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTWStartupLaunch : NSObject

+ (BOOL) willLaunchAtStartup;
+ (void) shouldLaunchAtStartup:(BOOL)shouldLaunchAtStartup;

@end
