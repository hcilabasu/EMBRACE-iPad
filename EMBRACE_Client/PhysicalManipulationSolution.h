//
//  PhysicalManipulationSolution.h
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Solution.h"

@interface PhysicalManipulationSolution : Solution {
    NSMutableArray* solutionSteps;
}

@property (nonatomic, strong) NSMutableArray* solutionSteps;

-(void) addSolutionStep:(ActionStep*)solStep;
-(NSMutableArray*) getStepsForSentence:(NSNumber*)sentNum;
-(NSNumber*) getNumStepsForSentence:(NSNumber*)sentNum;

@end
