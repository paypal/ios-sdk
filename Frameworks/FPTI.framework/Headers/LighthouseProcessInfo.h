//
//  LighthouseProcessInfo.h
//  LighthouseAnalytics
//
//  Created by Alden, Miles on 6/13/19.
//  Copyright © 2019 paypal. All rights reserved.
//

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#ifndef LighthouseProcessInfo_h
#define LighthouseProcessInfo_h

/**
 Find out when the process started, in seconds.
 */
CFTimeInterval LighthouseProcessTimeToRelativeTime (void);


typedef struct ProcessTime {
    
    CFTimeInterval processStartTime;
    CFTimeInterval threadTimeSpent;
    CFTimeInterval cpuTimeSpent;
    CFTimeInterval now;
    CFTimeInterval preMainTime;
    
} ProcessTime;

@interface PreMain : NSObject

+ (ProcessTime)processTime;

@end

#endif /* LighthouseProcessInfo_h */

