//
//  ContextualMenuController.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
@interface ContextualMenuDataSource () {
    
}

@property (nonatomic, strong) NSMutableArray* data;

@end

@implementation ContextualMenuDataSource

@synthesize data;

- (id)init {
    self = [super init];
    if (self) {
        data = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - PieContextualMenuDataSource
- (int)numberOfMenuItems {
    return [data count];
}

- (id)dataObjectAtIndex:(NSInteger)itemIndex {
    return [data objectAtIndex:itemIndex];
}

-(void) addMenuItem:(PossibleInteraction*)possInteraction :(NSArray*) imageArray :(CGRect) box {
    MenuItemDataSource* currentMenuItem = [[MenuItemDataSource alloc] initWithPossibleInteractionAndImages:possInteraction :imageArray :box];
    [data addObject:currentMenuItem];
}

-(void) clearMenuitems {
    [data removeAllObjects];
}

@end
