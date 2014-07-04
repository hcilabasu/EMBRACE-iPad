//
//  PieContextualMenuItem.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuItemDataSource.h"

@interface PieContextualMenuItem : UIView {
    MenuItemDataSource *data; 
    float angleFromMenuCenter; //angle at which the item is from the center of the menu. Used to offset the inside circle from the outside circle.
}

@property (nonatomic, strong) MenuItemDataSource *data;

- (id)initWithFrameAndData:(CGRect)frame :(float)angleFromCenter :(MenuItemDataSource*)itemData;

@end
