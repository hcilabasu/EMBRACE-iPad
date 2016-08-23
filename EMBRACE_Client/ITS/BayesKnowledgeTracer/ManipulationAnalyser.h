//
//  ManipulationAnalyser.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSController.h"

@class UserAction, ActionStep;
@class ManipulationContext;
@protocol ManipulationAnalyserProtocol;

@interface ManipulationAnalyser : NSObject

@property (nonatomic, weak) id <ManipulationAnalyserProtocol> delegate;

- (void)actionPerformed:(UserAction *)userAction
    manipulationContext:(ManipulationContext *)context;

- (void)userDidPlayWord:(NSString *)word;

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context
                               forSentence:(NSString *)sentence
                                isVerified:(BOOL)verified;

- (double)easySyntaxSkillValue;
- (double)medSyntaxSkillValue;
- (double)complexSyntaxSkillValue;

@end


@protocol ManipulationAnalyserProtocol <NSObject>

- (CGPoint)locationOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer;

- (NSArray *)getNextStepsForCurrentSentence:(ManipulationAnalyser *)analyzer;

- (EMComplexity)analyzer:(ManipulationAnalyser *)analyzer getComplexityForSentence:(int)sentenceNumber;

- (void)analyzer:(ManipulationAnalyser *)analyzer showMessage:(NSString *)message;

@end