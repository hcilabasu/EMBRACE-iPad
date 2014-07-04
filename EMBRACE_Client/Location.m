//
//  Location.m
//  EMBRACE
//
//  Created by Administrator on 4/11/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Location.h"

@implementation Location

@synthesize locationId;
@synthesize originX;
@synthesize originY;
@synthesize height;
@synthesize width;

- (id) initWithValues:(NSString*)locId :(NSString*)x :(NSString*)y :(NSString*)h :(NSString*)w {
    if(self = [super init]) {
        locationId = locId;
        originX = x;
        originY = y;
        height = h;
        width = w;
    }
    
    return self;
}

@end
