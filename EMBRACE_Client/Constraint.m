//
//  Constraint.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Constraint.h"

@implementation Constraint

@synthesize action1;
@synthesize action2;
@synthesize ruleType;

- (id) initWithValues:(NSString*)act1 :(NSString*)act2 :(NSString*) type {
    if(self = [super init]) {
        action1 = act1;
        action2 = act2;
        ruleType = type;
    }
    
    return self;
}

@end
