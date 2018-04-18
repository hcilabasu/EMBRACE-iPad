//
//  BookHeaderView.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookHeaderView : UICollectionReusableView

@property (nonatomic, strong) IBOutlet UILabel* bookTitle;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@end
