//
//  StudyContext.m
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "StudyContext.h"


@interface StudyContext()

@property (nonatomic,strong) NSDateFormatter *dateFormatter;
@property (nonatomic,strong) NSDateFormatter *timeFormatter;

@end

@implementation StudyContext

- (id)init {
    
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM-dd-yyyy"];
        
        self.timeFormatter = [[NSDateFormatter alloc] init];
        [self.timeFormatter setDateFormat:@"hh:mm:ss"];
    }
    
    return self;
}

- (NSMutableDictionary *)generateTimestamp {
    NSMutableDictionary *newTimestamp = [[NSMutableDictionary alloc] init];
    
    NSDate *currentDate = [NSDate date];
    NSString *date = [self.dateFormatter stringFromDate:currentDate];
    [newTimestamp setObject:date forKey:@"date"];
    
    [self.timeFormatter setDateFormat:@"hh:mm:ss"];
    NSString *time = [self.timeFormatter stringFromDate:currentDate];
    [newTimestamp setObject:time forKey:@"time"];
    
    return newTimestamp;
}

@end
