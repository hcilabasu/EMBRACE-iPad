//
//  Hotspot.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Hotspot.h"

@implementation Hotspot

@synthesize objectId;
@synthesize role;
@synthesize action;
@synthesize location;

- (id) initWithValues:(NSString*)objId :(CGPoint)loc {
    if (self = [super init]) {
        objectId = objId;
        location = loc;
    }
    
    return self;
}

- (id) initWithValues:(NSString*)objId :(NSString*)act :(NSString*)objRole :(CGPoint)loc {
    if (self = [super init]) {
        objectId = objId;
        location = loc;
        role = objRole;
        action = act;
    }
    
    return self;
}

@end
