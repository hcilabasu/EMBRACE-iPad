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
@synthesize boundingBox; //may not need this eventually.

float const itemRadius = 100.0; //radius of each menu item.
float const minAngle = 5.0; //minimum angle in degrees.

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

//TODO: Come back to this. For the moment, we'll just copy the interaction objects to the center of the screen and redisplay them. 
-(void) expandMenu:(CGPoint)location :(CGFloat)circleRadius {
    [self setCenter:CGPointMake(circleBounds.origin.x + (circleBounds.size.width / 2), circleBounds.origin.y + (circleBounds.size.height / 2))]; //temporary.
    [self setRadius:self->circleRadius]; //temporary

    /*
    //[self setCenter:CGPointMake(boundingBox.size.width / 2, boundingBox.size.height / 2)];
    //[self setRadius:circleRadius];

    //Calculate the minimum distance on the circle that two menu items can be based on the minAngle(between items) and
    //the itemRadius.
    //Calculating the angle of each item from center to edge using: angle = 2 * asin(chord length / 2r)
    float itemAngle = 2 * (asinf(itemRadius / (2 * radius)));
    
    //total angle then is the minAngle + 2 * itemAngle.
    float totalAngle = minAngle + (2 * itemAngle);
    float minAngleRadians = totalAngle * M_PI / 180.0;*/
    
    //Get the total number of items in the menu.
    int numItems = [[self dataSource] numberOfMenuItems];
    
    //Figure out where the menu needs to be placed, and how much of the circle I have available to me.
    /*float startingRadians;
    float endingRadians;
    
    //add the item radius to the circle radius to ensure that the full item is displayed.
    float circleAndItemRadius = radius + itemRadius;
    
    //if the edge of this expanded circle is over the width of the parent frame, then we'll increase the angle until we hit the edge.
    if(center.x + circleAndItemRadius > [self frame].size.width) {
            //Figure out at what x,y the x + radius is less than the parent frame width.
        
            //Check to make sure that the y location is not < 0, thereby moving off the frame at the top.
            //If it does, keep increasing the angle until y > 0 and x + radius < parent frame width.
        
            //At some point, we may have to check to make sure we haven't gone off the frame in the other direction for the x-axis. 
    }
    //otherwise, we'll decrease the angle from 2PI to find the starting point.
    else {
        
    }
    
    //if minimum distance for all items is larger than the space available expand the frame to make the menu larger.
    */
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
    //Leave space in the frame to draw the menu items.
    //CGRect circleBounds = CGRectMake(boundingBox.origin.x + itemRadius, boundingBox.origin.y + itemRadius, boundingBox.size.width - (itemRadius * 2), boundingBox.size.height - (itemRadius * 2));
    //Draw circle around items to be grouped or ungrouped.
    
    //For now, draw the circle in the center.
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
