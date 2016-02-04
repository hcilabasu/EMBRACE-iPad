//
//  PhysicalManipulationSolution.m
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "PhysicalManipulationSolution.h"

@implementation PhysicalManipulationSolution

- (id)init {
    self = [super init];
    
    return self;
}

/*
 * Returns an array containing all the idea numbers associated with the story
 */
- (NSMutableArray *)getIdeaNumbers {
    NSMutableArray *ideaNums = [[NSMutableArray alloc] init];
    
    NSUInteger currIdeaNumber = 0;
    
    for (ActionStep *step in [self solutionSteps]) {
        if ([step sentenceNumber] > currIdeaNumber) {
            [ideaNums addObject:[NSNumber numberWithInteger:[step sentenceNumber]]];
            currIdeaNumber = [step sentenceNumber];
        }
    }
    
    return ideaNums;
}

@end
