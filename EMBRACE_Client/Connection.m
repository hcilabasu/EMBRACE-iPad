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

- (BOOL)isEqualToConnection:(Connection *)connection {    
    //Same Connection objects
    if (self == connection) {
        return YES;
    }
    
    //Assume all UNGROUP connections are correct
    if ([self interactionType] == UNGROUP) {
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
    
    //Compare hotspots arrays
    if (![[self hotspots] isEqualToArray:[connection hotspots]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    
    return [self isEqualToConnection:other];
}

- (NSUInteger)hash {
     return [self interactionType] ^ [[self objects] hash] ^ [[self hotspots] hash];
}

@end
