//
//  Solution.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 11/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Solution.h"

@implementation Solution

@synthesize solutionSteps;

- (id)init {
    if (self = [super init]) {
        self.solutionSteps = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addSolutionStep:(ActionStep *)solStep {
    [solutionSteps addObject:solStep];
}

/*
 * Returns an array containing all the steps for a given sentence number
 */
- (NSMutableArray *)getStepsForSentence:(NSUInteger)sentNum {
    NSMutableArray *stepsForSentence = [[NSMutableArray alloc] init];
    
    for (ActionStep *step in solutionSteps) {
        //Step sentence number matches
        if ([step sentenceNumber] == sentNum) {
            [stepsForSentence addObject:step];
        }
    }
    
    return stepsForSentence;
}

/*
 * Returns the number of steps for a given sentence number
 */
- (NSUInteger)getNumStepsForSentence:(NSUInteger)sentNum {
    NSUInteger numberOfSteps = 0;
    
    for (ActionStep *step in solutionSteps) {
        //Step sentence number matches
        if ([step sentenceNumber] == sentNum) {
            numberOfSteps++; //increase count
        }
    }
    
    return numberOfSteps;
}

/*
 * Returns an array containing the ActionSteps associated with the specified step number
 */
- (NSMutableArray *)getStepsWithNumber:(NSUInteger)stepNum {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    for (ActionStep *step in solutionSteps) {
        //Step number matches
        if ([step stepNumber] == stepNum) {
            [steps addObject:step];
        }
    }
    
    return steps;
}

@end
