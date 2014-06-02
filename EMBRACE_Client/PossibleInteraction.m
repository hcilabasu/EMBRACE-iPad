//
//  PossibleInteraction.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 10/24/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PossibleInteraction.h"

@implementation PossibleInteraction

@synthesize connections;
@synthesize interactionType;

-(id) init {
    self = [super init];
    if (self) {
        connections = [[NSMutableArray alloc] init];
    }
    return self;

}

-(id) initWithInteractionType:(InteractionType)type {
    self = [super init];
    if (self) {
        connections = [[NSMutableArray alloc] init];
        interactionType = type;
    }
    return self;
    
}

- (void)addConnection:(InteractionType)type :(NSArray*) objs :(NSArray*) hotspts {
    Connection *connection = [[Connection alloc] initWithValues:type :objs :hotspts];
    [connections addObject:connection];
}

- (BOOL)isEqualToPossibleInteraction:(PossibleInteraction *)interaction {
    //Same PossbleInteraction objects
    if (self == interaction) {
        return YES;
    }
    
    //Compare interaction types
    if ([self interactionType] != [interaction interactionType]) {
        return NO;
    }
    
    //Compare connections arrays
    if (![[self connections] isEqual:[interaction connections]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    
    return [self isEqualToPossibleInteraction:other];
}

- (NSUInteger)hash {
    NSUInteger hash = [self interactionType];
    
    for (Connection* connection in [self connections]) {
        hash = hash ^ [connection hash];
    }
    
    return hash;
}

@end