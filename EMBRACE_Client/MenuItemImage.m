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
@synthesize boundingBoxImage;
@synthesize zPosition;

- (id)initWithImage:(UIImage*)img {
    self = [super init];
    if (self) {
        image = img;
        zPosition = 0; //Defaults to 0, just like in html. 
    }
    return self;
}

@end
