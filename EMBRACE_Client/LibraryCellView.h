//
//  LibraryCellView.h
//  EMBRACE
//
//  Created by Administrator on 10/5/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Progress.h"

@interface LibraryCellView : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *coverImage;
@property (nonatomic, weak) IBOutlet UILabel *coverTitle;
@property (nonatomic, strong) UIImageView *progressIndicator;
@property (nonatomic, assign) float progressIconY;

- (void) displayIndicator:(Status)status;

@end
