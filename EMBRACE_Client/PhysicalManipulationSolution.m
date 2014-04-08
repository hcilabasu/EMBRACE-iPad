//
//  PhysicalManipulationSolution.m
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "PhysicalManipulationSolution.h"

@implementation PhysicalManipulationSolution

@synthesize solutionSteps;

- (id) init {
    if (self = [super init]) {
        solutionSteps = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) addSolutionStep:(ActionStep*)solStep {
    [solutionSteps addObject:solStep];
}

@end
