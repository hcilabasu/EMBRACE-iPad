//
//  BookCell.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/11/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookCellView : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImage;
@property (nonatomic, strong) IBOutlet UILabel* coverTitle;
@property (nonatomic, strong) IBOutlet UILabel* defaultTitle;
@property (nonatomic, strong) IBOutlet UILabel* defaultAuthor;

@end
