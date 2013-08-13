//
//  ContextualMenuView.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDataSource.h"

@protocol PieContextualMenuDelegate;
@protocol PieContextualMenuDataSource;

@interface PieContextualMenu : UIView

@property (nonatomic, strong) id<PieContextualMenuDelegate> delegate;
@property (nonatomic, strong) id<PieContextualMenuDataSource> dataSource;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGRect boundingBox;

//Constants for the menu
extern float const itemRadius; 
extern float const minAngle; 

-(void) expandMenu:(CGPoint)location :(CGFloat) circleRadius;
-(int) pointInMenuItem:(CGPoint) point;

@end
