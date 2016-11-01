//
//  Student.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 5/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Student.h"

@implementation Student

@synthesize schoolCode;
@synthesize participantCode;
@synthesize studyDay;
@synthesize experimenterName;
@synthesize currentTimestamp;

- (id)initWithValues:(NSString *)school :(NSString *)participant :(NSString *)study :(NSString *)experimenter {
    if (self = [super init]) {
        schoolCode = [school lowercaseString];
        participantCode = [participant lowercaseString];
        studyDay = study;
        experimenterName = [experimenter lowercaseString];
    }
    
    return self;
}

/*
 * Sets the timestamp so that it can be appended to the end of the current log session file name.
 * For new students who have never logged in before, currentTimestamp will be left nil.
 */
- (void)setCurrentTimestamp:(NSString *)timestamp {
    currentTimestamp = timestamp;
}

@end
