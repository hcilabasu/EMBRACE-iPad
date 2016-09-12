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

@property (nonatomic, strong) ManipulationViewController *mvc;
@property (nonatomic, strong) StepContext *stepContext;
@property (nonatomic, strong) ConditionSetup *conditionSetup;
@property (nonatomic, strong) PageContext *pageContext;
@property (nonatomic, strong) SentenceContext *sentenceContext;
@property (nonatomic, strong) ManipulationContext *manipulationContext;

-(id)initWithController:(ManipulationViewController *) superMvc;
- (NSMutableArray *)returnCurrentSolutionSteps;
- (NSString *)getCurrentSolutionStep;
- (BOOL)checkSolutionForSubject:(NSString *)subject;
- (BOOL)checkSolutionForObject:(NSString *)overlappingObject;
- (void)moveObjectForSolution;
- (void)incrementCurrentStep;
- (void)createVocabSolutionsForPage;

@end
