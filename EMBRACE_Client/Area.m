//
//  Area.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga on 3/30/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "Area.h"

@implementation Area

@synthesize areaId;
@synthesize aPath;
@synthesize points;

- (id) initWithValues:(NSString*)aId :(UIBezierPath *)path :(NSMutableDictionary *)aPoints {
    if(self = [super init]) {
        areaId = aId;
        aPath = path;
        points = aPoints;
    }
    
    return self;
}

@end
