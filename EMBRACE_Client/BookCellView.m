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
@synthesize coverImageBackground;

- (id)initWithFrame:(CGRect)frame {
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
        
        CALayer* imageLayer = [coverImage layer];
        [imageLayer setBorderWidth:2];
        [imageLayer setMasksToBounds:YES];
        
        self.progressIndicator = [[UIImageView alloc] init];
        self.progressIconY = 10.5;
    }
    
    return self;
}

@end
