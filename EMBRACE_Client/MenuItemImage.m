//
//  MenuItemImage.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 10/24/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "MenuItemImage.h"

@implementation MenuItemImage

@synthesize image;
@synthesize position;

- (id)initWithImage:(UIImage*)img {
    self = [super init];
    if (self) {
        image = img;
    }
    return self;
}

@end
