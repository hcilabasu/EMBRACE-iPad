//
//  LibraryCellView.m
//  EMBRACE
//
//  Created by Administrator on 10/5/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "LibraryCellView.h"
#import "QuartzCore/CALayer.h"

@implementation LibraryCellView

@synthesize coverImage;
@synthesize coverTitle;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"LibraryCellView" owner:self options:nil];
        
        if ([arrayOfViews count] < 1) {
            return nil;
        }
        
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
            return nil;
        }
        
        self = [arrayOfViews objectAtIndex:0];
        
        CALayer* imageLayer = [coverImage layer];
        [imageLayer setCornerRadius:10];
        [imageLayer setBorderWidth:2];
        [imageLayer setMasksToBounds:YES];
        
        int randomNum = arc4random_uniform(3);
        
        UIImageView* progressIcon;
        float progressIconY = 9.5;
        int progressIconWidth = 45;
        int progressIconHeight = 45;
        
        if (randomNum == 0) {            
            progressIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
        }
        else if (randomNum == 1) {
            progressIconWidth = 33;
            progressIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bookmark"]];
        }
        else if (randomNum == 2) {
            progressIconWidth = 38;
            progressIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lock"]];
        }
        
        int progressIconX = self.frame.size.width - progressIconWidth;
        progressIcon.frame = CGRectMake(progressIconX, progressIconY, progressIconWidth, progressIconHeight);
        [self addSubview:progressIcon];
    }
    
    return self;
}

@end