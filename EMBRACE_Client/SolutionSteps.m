//
//  SolutionSteps.m
//  EMBRACE
//
//  Created by Rishabh Chaudhry on 2/24/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "SolutionSteps.h"

@implementation SolutionSteps

@synthesize interactionType;
@synthesize stepNum;
@synthesize obj1Id ;
@synthesize action ;
@synthesize obj2Id ;


- (id)initWithValues:(NSString*)type :(NSString*) obj1 :(NSString*) obj2 :(NSString*) act :(NSNumber*)num {
    self = [super init];
    if (self) {
        interactionType = type;
        stepNum = num;
        obj1Id  = obj1;
        obj2Id  = obj2;
        action  = act;
    }
    return self;
}

@end
