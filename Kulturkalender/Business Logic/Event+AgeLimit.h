//
//  Event+AgeLimit.h
//  Kulturkalender
//
//  Created by Christian Rasmussen on 24.10.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

@interface Event (AgeLimit)

+ (NSString *)stringForAgeLimit:(NSNumber *)ageLimit;

- (NSString *)ageLimitString;

@end
