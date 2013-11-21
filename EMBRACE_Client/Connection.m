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

@end
