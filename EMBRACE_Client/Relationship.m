//
//  Relationship.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Relationship.h"

@implementation Relationship

@synthesize object1Id;
@synthesize object2Id;
@synthesize action;
@synthesize actionType;

NSSet* actionTypes = nil;

+ (void)initialize {
    //We're currently ignoring ungroup since it's just the inverse of group.
    if(!actionTypes)
        actionTypes = [NSSet setWithObjects:@"group", @"disappear",@"transfer", nil];
}

- (id) initWithValues:(NSString*)obj1Id :(NSString*)can :(NSString*)type :(NSString*) obj2Id {
    if (self = [super init]) {
        object1Id = obj1Id;
        action = can;
        actionType = type;
        object2Id = obj2Id;
    }
    
    return self;
}

@end
