//
//  ContextualMenuView.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PieContextualMenu.h"
#import "PieContextualMenuItem.h"

@interface PieContextualMenu() {
    CGRect circleBounds;
    float circleRadius;
}

@end

@implementation PieContextualMenu

@synthesize delegate = _delegate;
@synthesize dataSource = dataSource_;
@synthesize center;
@synthesize radius;

float const itemRadius = 100.0; //radius of each menu item.
float const minAngle = 5.0; //minimum angle in degrees.
float const menuBoundingBox = 400.0; // The bounding box of the large for the menu.
int const maxMenuItems = 10; //Total number of items the menu will display. changed to 3 from 6

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:.5]];
        
        float boxSize = [self frame].size.height - (itemRadius * 2) - 50.0;
        float originX = ([self frame].size.width - boxSize) / 2;
        float originY = ([self frame].size.height - boxSize) / 2;
        circleBounds = CGRectMake(originX, originY, boxSize, boxSize);
        circleRadius = boxSize / 2;
    }
    return self;
}

-(void) expandMenu:(CGFloat)circleRadius {
    [self setCenter:CGPointMake(circleBounds.origin.x + (circleBounds.size.width / 2), circleBounds.origin.y + (circleBounds.size.height / 2))];
    [self setRadius:self->circleRadius];
    
    //Get the total number of items in the menu.
    int numItems = [[self dataSource] numberOfMenuItems];

    //Calculate the distance between items.
    float distance = 2 * M_PI / numItems;
    
    //NSLog(@"circle radius: %f and radius: %f", self->circleRadius, radius);
    //NSLog(@"numItems: %d", numItems);
    
    for(int i = 0; i < numItems; i ++) {
        float angle = distance * i;
        CGFloat currX = center.x + radius * cos(angle);
        CGFloat currY = center.y + radius * sin(angle);
        
        //NSLog(@"current X & Y: (%f, %f)", currX, currY);
        CGRect rect = CGRectMake(currX - itemRadius, currY - itemRadius, itemRadius * 2, itemRadius * 2);
        //PieContextualMenuItem *item = [[PieContextualMenuItem alloc] initWithFrame:rect];
        PieContextualMenuItem *item = [[PieContextualMenuItem alloc]
                                       initWithFrameAndData:rect :angle :[[self dataSource] dataObjectAtIndex:i]];
        [self addSubview:item];
    }
}

-(int) pointInMenuItem:(CGPoint) point {
    NSArray* menuItems = [self subviews]; //Get all subviews of the current view
    
    //Check each subview to see if the point is in it.
    //Subviews are returned in order they were added, with the first item added being the first subview.
    for(int i = 0;i < [menuItems count]; i++) {
        UIView *menuItemView = [menuItems objectAtIndex:i];
        CGRect viewFrame = [menuItemView frame];
        
        if((point.x >= viewFrame.origin.x) && (point.x <= viewFrame.origin.x + viewFrame.size.width)
           && (point.y >= viewFrame.origin.y) && (point.y <=viewFrame.origin.y + viewFrame.size.height))
                return i;
    }
    
    //Did not click on any of the menu items. 
    return -1;
}

- (void)drawRect:(CGRect)rect {
    //Draw the circle in the center.
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = [[UIColor alloc] initWithRed:.086 green:.41 blue:.53 alpha:.1];
    CGContextSetStrokeColorWithColor(context, color.CGColor);

    CGContextSetFillColor(context, CGColorGetComponents(color.CGColor));
    
    CGContextAddEllipseInRect(context, circleBounds);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, circleBounds);
    UIGraphicsEndImageContext();
}

@end
