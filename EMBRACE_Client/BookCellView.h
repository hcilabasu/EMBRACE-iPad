//
//  BookCell.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/11/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibraryCellView.h"

@interface BookCellView : LibraryCellView

@property (nonatomic, weak) IBOutlet UIImageView *coverImage;
@property (nonatomic, weak) IBOutlet UILabel* coverTitle;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageBackground;

@end
