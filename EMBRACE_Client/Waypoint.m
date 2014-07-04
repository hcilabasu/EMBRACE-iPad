//
//  Waypoint.m
//  EMBRACE
//
//  Created by Administrator on 4/11/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Waypoint.h"

@implementation Waypoint

@synthesize waypointId;
@synthesize location;

- (id) initWithValues:(NSString*)wayptId :(CGPoint)loc {
    if (self = [super init]) {
        waypointId = wayptId;
        location = loc;
    }
    
    return self;
}

@end
