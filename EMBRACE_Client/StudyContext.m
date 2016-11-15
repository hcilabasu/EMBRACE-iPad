//
//  StudyContext.m
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "StudyContext.h"

@implementation StudyContext

@synthesize appMode;
@synthesize condition;
@synthesize schoolCode;
@synthesize participantCode;
@synthesize studyDay;
@synthesize experimenterName;
@synthesize language;

- (id)init {
    return [super init];
}

- (NSMutableDictionary *)generateTimestamp {
    NSMutableDictionary *newTimestamp = [[NSMutableDictionary alloc] init];
    
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    NSString *date = [dateFormatter stringFromDate:currentDate];
    [newTimestamp setObject:date forKey:@"date"];
    
    [dateFormatter setDateFormat:@"hh:mm:ss"];
    NSString *time = [dateFormatter stringFromDate:currentDate];
    [newTimestamp setObject:time forKey:@"time"];
    
    return newTimestamp;
}

@end
