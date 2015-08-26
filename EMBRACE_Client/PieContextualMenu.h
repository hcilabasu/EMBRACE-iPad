//
//  ContextualMenuView.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDataSource.h"
#import "ConditionSetup.h"

@protocol PieContextualMenuDelegate;
@protocol PieContextualMenuDataSource;

@interface PieContextualMenu : UIView

@property (nonatomic, strong) id<PieContextualMenuDelegate> delegate;
@property (nonatomic, strong) id<PieContextualMenuDataSource> dataSource;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGFloat radius;

//Constants for the menu
extern float const itemRadiusIM;
extern float const itemRadiusPM;
extern float const menuBoundingBoxIM;
extern float const menuBoundingBoxPM;
extern float const minAngle;
extern int const maxMenuItems;

-(void) expandMenu:(CGFloat) circleRadius;
-(int) pointInMenuItem:(CGPoint) point;

@end
