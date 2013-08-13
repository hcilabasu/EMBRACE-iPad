//
//  Relationship.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Relationship.h"

@implementation Relationship

@synthesize object1Id;
@synthesize object2Id;
@synthesize action;

- (id) initWithValues:(NSString*)obj1Id :(NSString*)can :(NSString*) obj2Id {
    if (self = [super init]) {
        object1Id = obj1Id;
        action = can;
        object2Id = obj2Id;
    }
    
    return self;
}
@end
