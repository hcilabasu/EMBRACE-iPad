//
//  MenuItemImage.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 10/24/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuItemImage : NSObject {
    UIImage *image;
    CGPoint position;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGPoint position;

- (id)initWithImage:(UIImage*)img;

@end
