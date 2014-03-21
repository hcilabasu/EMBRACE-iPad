//
//  PhysicalManipulationActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PhysicalManipulationActivity.h"

@implementation PhysicalManipulationActivity

@synthesize setup;

- (void) addSetup:(NSString*)title {
    setup = [[Setup alloc] initWithTitle:title]; //create new Setup with title
}

@end
