//
//  ContextualMenuController.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PieContextualMenuDataSource.h"
#import "MenuItemDataSource.h"
#import "Relationship.h"

@interface ContextualMenuDataSource : NSObject <PieContextualMenuDataSource> {
}

//Add a menu item with the following information. 
-(void) addMenuItem:(PossibleInteraction*)possInteraction : (Relationship*) relationship : (NSArray*) imageArray :(CGRect) box;

-(void) clearMenuitems; //Clear all menu items so we can use this again for a new menu.

@end
