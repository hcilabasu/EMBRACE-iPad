//
//  ManipulationAnalyser.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSController.h"
#import "ConditionSetup.h"
#import "SentenceContext.h"
@class SkillSet;
@class UserAction, ActionStep;
@class ManipulationContext;
@protocol ManipulationAnalyserProtocol;

@interface ManipulationAnalyser : NSObject

@property (nonatomic, weak) id <ManipulationAnalyserProtocol> delegate;
@property (nonatomic, strong) ConditionSetup* conditionsetup;
@property (nonatomic, strong) SentenceContext* sentencecontext;

- (SkillSet *)getSkillSet;
- (void)setSkillSet:(SkillSet *)skillSet;

- (void)actionPerformed:(UserAction *)userAction manipulationContext:(ManipulationContext *)context;

- (void)userDidPlayWord:(NSString *)word context:(ManipulationContext *)context;
- (void)userDidVocabPreviewWord:(NSString *)word context:(ManipulationContext *)context;
- (NSMutableSet *)getRequestedVocab;

- (double)syntaxSkillValue;

//- (double)easySyntaxSkillValue;
//- (double)medSyntaxSkillValue;
//- (double)complexSyntaxSkillValue;

- (double)vocabSkillForWord:(NSString *)word;

- (ErrorFeedback * )feedbackToShow;

- (void)resetSyntaxForContext:(ManipulationContext *)context;

@end

@protocol ManipulationAnalyserProtocol <NSObject>

- (CGPoint)locationOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer;

- (CGPoint)analyzerInitialPositionOfMovedObject:(ManipulationAnalyser *)analyzer;

- (CGSize)sizeOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer;

- (NSArray *)getNextStepsForCurrentSentence:(ManipulationAnalyser *)analyzer;
- (NSArray *)getStepsForCurrentSentence:(ManipulationAnalyser *)analyzer;

- (EMComplexity)getComplexityForCurrentSentence:(ManipulationAnalyser *)analyzer;
- (NSString *)getCurrentSentenceText:(ManipulationAnalyser *)analyzer;

- (NSDictionary *)getWordMapping;

- (void)analyzer:(ManipulationAnalyser *)analyzer showMessage:(NSString *)message;

@end
