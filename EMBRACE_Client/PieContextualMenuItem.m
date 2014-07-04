//
//  PieContextualMenuItem.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PieContextualMenuItem.h"

/* 
 * Private class used to paint an X over an image in instances in which we're showing an object that's disappearing.
 */
@interface XView : UIView {

}
@end

@implementation XView
    
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
    
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, CGColorCreateCopyWithAlpha([UIColor blackColor].CGColor, .5));
    CGContextSetLineWidth(context, 5.0);
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, 0, 0); //Move to top left corner of image.
    //Draw line to bottom right corner of image.
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    
    //Move to top right corner of image.
    CGContextMoveToPoint(context, rect.size.width, 0);
    //Draw line to bottom left corner of image.
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextStrokePath(context);
}

@end

@implementation PieContextualMenuItem

@synthesize data;

- (id)initWithFrameAndData:(CGRect)frame :(float)angleFromCenter :(MenuItemDataSource*)itemData {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        data = itemData;
        angleFromMenuCenter = angleFromCenter;

        //NSLog(@"initialized menu item with interaction type: %d between objects: %@", [[itemData interaction] interactionType], [[[itemData interaction] objects] componentsJoinedByString:@","]);

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
        
        //Calculate the square that fits in the circle.
        //Find the top-left point of the square, which will be at 3/4PI angle from the center of the circle.
        float angle = (5.0 * M_PI) / 4.0; // PI/4 is in quadrant IV and we want 45 angle in quadrant II.
        CGFloat topleftX = innerCircleCenter.x + innerCircleRadius * cos(angle);
        CGFloat topleftY = innerCircleCenter.y + innerCircleRadius * sin(angle);
        float lengthSide = sqrtf(powf((innerCircleRadius * 2), 2) / 2);
        
        //Ungrouping two items. For the moment, just go ahead and leave the code that shows the 2 items at opposite ends of the circle with arrows pointing away from the center. TODO: We may want to remove the arrows and not check what the type of interaction we have and just go ahead and display all of them the same way.
        if(type == UNGROUP) {
            //40 pixels is currently what the arrows will take up. 
            float widthImage = (lengthSide - 50) / 2;
    
            //There are only two images.
            UIImage *image1 = [[images objectAtIndex:0] image];
            UIImage *image2 = [[images objectAtIndex:1] image];
            
            //Need to properly figure out what these image resolutions need to be.
            UIImage *image1Scaled = [self scaleImagetoResolution:image1 :widthImage :SCALE_EITHER];
            UIImage *image2Scaled = [self scaleImagetoResolution:image2 :widthImage :SCALE_EITHER];

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
        else {
            //Figure out where the images should be and how they should be scaled, then add all images to the subview.
            //Get the bounding box information because this will determine how much we need to scale each individual image.
            //Use lengthside to determine the scaling factor. Keep in mind that the bounding box may not be square, so the largest side needs to be determnined.
            CGRect boundingBoxScene = [data boundingBox];
            
            float scaleFactor = 0;
            BOOL scaleWidth = FALSE;
            
            if(boundingBoxScene.size.width > boundingBoxScene.size.height) {
                scaleFactor = lengthSide / boundingBoxScene.size.width;
                scaleWidth = TRUE;
            }
            else
                scaleFactor = lengthSide / boundingBoxScene.size.height;
            
            NSArray* sortedImages = [self sortMenuItemImagesByZPosition:images];
            
            for(MenuItemImage *itemImage in sortedImages) {
                UIImage *image = [itemImage image];
                
                UIImage *imageScaled;
                
                if(scaleWidth) {
                    //Calculate the size of this image based on the width of the image in the larger scene and the scale factor.
                    float widthImage = itemImage.boundingBoxImage.size.width * scaleFactor;
                    imageScaled = [self scaleImagetoResolution:image :widthImage :SCALE_WIDTH]; //Create the scaled image.
                }
                else {
                    //Calculate the size of this image based on the height of the image in the larger scene and the scale factor.
                    float heightImage = itemImage.boundingBoxImage.size.height * scaleFactor;
                    imageScaled = [self scaleImagetoResolution:image :heightImage :SCALE_HEIGHT];
                }
                
                UIImageView *imageView = [[UIImageView alloc] initWithImage:imageScaled]; //Create the image view.
                
                //Calculate the location of the image within the menu item view. Use the bounding box information as well as the position information stored in the MenuItemImage object.
                CGPoint position = [itemImage boundingBoxImage].origin;
                
                //Calculate the top left corner location so that the scene is centered.
                CGFloat topLeftXCentered = topleftX + ((lengthSide - boundingBoxScene.size.width * scaleFactor) / 2.0);
                CGFloat topLeftYCentered = topleftY + ((lengthSide - boundingBoxScene.size.height * scaleFactor) / 2.0);
                
                CGFloat imageTopLeftX = topLeftXCentered + ((position.x - boundingBoxScene.origin.x) * scaleFactor);
                CGFloat imageTopLeftY = topLeftYCentered + ((position.y - boundingBoxScene.origin.y) * scaleFactor);
                
                CGRect imageLoc = CGRectMake(imageTopLeftX, imageTopLeftY,
                                             imageView.frame.size.width, imageView.frame.size.height);
                
                [imageView setFrame:imageLoc]; //Set the location of the image.
                [self addSubview:imageView]; //Add the image as a subview.
                
                //If this is an object that should be disappearing, go ahead and draw an X over it.
                //That means this image corresponds to the first image in the unsorted array.
                //TODO: Fix this based on the current changes.
                //if((itemImage == [images objectAtIndex:0]) && ((type == DISAPPEAR) || (type == TRANSFERANDDISAPPEAR))) {
                //If this is an object that should be disappearing, go ahead and draw an X over it.
                //That means this image corresponds to the last image in the sorted array
                if((itemImage == [sortedImages lastObject]) && ((type == DISAPPEAR) || (type == TRANSFERANDDISAPPEAR))) {
                    //Create the view that paints the X over the top of the image.
                    XView *xView = [[XView alloc] initWithFrame:CGRectMake(imageTopLeftX, imageTopLeftY, imageView.frame.size.width, imageView.frame.size.height)];
                    [self addSubview:xView];
                }
            }
        }
    }
    
    UIGraphicsEndImageContext();
}

typedef enum ScaleDimension {
    SCALE_WIDTH,
    SCALE_HEIGHT,
    SCALE_EITHER,
} ScaleDimension;


/*
 * Change image resolution to the desired size while maintaining proportions.
 * If dim is SCALE_WIDTH, scale based on width. If dim is SCALE_HEIGHT scale based on height.
 * If dim is SCALE_EITHER, scale based on ratio that will result in largest image for resolution.
 */
- (UIImage *)scaleImagetoResolution:(UIImage*)image :(float)resolution :(ScaleDimension)dim {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    //if already at the minimum resolution, return the orginal image, otherwise scale
    if(dim == SCALE_WIDTH && width <= resolution)
        return image;
    else if(dim == SCALE_HEIGHT && height <= resolution)
        return image;
    else if (dim == SCALE_EITHER && width <= resolution && height <= resolution)
        return image;
    else {
        CGFloat ratio = width/height;
        
        if ((dim == SCALE_EITHER && ratio > 1) || dim == SCALE_WIDTH) {
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

/*
 * Returns an array with the menu item images sorted by z-position in ascending order
 */
-(NSArray*) sortMenuItemImagesByZPosition:(NSArray*) unsortedImages {
    NSSortDescriptor *sortDescriptor;   
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"zPosition"
                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [unsortedImages sortedArrayUsingDescriptors:sortDescriptors];
    
    return sortedArray;
}

@end
