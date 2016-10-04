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

- (void)userDidVocabPreviewWord:(NSString *)word {
    [self.manipulationAnalyser userDidVocabPreviewWord:word];
}


- (void)movedObject:(NSString *)objectId
 destinationObjects:(NSArray *)destinationObjs
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context
        forSentence:(NSString *)sentence
    withWordMapping:(NSDictionary *)mapDict {
    
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
    
    NSString *actionObj1 = actionStep.object1Id;
    NSString *correctDest = nil;
    if (actionStep.object2Id != nil) {
        correctDest = actionStep.object2Id;
        
    } else if (actionStep.locationId != nil) {
        correctDest = actionStep.locationId;
        
    } else if (actionStep.areaId != nil) {
        correctDest = actionStep.areaId;
    }


    // Convert the words to the mapped keys if present
    for (NSString *key in mapDict.allKeys) {
        
        NSArray *mappedWords = [mapDict objectForKey:key];
        if ([mappedWords containsObject:objectId]) {
            objectId = [key copy];
        }
        if ([mappedWords containsObject:dest]) {
            dest = [key copy];
        }
        if ([mappedWords containsObject:actionObj1]) {
            actionObj1 = [key copy];
        }
        if ([mappedWords containsObject:correctDest]) {
            correctDest = [key copy];
        }
        
    }
    
    UserAction *userAction = [[UserAction alloc] initWithMovedObjectId:objectId
                                                         destinationId:dest
                                                            isVerified:verified
                                               actionStepMovedObjectId:actionObj1
                                         actionStepDestinationObjectId:correctDest
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

- (NSMutableSet *)getExtraIntroductionVocabularyForChapter:(Chapter *)chapter inBook:(Book *)book {
    NSMutableSet *extraVocabulary = [[NSMutableSet alloc] init];
    [extraVocabulary unionSet:[self.manipulationAnalyser getRequestedVocab]];
    
    NSMutableSet *chapterVocabulary = [chapter getOldVocabulary];
    [extraVocabulary intersectSet:chapterVocabulary];
    
    NSMutableSet *solutionVocabulary = [[NSMutableSet alloc] init];
    
    for (Chapter *bookChapter in [book chapters]) {
        if ([[bookChapter title] isEqualToString:[chapter title]]) {
            break;
        }
        else {
            [solutionVocabulary unionSet:[bookChapter getVocabularyFromSolutions]];
        }
    }
    
    [solutionVocabulary intersectSet:[chapter getVocabularyFromSolutions]];
    [extraVocabulary unionSet:solutionVocabulary];
    
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
