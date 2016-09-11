//
//  ITSController.m
//  EMBRACE
//
//  Created by Jithin on 6/1/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ITSController.h"
#import "ManipulationAnalyser.h"
#import "UserAction.h"
#import "ConditionSetup.h"

@interface ITSController()

@property (nonatomic, strong) ManipulationAnalyser *manipulationAnalyser;

@end

@implementation ITSController

+ (instancetype)sharedInstance {
    
    static ITSController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ITSController alloc] init];

    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manipulationAnalyser = [[ManipulationAnalyser alloc] init];
    }
    return self;
}

- (void)setAnalyzerDelegate:(id)delegate {
    self.manipulationAnalyser.delegate = delegate;
}

#pragma  mark - 

- (void)userDidPlayWord:(NSString *)word {
    [self.manipulationAnalyser userDidPlayWord:word];
    
}


- (void)movedObject:(NSString *)objectId
  destinationObjects:(NSArray *)destinationObjs
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context
        forSentence:(NSString *)sentence {
    
    if ([[ConditionSetup sharedInstance] appMode] != ITS) {
        return;
    }
    
    NSString *dest = nil;
    if ([destinationObjs count] > 0) {
           dest = [destinationObjs objectAtIndex:0];
        if ([destinationObjs containsObject:actionStep.object2Id]) {
            dest = [actionStep.object2Id copy];
        }
    }

    UserAction *userAction = [[UserAction alloc] initWithMovedObjectId:objectId
                                                         destinationId:dest
                                                            actionStep:actionStep
                                                            isVerified:verified
                                                           forSentence:sentence];
    [self.manipulationAnalyser actionPerformed:userAction
                           manipulationContext:context];

}

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context
                               forSentence:(NSString *)sentence
                                isVerified:(BOOL)verified {
    
}

- (EMComplexity)getCurrentComplexity {
    
    double easySkillValue = [self.manipulationAnalyser easySyntaxSkillValue];
    double medSkillValue = [self.manipulationAnalyser medSyntaxSkillValue];
    double complexSkillValue = [self.manipulationAnalyser complexSyntaxSkillValue];
    
    EMComplexity complexity = EM_Medium;
    if (complexSkillValue == 0 && easySkillValue == 0 &&
        medSkillValue == 0) {
        complexity = EM_Medium;
        
    } else if (complexSkillValue > 0.8 || medSkillValue > 0.9) {
        complexity = EM_Complex;
        
    } else if (easySkillValue > 0.9 ) {
        complexity = EM_Medium;
        
    } else {
        complexity = EM_Easy;
        
    }
    
    return complexity;
}

- (double)vocabSkillValueForWord:(NSString *)word {
    return [self.manipulationAnalyser vocabSkillForWord:word];
}

- (NSMutableSet *)getExtraIntroductionVocabularyForChapter:(Chapter *)chapter {
    NSMutableSet *extraVocabulary = [[NSMutableSet alloc] init];
    [extraVocabulary unionSet:[self.manipulationAnalyser getRequestedVocab]];
    
    NSMutableSet *chapterVocabulary = [chapter getOldVocabulary];
    [extraVocabulary intersectSet:chapterVocabulary];
    
    NSMutableSet *highSkillVocabulary = [[NSMutableSet alloc] init];
    
    for (NSString *vocabulary in extraVocabulary) {
        double skill = [self vocabSkillValueForWord:vocabulary];
        
        if (skill >= 0.9) {
            [highSkillVocabulary addObject:vocabulary];
        }
    }
    
    [extraVocabulary minusSet:highSkillVocabulary];
    
    return extraVocabulary;
}

@end
