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

-(id)initWithName:(NSString*) first :(NSString*) last {
    if (self = [super init]) {
        firstName = first;
        lastName = last;
    }
    
    return self;
}

@end
