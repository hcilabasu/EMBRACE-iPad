//
//  ITSImagineManipulationSolution.m
//  EMBRACE
//
//  Created by aewong on 1/28/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ITSImagineManipulationSolution.h"

@implementation ITSImagineManipulationSolution

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
