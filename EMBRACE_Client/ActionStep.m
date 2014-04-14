//
//  ActionStep.m
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "ActionStep.h"

@implementation ActionStep

@synthesize sentNumber;
@synthesize stepNumber;
@synthesize stepType;
@synthesize object1Id;
@synthesize object2Id;
@synthesize locationId;
@synthesize waypointId;
@synthesize action;

- (id) initAsSetupStep:(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)act {
    if(self = [super init]) {
        stepType = type;
        object1Id = obj1Id;
        object2Id = obj2Id;
        action = act;
    }
    
    return self;
}

- (id) initAsSolutionStep:(NSNumber*)sentNum :(NSNumber*)stepNum :(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)loc :(NSString*)waypt :(NSString*)act {
    if(self = [super init]) {
        sentNumber = sentNum;
        stepNumber = stepNum;
        stepType = type;
        object1Id = obj1Id;
        object2Id = obj2Id;
        locationId = loc;
        waypointId = waypt;
        action = act;
    }
    
    return self;
}

@end