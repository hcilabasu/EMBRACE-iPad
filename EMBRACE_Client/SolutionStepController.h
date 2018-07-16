//
//  SolutionStepController.h
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationViewController.h"

@interface SolutionStepController : NSObject

@property (nonatomic, weak) ManipulationViewController *mvc;
@property (nonatomic, weak) StepContext *stepContext;
@property (nonatomic, weak) ConditionSetup *conditionSetup;
@property (nonatomic, weak) PageContext *pageContext;
@property (nonatomic, weak) SentenceContext *sentenceContext;
@property (nonatomic, weak) ManipulationContext *manipulationContext;

-(id)initWithController:(ManipulationViewController *) superMvc;
- (NSMutableArray *)returnCurrentSolutionSteps;
- (NSString *)getCurrentSolutionStep;
- (BOOL)checkSolutionForSubject:(NSString *)subject;
- (BOOL)checkSolutionForObject:(NSString *)overlappingObject;
- (void)moveObjectForSolution;
- (void)incrementCurrentStep;
- (void)createVocabSolutionsForPage;

@end
