//
//  StepContext.m
//  EMBRACE
//
//  Created by James Rodriguez on 7/21/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "StepContext.h"

@implementation StepContext

@synthesize numSteps; //Number of steps for current sentence
@synthesize currentStep; //Active step to be completed
@synthesize maxAttempts;
@synthesize numAttempts;
@synthesize numSyntaxErrors;
@synthesize numVocabErrors;
@synthesize numUsabilityErrors;

@synthesize PMSolution;
@synthesize IMSolution;
@synthesize stepsComplete;

- (id)init {
    return [super init];
}

@end
