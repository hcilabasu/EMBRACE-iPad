//
//  Solution.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 11/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ActionStep.h"

@interface Solution : NSObject

@property (nonatomic, strong) NSMutableArray *solutionSteps;

- (void)addSolutionStep:(ActionStep *)solStep;
- (NSMutableArray *)getStepsForSentence:(NSUInteger)sentNum;
- (NSUInteger)getNumStepsForSentence:(NSUInteger)sentNum;
- (NSMutableArray *)getStepsWithNumber:(NSUInteger)stepNum;

@end
