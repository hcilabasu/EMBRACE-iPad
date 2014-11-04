//
//  MenuItemDataSource.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/25/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "MenuItemDataSource.h"

@implementation MenuItemDataSource

@synthesize images;
@synthesize interaction;
@synthesize boundingBox;
@synthesize menuRelationship;

- (id)init {
    self = [super init];

    if (self) {
        images = [[NSArray alloc] init];
    }
    
    return self;
}

-(id) initWithPossibleInteractionAndImages:(PossibleInteraction*)possInteraction : (Relationship* ) relationship : (NSArray*) imageArray : (CGRect) box {
    self = [super init];
    
    if (self) {
        interaction = possInteraction;
        images = imageArray;
        boundingBox = box;
        menuRelationship = relationship;
    }
    
    return self;
}

@end
