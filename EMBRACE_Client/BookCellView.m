//
//  BookCell.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/11/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "BookCellView.h"
#import "QuartzCore/CALayer.h"

@implementation BookCellView

@synthesize coverImage;
@synthesize coverTitle;
@synthesize defaultTitle;
@synthesize defaultAuthor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"BookCellView" owner:self options:nil];
        
        if ([arrayOfViews count] < 1) {
            return nil;
        }
        
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
            return nil;
        }
        
        self = [arrayOfViews objectAtIndex:0];
       
        coverImage.layer.shadowColor = [UIColor blackColor].CGColor;
        coverImage.layer.shadowOffset = CGSizeMake(2, 2);
        coverImage.layer.shadowOpacity = 0.75;
        coverImage.layer.shadowRadius = 5;
        coverImage.clipsToBounds = NO;
        
        coverTitle.textAlignment = NSTextAlignmentCenter;
    }
    
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
