//
//  MenuItemDataSource.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/25/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MenuItemImage.h"
#import "PossibleInteraction.h"
#import "Relationship.h"

@interface MenuItemDataSource : NSObject {
    PossibleInteraction *interaction; //Stores the type of interaction, the object ids and the hotspots.
    Relationship* menuRelationship;
    NSArray* images; //List of all MenuItemImage objects that need to be displayed in this particular menu item. This includes all objects listed in the objectIds array as well as any objects grouped with those items that will also be displayed.
    CGRect boundingBox; //Used to specify the size of the entire group of objects to be displayed. Used to calculate new sizes and locations within the menu item for all images.
}

@property (nonatomic, strong) PossibleInteraction* interaction;
@property (nonatomic, strong) NSArray* images;
@property (nonatomic, assign) CGRect boundingBox;
@property (nonatomic, strong) Relationship* menuRelationship;

-(id) initWithPossibleInteractionAndImages:(PossibleInteraction*)possInteraction : (Relationship*) relationship :(NSArray*) imageArray :(CGRect) box;

@end
