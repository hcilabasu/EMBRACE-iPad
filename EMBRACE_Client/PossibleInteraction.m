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

@end