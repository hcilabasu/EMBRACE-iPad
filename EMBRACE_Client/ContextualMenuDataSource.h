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

@interface ContextualMenuDataSource : NSObject <PieContextualMenuDataSource> {
}

-(void) addMenuItem:(PossibleInteraction*)possInteraction :(NSArray*) imageArray :(CGRect) box;
@end
