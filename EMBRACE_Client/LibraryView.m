//
//  LibraryView.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/8/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LibraryView.h"

@implementation LibraryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"initializing library view");
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"in draw reg for library view");
}

@end
