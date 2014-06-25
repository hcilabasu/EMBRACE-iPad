//
//  Connection.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 11/21/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Connection.h"

@implementation Connection

@synthesize interactionType;
@synthesize objects;
@synthesize hotspots;

- (id)initWithValues:(InteractionType)type :(NSArray*) objs :(NSArray*) hotspts {
    self = [super init];
    if (self) {
        interactionType = type;
        objects = objs;
        hotspots = hotspts;
    }
    return self;
}

/*
 * Checks for equality against another Connection object by comparing interaction types, objects, and hotspots
 */
- (BOOL)isEqualToConnection:(Connection *)connection {    
    //Same Connection objects
    if (self == connection) {
        return YES;
    }
    
    //Compare interaction types
    if ([self interactionType] != [connection interactionType]) {
        return NO;
    }
    
    //Compare objects arrays
    if (![[self objects] isEqualToArray:[connection objects]]) {
        return NO;
    }
    
    //Compare hotspots arrays. Assume the hotspots are correct for ungroup interactions because a Connection object from the solution does not include hotspots for ungroup steps
    if ([self interactionType] != UNGROUP && ![[self hotspots] isEqualToArray:[connection hotspots]]) {
        return NO;
    }
    
    return YES;
}

/*
 * Checks for equality against another object by performing a series of checks, ending with one that is
 * specific to the Connection class
 */
- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    
    return [self isEqualToConnection:other];
}

/* 
 * Generates the same hash value (an integer) for two objects if isEqual determines that the two objects are equal. 
 * This method must be implemented if isEqual is overridden.
 */
- (NSUInteger)hash {
     return [self interactionType] ^ [[self objects] hash] ^ [[self hotspots] hash];
}

@end
