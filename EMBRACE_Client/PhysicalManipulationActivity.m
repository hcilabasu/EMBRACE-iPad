//
//  PhysicalManipulationActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PhysicalManipulationActivity.h"

@implementation PhysicalManipulationActivity

@synthesize setupSteps;
@synthesize PMSolution;

- (id) init {
    if (self = [super init]) {
        setupSteps = [[NSMutableArray alloc] init];
        PMSolution = [[PhysicalManipulationSolution alloc] init];
    }
    
    return self;
}

- (void) addSetupStep:(ActionStep*)setupStep {
    [setupSteps addObject:setupStep];
}

@end