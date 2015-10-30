//
//  LibraryCellView.h
//  EMBRACE
//
//  Created by Administrator on 10/5/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibraryCellView : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImage;
@property (nonatomic, strong) IBOutlet UILabel* coverTitle;

@end