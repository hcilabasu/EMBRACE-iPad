//
//  PieContextualMenuItem.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PieContextualMenuItem.h"
@implementation PieContextualMenuItem

@synthesize data;

- (id)initWithFrameAndData:(CGRect)frame :(float)angleFromCenter :(MenuItemDataSource*)itemData {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        data = itemData;
        angleFromMenuCenter = angleFromCenter;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Draw outer circle.
    UIColor *color = [[UIColor alloc] initWithRed:.086 green:.41 blue:.53 alpha:1.0];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColor(context, CGColorGetComponents(color.CGColor));
    
    CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, rect);
    
    //Figure out where the position of the innerCircle needs to be based on the angle passed in from the menu.
    CGRect innerCircle = CGRectMake(rect.origin.x + 5, rect.origin.y + 5, rect.size.width - 10, rect.size.height - 10);
    
    //Set location and size information for inner circle so we know where to draw the images.
    float innerCircleRadius = ((rect.size.width - 10)/2);
    CGPoint innerCircleCenter  = CGPointMake(rect.origin.x + 5 + innerCircleRadius, rect.origin.y + 5 + innerCircleRadius);
    
    //Draw inner circle.
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextAddEllipseInRect(context, innerCircle);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, innerCircle);

    if(data != nil) {
        //Pull the images and draw them based on the relationship
        NSArray* images = [data images]; //This is an array of MenuItemImage objects.
        InteractionType type = [[data interaction] interactionType];
        
        //separate
        if(type == UNGROUP) {
            //Calculate the square that fits in the circle.
            //Find the top-left point of the square, which will be at 3/4PI angle from the center of the circle.
            float angle = (5.0 * M_PI) / 4.0; // PI/4 is in quadrant IV and we want 45 angle in quadrant II.
            CGFloat topleftX = innerCircleCenter.x + innerCircleRadius * cos(angle);
            CGFloat topleftY = innerCircleCenter.y + innerCircleRadius * sin(angle);
            float lengthSide = sqrtf(powf((innerCircleRadius * 2), 2) / 2);
            
            //40 pixels is currently what the arrows will take up. 
            float widthImage = (lengthSide - 40) / 2;
    
            //There are only two images.
            //TODO: Delete the following 2 lines after we've verified this new code works.
            //UIImage *image1 = [images objectAtIndex:0];
            //UIImage *image2 = [images objectAtIndex:1];
            UIImage *image1 = [[images objectAtIndex:0] image];
            UIImage *image2 = [[images objectAtIndex:1] image];
            
            //Need to properly figure out what these image resolutions need to be.
            UIImage *image1Scaled = [self scaleImagetoResolution:image1 :widthImage];
            UIImage *image2Scaled = [self scaleImagetoResolution:image2 :widthImage];
            
            UIImageView *imageView1 = [[UIImageView alloc] initWithImage:image1Scaled];
            UIImageView *imageView2 = [[UIImageView alloc] initWithImage:image2Scaled];

            CGRect image1Loc = CGRectMake(topleftX, topleftY + (lengthSide / 2) - (image1Scaled.size.height / 2),
                                          imageView1.frame.size.width, imageView1.frame.size.height);
            CGRect image2Loc = CGRectMake(topleftX + lengthSide - image2Scaled.size.width,
                                          topleftY + (lengthSide / 2) - (image2Scaled.size.height / 2),
                                          imageView2.frame.size.width, imageView2.frame.size.height);
            
            [imageView1 setFrame:image1Loc];
            [imageView2 setFrame:image2Loc];

            //Add the images as subviews
            [self addSubview:imageView1];
            [self addSubview:imageView2];
            
            //TODO: Remove the arrows and draw something more generalizeable based on the information passed in from the PMViewController.
            //Draw arrows indicating that you're separating them.
            CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
            CGContextSetLineWidth(context, 3.0);
            
            //Draw arrow pointing toward right object
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, topleftX + (lengthSide / 2) + 2, topleftY + (lengthSide / 2)); //Beginning of line
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) + 18, topleftY + (lengthSide / 2)); //End of line
            CGContextStrokePath(context);
            
            //Draw right arrow head
            CGContextMoveToPoint(context, topleftX + (lengthSide / 2) + 18, topleftY + (lengthSide / 2)); //Beginning of line
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) + 13, topleftY + (lengthSide / 2) - 5);  // top arrow point
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) + 13, topleftY + (lengthSide / 2) + 5);  // bottom arrow point
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) + 18, topleftY + (lengthSide / 2)); //Back to arrow point
            CGContextClosePath(context);
            CGContextStrokePath(context);            
            CGContextFillPath(context);
            
            //Draw arrow pointing toward left object
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, topleftX + (lengthSide / 2) - 2, topleftY + (lengthSide / 2)); //Beginning of line.
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) - 18, topleftY + (lengthSide / 2)); //End of line.
            CGContextStrokePath(context);

            //Draw left arrow head
            CGContextMoveToPoint(context, topleftX + (lengthSide / 2) - 18, topleftY + (lengthSide / 2)); //Beginning of line
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) - 13, topleftY + (lengthSide / 2) - 5);  // top arrow point
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) - 13, topleftY + (lengthSide / 2) + 5);  // bottom arrow point
            CGContextAddLineToPoint(context, topleftX + (lengthSide / 2) - 18, topleftY + (lengthSide / 2)); //Back to arrow point
            CGContextClosePath(context);
            CGContextStrokePath(context);
            CGContextFillPath(context);

        }
    }
    
    UIGraphicsEndImageContext();
}

// Change image resolution to the desired size while maintaining proportions.
- (UIImage *)scaleImagetoResolution:(UIImage*)image :(int)resolution {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    //if already at the minimum resolution, return the orginal image, otherwise scale
    if (width <= resolution && height <= resolution) {
        return image;
        
    }
    else {
        CGFloat ratio = width/height;
        
        if (ratio > 1) {
            bounds.size.width = resolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = resolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    [image drawInRect:CGRectMake(0.0, 0.0, bounds.size.width, bounds.size.height)];
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

@end
