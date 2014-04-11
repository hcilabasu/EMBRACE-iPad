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

-(id) init {
    if (self = [super init]) {
        solutionSteps = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) addSolutionStep:(ActionStep*)solStep {
    [solutionSteps addObject:solStep];
}

/*
 * Returns an array containing all the steps for a given sentence number
 */
-(NSMutableArray*) getStepsForSentence:(NSUInteger)sentNum {
    NSMutableArray* stepsForSentence = [[NSMutableArray alloc] init];
    
    for (ActionStep* step in solutionSteps) {
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
-(NSUInteger) getNumStepsForSentence:(NSUInteger)sentNum {
    NSUInteger numberOfSteps = 0;
    
    for (ActionStep* step in solutionSteps) {
        //Step sentence number matches
        if ([step sentenceNumber] == sentNum) {
            numberOfSteps++; //increase count
        }
    }
    
    return numberOfSteps;
}

@end
