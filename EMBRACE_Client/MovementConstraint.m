//
//  MovementConstraint.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 9/9/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "MovementConstraint.h"

@implementation MovementConstraint

@synthesize objId;
@synthesize action;
@synthesize originX;
@synthesize originY;
@synthesize height;
@synthesize width;

- (id) initWithValues:(NSString*)objectId :(NSString*)act :(NSString*)x :(NSString*)y :(NSString*)w :(NSString*)h {
    if(self = [super init]) {
        objId = objectId;
        action = act;
        originX = x;
        originY = y;
        width = w;
        height = h;
    }
    
    return self;
}

@end
