//
//  Student.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 5/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Student.h"

@implementation Student

@synthesize firstName;
@synthesize lastName;
@synthesize experimenterName;
@synthesize schoolName;
@synthesize currentTimestamp;

-(id)initWithName: (NSString*) school :(NSString*) first :(NSString*) last : (NSString*) experimenter{
    if (self = [super init]) {
        firstName = first;
        lastName = last;
        experimenterName = experimenter;
        schoolName = school;
    }
    
    return self;
}

/*
 * Sets the timestamp so that it can be appended to the end of the current log session file name.
 * For new students who have never logged in before, currentTimestamp will be left nil.
 */
- (void) setCurrentTimestamp:(NSString*)timestamp {
    currentTimestamp = timestamp;
}

@end
