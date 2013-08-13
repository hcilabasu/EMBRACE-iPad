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
@synthesize objectIds;
@synthesize relationship;

- (id)init {
    self = [super init];
    if (self) {
        images = [[NSArray alloc] init];
        objectIds = [[NSArray alloc] init];
    }
    return self;
}

- (id)initWithRelationship:(NSString*)strRelationship {
    self = [super init];
    if (self) {
        images = [[NSArray alloc] init];
        objectIds = [[NSArray alloc] init];
        relationship = strRelationship;
    }
    return self;
}

- (id)initWithRelationshipAndImages:(NSString*)strRelationship :(NSArray*) ids :(NSArray*) imageArray {
    self = [super init];
    if (self) {
        images = imageArray;
        objectIds = ids;
        relationship = strRelationship;
    }
    return self;
}

@end
