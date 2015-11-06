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
@synthesize progressIndicator;
@synthesize progressIconY;

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
        
        progressIndicator = [[UIImageView alloc] init];
        progressIconY = 14.5;
    }
    
    return self;
}

/*
 * Displays progress indicator (i.e., checkmark, bookmark, lock) for the
 * corresponding chapter status
 */
- (void) displayIndicator:(ChapterStatus)status {
    int progressIconWidth = 45;
    int progressIconHeight = 45;
    
    if (status == COMPLETED) {
        [progressIndicator setImage:[UIImage imageNamed:@"checkmark"]];
    }
    else if (status == IN_PROGRESS) {
        progressIconWidth = 33;
        [progressIndicator setImage:[UIImage imageNamed:@"bookmark"]];
    }
    else if (status == INCOMPLETE) {
        progressIconWidth = 38;
        [progressIndicator setImage:[UIImage imageNamed:@"lock"]];
    }
    
    int progressIconX = self.coverImage.frame.size.width - progressIconWidth / 1.75;
    CGRect frame = CGRectMake(progressIconX, self.progressIconY, progressIconWidth, progressIconHeight);
    [progressIndicator setFrame:frame];
    [self addSubview:progressIndicator];
}

@end