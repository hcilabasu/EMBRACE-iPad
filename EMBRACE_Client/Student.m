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

-(id)initWithName:(NSString*) first :(NSString*) last : (NSString*) experimenter{
    if (self = [super init]) {
        firstName = first;
        lastName = last;
        experimenterName = experimenter;
    }
    
    return self;
}

@end
