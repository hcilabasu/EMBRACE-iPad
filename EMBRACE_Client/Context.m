//
//  LogContext.m
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@implementation Context

@synthesize timestamp;

- (id)init {
    if (self = [super init]) {
        timestamp = [Context generateTimestamp];
    }
    
    return self;
}

+ (NSString *)generateTimestamp {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy'T'hh:mm.ss.SSS"];
    NSString *newTimestamp = [dateFormatter stringFromDate:currentDate];
    
    return newTimestamp;
}

@end
