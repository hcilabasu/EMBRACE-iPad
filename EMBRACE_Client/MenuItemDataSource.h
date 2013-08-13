//
//  MenuItemDataSource.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/25/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuItemDataSource : NSObject {
    NSString* relationship;
    NSArray* objectIds;
    NSArray* images;
}

@property (nonatomic, strong) NSString* relationship;
@property (nonatomic, strong) NSArray* objectIds;
@property (nonatomic, strong) NSArray* images;

- (id)initWithRelationship:(NSString*)strRelationship;
- (id)initWithRelationshipAndImages:(NSString*)strRelationship :(NSArray*) ids :(NSArray*) imageArray;

@end
