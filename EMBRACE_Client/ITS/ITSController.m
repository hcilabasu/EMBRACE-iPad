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
@property (nonatomic, assign) EMComplexity currentComplexity;

@end

@implementation ITSController

static ITSController *sharedInstance = nil;

+ (ITSController *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[ITSController alloc] init];
    }
    
    return sharedInstance;
}

+ (void)resetSharedInstance {
    sharedInstance = nil;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _manipulationAnalyser = [[ManipulationAnalyser alloc] init];
        _currentComplexity = EM_Medium;
    }
    
    return self;
}

- (void)setAnalyzerDelegate:(id)delegate {
    self.manipulationAnalyser.delegate = delegate;
}

#pragma  mark - 

- (void)userDidPlayWord:(NSString *)word context:(ManipulationContext *)context {
    [self.manipulationAnalyser userDidPlayWord:word context:context];
}

- (void)userDidVocabPreviewWord:(NSString *)word context:(ManipulationContext *)context {
    [self.manipulationAnalyser userDidVocabPreviewWord:word context:context];
}

- (void)movedObjectIDs:(NSMutableSet *)movedObjectIDs destinationIDs:(NSArray *)destinationIDs isVerified:(BOOL)verified actionStep:(ActionStep *)actionStep manipulationContext:(ManipulationContext *)context forSentence:(NSString *)sentence withWordMapping:(NSDictionary *)mapDict {
    // Get step information
    NSString *object1ID = [actionStep object1Id];
    NSString *object2ID = [actionStep object2Id];
    NSString *locationID = [actionStep locationId];
    NSString *areaID = [actionStep areaId];
    
    // If the current step involves transference, we need the next step to help determine object1ID and object2ID
    if ([[actionStep stepType] isEqualToString:@"transferAndGroup"] || [[actionStep stepType] isEqualToString:@"transferAndDisappear"]) {
        ActionStep *nextStep = [[self.manipulationAnalyser.delegate getNextStepsForCurrentSentence:self.manipulationAnalyser] firstObject];
        
        // Try to select the distinct objects in the transference steps.
        if ([[actionStep object2Id] isEqualToString:[nextStep object2Id]]) {
            object1ID = [actionStep object1Id];
            object2ID = [nextStep object1Id];
        }
        else if ([[actionStep object2Id] isEqualToString:[nextStep object1Id]]) {
            object1ID = [actionStep object1Id];
            object2ID = [nextStep object2Id];
        }
        else if ([[actionStep object1Id] isEqualToString:[nextStep object2Id]]) {
            object1ID = [nextStep object1Id];
            object2ID = [actionStep object2Id];
        }
    }
    
    NSString *correctMovedObjectID = object1ID;
    NSString *correctDestinationID;
    
    // Set action step destination based on object, location, or area
    if (object2ID != nil) {
        correctDestinationID = object2ID;
    }
    else if (locationID != nil) {
        correctDestinationID = locationID;
    }
    else if (areaID != nil) {
        correctDestinationID = areaID;
    }
    
    // Convert the action step moved object and destination to the mapped keys if present
    for (NSString *key in mapDict.allKeys) {
        NSArray *mappedWords = [mapDict objectForKey:key];
        
        if ([mappedWords containsObject:correctMovedObjectID]) {
            correctMovedObjectID = [key copy];
        }
        
        if ([mappedWords containsObject:correctDestinationID]) {
            correctDestinationID = [key copy];
        }
    }
    
    NSMutableSet *convertedMovedObjectIDs = [[NSMutableSet alloc] init];
    
    // Convert the moved objects to the mapped keys if present
    for (NSString *movedObjectID in movedObjectIDs) {
        BOOL present = FALSE;
        
        for (NSString *key in mapDict.allKeys) {
            NSArray *mappedWords = [mapDict objectForKey:key];
            
            if ([mappedWords containsObject:movedObjectID]) {
                present = TRUE;
                [convertedMovedObjectIDs addObject:[key copy]];
                break;
            }
        }
        
        if (!present) {
            // Nothing to convert, so just use the word itself
            [convertedMovedObjectIDs addObject:movedObjectID];
        }
    }
    
    NSMutableSet *convertedDestinationIDs = [[NSMutableSet alloc] init];
    
    // Convert the destinations to the mapped keys if present
    for (NSString *destinationID in destinationIDs) {
        BOOL present = FALSE;
        
        for (NSString *key in mapDict.allKeys) {
            NSArray *mappedWords = [mapDict objectForKey:key];
            
            if ([mappedWords containsObject:destinationID]) {
                present = TRUE;
                [convertedDestinationIDs addObject:[key copy]];
                break;
            }
        }
        
        if (!present) {
            // Nothing to convert, so just use the word itself
            [convertedDestinationIDs addObject:destinationID];
        }
    }
    
    UserAction *userAction = [[UserAction alloc] initWithMovedObjectIDs:convertedMovedObjectIDs destinationIDs:convertedDestinationIDs isVerified:verified correctMovedObjectID:correctMovedObjectID correctDestinationID:correctDestinationID forSentence:sentence];
    
    [self.manipulationAnalyser actionPerformed:userAction manipulationContext:context];
}

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context forSentence:(NSString *)sentence isVerified:(BOOL)verified {
    
}

- (EMComplexity)getCurrentComplexity {
    return _currentComplexity;
}

- (EMComplexity)setCurrentComplexity {
    double easySkillValue = [self.manipulationAnalyser easySyntaxSkillValue];
    double medSkillValue = [self.manipulationAnalyser medSyntaxSkillValue];
    double complexSkillValue = [self.manipulationAnalyser complexSyntaxSkillValue];
    
    EMComplexity complexity = _currentComplexity;
    
    if (easySkillValue == 0 && medSkillValue == 0 && complexSkillValue == 0) {
        complexity = EM_Medium;
    }
    else if (easySkillValue < 0.9 || (easySkillValue > 0.9 && (medSkillValue < 0.4 && medSkillValue > 0.15))) {
        complexity = EM_Easy;
    }
    else if (medSkillValue < 0.9 || (medSkillValue > 0.9 && (complexSkillValue < 0.4 && complexSkillValue > 0.15))) {
        complexity = EM_Medium;
    }
    else {
        complexity = EM_Complex;
    }
    
    _currentComplexity = complexity;
    
    return complexity;
}

- (NSMutableSet *)getExtraIntroductionVocabularyForChapter:(Chapter *)chapter inBook:(Book *)book {
    double HIGH_VOCABULARY_SKILL_THRESHOLD = 0.8;
    int MAX_EXTRA_VOCABULARY = 8.0 - [[chapter getNewVocabulary] count];
    
    NSMutableSet *extraVocabulary = [[NSMutableSet alloc] init];
    
    // Get all vocabulary that comes from solutions of previous chapters
    NSMutableSet *solutionVocabulary = [[NSMutableSet alloc] init];
    
    for (Chapter *bookChapter in [book chapters]) {
        if ([[bookChapter title] isEqualToString:[chapter title]]) {
            break;
        }
        else {
            [solutionVocabulary unionSet:[bookChapter getVocabularyFromSolutions]];
        }
    }
    
    // Remove vocabulary that does not appear in solution of current chapter
    [solutionVocabulary intersectSet:[chapter getVocabularyFromSolutions]];
    
    // Get all vocabulary that can be requested by combining underlined chapter vocabulary with solution vocabulary
    NSMutableSet *allowedVocabularyToRequest = [chapter getOldVocabulary];
    [allowedVocabularyToRequest unionSet:solutionVocabulary];
    
    // Add requested vocabulary only if it appears in the allowed vocabulary set
    NSMutableSet *requestedVocabulary = [[NSMutableSet alloc] init];
    [requestedVocabulary unionSet:[self.manipulationAnalyser getRequestedVocab]];
    [requestedVocabulary intersectSet:allowedVocabularyToRequest];
    
    // Potential vocabulary combines solution vocabulary and requested vocabulary
    NSMutableSet *potentialVocabulary = [[NSMutableSet alloc] init];
    [potentialVocabulary unionSet:solutionVocabulary];
    [potentialVocabulary unionSet:requestedVocabulary];
    
    // Sort vocabulary/skills from lowest to highest skill
    NSMutableArray *vocabularyStrings = [[NSMutableArray alloc] init];
    NSMutableArray *vocabularySkills = [[NSMutableArray alloc] init];
    
    for (NSString *vocabulary in potentialVocabulary) {
        double s = [self.manipulationAnalyser vocabSkillForWord:vocabulary];
        
        // Do not include vocabulary with skills above the threshold
        if (s < HIGH_VOCABULARY_SKILL_THRESHOLD) {
            NSNumber *skill = [NSNumber numberWithDouble:s];
            
            // Figure out index to insert vocabulary/skill into sorted arrays
            NSUInteger index = [vocabularySkills indexOfObject:skill inSortedRange:(NSRange){0, [vocabularySkills count]} options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 compare:obj2];
            }];
            
            [vocabularyStrings insertObject:vocabulary atIndex:index];
            [vocabularySkills insertObject:skill atIndex:index];
        }
    }
    
    // Extra vocabulary will consist of the vocabulary with the lowest skills
    if ([vocabularyStrings count] <= MAX_EXTRA_VOCABULARY) {
        [extraVocabulary addObjectsFromArray:vocabularyStrings];
    }
    else {
        [extraVocabulary addObjectsFromArray:[vocabularyStrings subarrayWithRange:NSMakeRange(0, MAX_EXTRA_VOCABULARY)]];
    }
    
    return extraVocabulary;
}

- (NSString *)getMostProbableErrorType {
    return [self.manipulationAnalyser getMostProbableErrorType];
}

@end
