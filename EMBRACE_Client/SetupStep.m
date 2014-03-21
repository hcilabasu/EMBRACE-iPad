//
//  SetupStep.m
//  EMBRACE
//
//  Created by Administrator on 3/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "SetupStep.h"

@implementation SetupStep

@synthesize stepType;
@synthesize object1Id;
@synthesize object2Id;
@synthesize action;

- (id) initWithValues:(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)act {
    if(self = [super init]) {
        stepType = type;
        object1Id = obj1Id;
        object2Id = obj2Id;
        action = act;
    }
    
    return self;
}

@end
