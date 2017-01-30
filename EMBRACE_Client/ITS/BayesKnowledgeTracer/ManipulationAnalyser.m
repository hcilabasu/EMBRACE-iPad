//
//  ManipulationAnalyser.m
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ManipulationAnalyser.h"
#import "ManipulationContext.h"
#import "KnowledgeTracer.h"
#import "UserAction.h"
#import "SentenceStatus.h"
#import "ActionStep.h"
#import "Skill.h"
#import "WordSkill.h"
#import "SyntaxSkill.h"
#import "UsabilitySkill.h"

#define DISTANCE_THRESHOLD 90
#define HIGH_VOCABULARY_SKILL_THRESHOLD  0.9

@interface ManipulationAnalyser ()

@property (nonatomic, strong) KnowledgeTracer *knowledgeTracer;

// List of books that the user currently have read.
// Key: BookTitle Value: Dictionary
// Internal Dictionary contains the actions performed for each sentence
// Key : ChapterTitle_SentenceNumber Value: StatementStatus
@property (nonatomic, strong) NSMutableDictionary *booksDict;

@property (nonatomic, strong) NSMutableSet *playWords;

@property (nonatomic, strong) ErrorFeedback *currentFeedback;

@property (nonatomic, strong) SentenceStatus *currentSentenceStatus;

@end

@implementation ManipulationAnalyser

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _knowledgeTracer = [[KnowledgeTracer alloc] init];
        _booksDict = [[NSMutableDictionary alloc] init];
        _playWords = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (SkillSet *)getSkillSet {
    return [_knowledgeTracer getSkillSet];
}

- (void)setSkillSet:(SkillSet *)skillSet {
    [_knowledgeTracer setSkillSet:skillSet];
}

- (void)userDidPlayWord:(NSString *)word context:(ManipulationContext *)context {
    [self.playWords addObject:word];
    NSMutableArray *skillList = [NSMutableArray array];
    Skill *movedSkill = [self.knowledgeTracer generateSkillFor:word isVerified:NO context:context];
    [skillList addObject:movedSkill];
    [self.knowledgeTracer updateSkills:@[movedSkill]];
    [self showMessageWith:skillList];
}

- (void)userDidVocabPreviewWord:(NSString *)word context:(ManipulationContext *)context {
    [self.playWords addObject:word];
    
    NSMutableArray *skillList = [NSMutableArray array];
    Skill *movedSkill = [self.knowledgeTracer generateSkillFor:word
                                                    isVerified:YES
                                                       context:context
                                                 isFromPreview:YES];
    [skillList addObject:movedSkill];
    [self.knowledgeTracer updateSkills:@[movedSkill]];
    [self showMessageWith:skillList];
}

- (NSMutableSet *)getRequestedVocab {
    return self.playWords;
}

- (double)syntaxSkillValue {
    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Default];
    
    return sk.skillValue;
}

//- (double)easySyntaxSkillValue {
//    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Easy];
//
//    return sk.skillValue;
//}
//
//- (double)medSyntaxSkillValue {
//    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Medium];
//
//    return sk.skillValue;
//}
//
//- (double)complexSyntaxSkillValue {
//    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Complex];
//
//    return sk.skillValue;
//}

- (double)vocabSkillForWord:(NSString *)word {
    Skill *sk = [self.knowledgeTracer vocabSkillForWord:word];
    
    return sk.skillValue;
}

- (void)actionPerformed:(UserAction *)userAction
    manipulationContext:(ManipulationContext *)context {
    
    userAction.sentenceNumber = context.sentenceNumber;
    userAction.ideaNumber = context.ideaNumber;
    userAction.stepNumber = context.stepNumber;
    
    NSString *bookTitle = context.bookTitle;
    NSMutableDictionary *bookDetails = [self bookDictionaryForTitle:bookTitle];
    self.currentSentenceStatus = [self getActionListFrom:bookDetails forChapter:context.chapterTitle sentenceNumber:context.sentenceNumber andIdeaNumber:context.ideaNumber];
    
    if ([self.currentSentenceStatus containsAction:userAction]) {
        // The sentence has been tried before
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:NO];
    }
    else {
        // First try by user
        self.currentSentenceStatus.updatedVocabSkills = [NSMutableSet set];
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:YES];
    }
    
    [self.currentSentenceStatus addUserAction:userAction];
}

- (void)analyzeAndUpdateSkill:(UserAction *)userAction
                   andContext:(ManipulationContext *)context
               isFirstAttempt:(BOOL)isFirstAttempt {
    
    [self.knowledgeTracer updateDampenValue:!isFirstAttempt];
    
    // Correct action
    if (userAction.isVerified) {
        NSMutableArray *skills = [NSMutableArray array];
        
        // Increase vocabulary skill for the object(s) moved
        for (NSString *movedObjectID in [userAction movedObjectIDs]) {
            [self updateVocabSkillFor:movedObjectID
                               skills:skills
                           isVerified:YES
                       isFirstAttempt:isFirstAttempt
                              context:context];
        }
        
        NSString *correctDestinationID = [userAction correctDestinationID];
        
        // Increase vocabulary skill for the destination
        if (correctDestinationID != nil && ![correctDestinationID isEqualToString:@""]) {
            [self updateVocabSkillFor:correctDestinationID
                               skills:skills
                           isVerified:YES
                       isFirstAttempt:isFirstAttempt
                              context:context];
        }
        
        // Increase syntax skill
        EMComplexity complexity = [self.delegate getComplexityForCurrentSentence:self];
        Skill *syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                        isVerified:YES
                                                           context:context];
        if (syntaxSkill != nil) {
            [skills addObject:syntaxSkill];
        }
        
        
        // Increase usability skill
        Skill *usabilitySkill = [self.knowledgeTracer generateUsabilitySkill:YES context:context];
        
        if (usabilitySkill != nil) {
            [skills addObject:usabilitySkill];
        }
        
        
        NSArray *finalSkills = [self filterSkillsForCorrectAction:skills];
        [self.knowledgeTracer updateSkills:finalSkills];
        [self showMessageWith:finalSkills];
    }
    // Incorrect action
    else {
        // Determine what skills to adjust based on error
        [self updateSkillBasedOnMovedObject:userAction andContext:context isFirstAttempt:isFirstAttempt];
    }
}

- (void)updateSkillBasedOnMovedObject:(UserAction *)userAction
                           andContext:(ManipulationContext *)context
                       isFirstAttempt:(BOOL)isFirstAttempt {
    
    BOOL syntaxErrorFound = NO;
    NSMutableArray *skills = [NSMutableArray array];
    EMComplexity complexity = [self.delegate getComplexityForCurrentSentence:self];
    
    // Get user action information
    NSSet *movedObjectIDs = [userAction movedObjectIDs];
    NSSet *destinationIDs = [userAction destinationIDs];
    NSString *correctMovedObjectID = [userAction correctMovedObjectID];
    NSString *correctDestinationID = [userAction correctDestinationID];
    
    // Check for syntax error
    // Mixed up order of subject and object
    if ([destinationIDs containsObject:correctMovedObjectID] && [movedObjectIDs containsObject:correctDestinationID]) {
        // Decrease syntax skill
        Skill *syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                        isVerified:NO
                                                           context:context];
        [skills addObject:syntaxSkill];
        syntaxErrorFound = YES;
    }
    // Check for syntax error
    // Moved objects involved in the sentence
    else {
        // Get objects involved in current sentence
        NSSet *objectsInvolved = [self getObjectsInvolvedInCurrentSentence];
        
        // Check if any of the moved objects and destinations are involved in the sentence
        for (NSString *movedObjectID in movedObjectIDs) {
            for (NSString *destinationID in destinationIDs) {
                if ([objectsInvolved containsObject:movedObjectID] && [objectsInvolved containsObject:destinationID]) {
                    // Decrease syntax skill
                    Skill *syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                                    isVerified:NO
                                                                       context:context];
                    [skills addObject:syntaxSkill];
                    syntaxErrorFound = YES;
                    break;
                }
            }
        }
    }
    
    if (syntaxErrorFound == NO) {
        Skill *syntaxSkill;
        Skill *usabilitySkill;
        
        
        [self checkMovedObjectWithObjects:movedObjectIDs
                            correctObject:correctMovedObjectID
                                   skills:skills
                             firstAttempt:isFirstAttempt
                               complexity:complexity
                               andContext:context];
        
        
        [self checkDestinationObjectWithObjects:destinationIDs
                                  correctObject:correctDestinationID
                                         skills:skills
                                   firstAttempt:isFirstAttempt
                                     complexity:complexity
                                     andContext:context];
        
        // Add syntax skill if it was updated
        if (syntaxSkill != nil) {
            [skills addObject:syntaxSkill];
        }
        
        // Add usability skill if it was updated
        if (usabilitySkill != nil) {
            [skills addObject:usabilitySkill];
        }
    }
    
    [self determineFeedbackToShow:skills];
    NSArray *finalSkills = [self filterSkillsForError:skills];
    [self.knowledgeTracer updateSkills:finalSkills];
    [self showMessageWith:finalSkills];
    
}

- (NSMutableArray *)filterSkillsForCorrectAction:(NSMutableArray *)skills  {
    NSMutableArray *array = [NSMutableArray array];
    for (Skill *skill in skills) {
        
        if(skill.skillType == SkillType_Syntax) {
            if (self.currentSentenceStatus.numOfSyntaxErrors == 0) {
                    [array addObject:skill];
            } else {
                // If same sentence has two steps, new step has 0 syntax skill value
                self.currentSentenceStatus.numOfSyntaxErrors = 0;
            }
            
        } else {
            [array addObject:skill];
        }
    }

    return array;
}


- (NSMutableArray *)filterSkillsForError:(NSMutableArray *)skills {
    
    NSMutableArray *array = [NSMutableArray array];
    for (Skill *skill in skills) {
        
        if(skill.skillType == SkillType_Vocab ||
           skill.skillType == SkillType_Prev_Vocab) {

            WordSkill *wskill = (WordSkill *)skill;
                // Update the vocab skill if it was not updated before in the current sentence
                //
                if ([self.currentSentenceStatus.updatedVocabSkills containsObject:wskill.word] == NO) {
                    
                    if (wskill != nil) {
                        [array addObject:wskill];
                        [self.currentSentenceStatus.updatedVocabSkills addObject:wskill.word];
                    }
                }
        } else {
            [array addObject:skill];
        }
    }
    return  array;
    
}

/**
 * Check all possible skill updates based on the destination objects.
 * Different cases are:
 *
 * 1. Check if the destination is emtpy.
 * 2. Correct destination object is not present in the Destination objects list.
 *      i. Check the distance is above a threshold and if true it is usability
 *      ii. Else it is a syntax or vocab
 * 3. If Correct Destination object is present in Destinations objects list, increase the syntax skill.
 **/
- (void) checkDestinationObjectWithObjects:(NSSet *)destinationIDs
                             correctObject:(NSString *)correctDestinationID
                                    skills:(NSMutableArray *)skills
                              firstAttempt:(BOOL)isFirstAttempt
                                complexity:(EMComplexity) complexity
                                andContext:(ManipulationContext *)context {
    
    Skill *syntaxSkill;
    Skill *usabilitySkill;
    
    // Check for vocabulary, syntax, or usability errors
    // Vocabulary or syntax error
    if ([destinationIDs count] == 0) {
        double correctSkillValue = [[self.knowledgeTracer vocabSkillForWord:correctDestinationID] skillValue];
        
        // Vocabulary error
        if (correctSkillValue < HIGH_VOCABULARY_SKILL_THRESHOLD) {
            // Decrease vocabulary error for the correct destination
            [self updateVocabSkillFor:correctDestinationID
                               skills:skills
                           isVerified:NO
                       isFirstAttempt:isFirstAttempt
                              context:context];
        }
        // Syntax error
        else {
            // Decrease syntax skill
            syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                            isVerified:NO
                                                               context:context];
        }
    }
    // Moved to incorrect destination
    else if (![destinationIDs containsObject:correctDestinationID]) {
        // Vocabulary or syntax error
        if (![self isDestDistanceBelowThreshold:destinationIDs :correctDestinationID]) {
            double correctSkillValue = [[self.knowledgeTracer vocabSkillForWord:correctDestinationID] skillValue];
            
            // Vocabulary error
            if (correctSkillValue < HIGH_VOCABULARY_SKILL_THRESHOLD) {
                // Decrease vocabulary skill for the correct destination
                [self updateVocabSkillFor:correctDestinationID
                                   skills:skills
                               isVerified:NO
                           isFirstAttempt:isFirstAttempt
                                  context:context];
                
                // Decrease vocabulary skills for the destinations
                for (NSString *destinationID in destinationIDs) {
                    
                    [self updateVocabSkillFor:destinationID
                                       skills:skills
                                   isVerified:NO
                               isFirstAttempt:isFirstAttempt
                                      context:context];
                }
            }
            // Syntax error
            else {
                // Decrease syntax skill
                syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                                isVerified:NO
                                                                   context:context];
            }
        }
        // Usability error
        else {
            // Decrease usability skill
            usabilitySkill = [self.knowledgeTracer generateUsabilitySkill:NO context:context];
        }
    }
    // Moved to correct destination
    else {
        // Increase vocabulary skill for the destination
        [self updateVocabSkillFor:correctDestinationID
                           skills:skills
                       isVerified:YES
                   isFirstAttempt:isFirstAttempt
                          context:context];
        
    }
    
    // Add syntax skill if it was updated
    if (syntaxSkill != nil) {
        [skills addObject:syntaxSkill];
    }
    
    // Add usability skill if it was updated
    if (usabilitySkill != nil) {
        [skills addObject:usabilitySkill];
    }
    
}


/**
 * Check all possible skill updates based on the moved objects.
 * Different cases are:
 *
 * 1. Correct moved object is not present in the moved objects list.
 *      i. Check the distance is above a threshold and if true it is usability
 *      ii. Else it is a syntax or vocab
 * 2. If Correct Moved object is present in moved objects list, increase the syntax skill.
 **/
- (void) checkMovedObjectWithObjects:(NSSet *)movedObjectIDs
                       correctObject:(NSString *)correctMovedObjectID
                              skills:(NSMutableArray *)skills
                        firstAttempt:(BOOL)isFirstAttempt
                          complexity:(EMComplexity) complexity
                          andContext:(ManipulationContext *)context {
    
    
    Skill *syntaxSkill;
    Skill *usabilitySkill;
    
    // Check for vocabulary, syntax, or usability errors
    // Moved incorrect object
    if (![movedObjectIDs containsObject:correctMovedObjectID]) {
        // Vocabulary or syntax error
        if (![self isInitialDistanceBelowThreshold:movedObjectIDs :correctMovedObjectID]) {
            double correctSkillValue = [[self.knowledgeTracer vocabSkillForWord:correctMovedObjectID] skillValue];
            
            // Vocabulary error
            if (correctSkillValue < HIGH_VOCABULARY_SKILL_THRESHOLD) {
                // Decrease vocabulary skill for the correct object to move
                [self updateVocabSkillFor:correctMovedObjectID
                                   skills:skills
                               isVerified:NO
                           isFirstAttempt:isFirstAttempt
                                  context:context];
                
                // Decrease vocabulary skills for the moved objects
                for (NSString *movedObjectID in movedObjectIDs) {
                    [self updateVocabSkillFor:movedObjectID
                                       skills:skills
                                   isVerified:NO
                               isFirstAttempt:isFirstAttempt
                                      context:context];
                }
            }
            // Syntax error
            else {
                // Decrease syntax skill
                syntaxSkill = [self updateSyntaxSkillwithComplexity:complexity
                                                                isVerified:NO
                                                                   context:context];
            }
        }
        // Usability error
        else {
            // Decrease usability skill
            usabilitySkill = [self.knowledgeTracer generateUsabilitySkill:NO context:context];
        }
    }
    // Moved correct object
    else {
        for (NSString *movedObjectID in movedObjectIDs) {
            // Increase vocabulary skill for the moved object
            [self updateVocabSkillFor:movedObjectID
                               skills:skills
                           isVerified:YES
                       isFirstAttempt:isFirstAttempt
                              context:context];
        }
    }
    // Add syntax skill if it was updated
    if (syntaxSkill != nil) {
        [skills addObject:syntaxSkill];
    }
    
    // Add usability skill if it was updated
    if (usabilitySkill != nil) {
        [skills addObject:usabilitySkill];
    }
}

- (Skill *)updateSyntaxSkillwithComplexity:(EMComplexity)complexity
                             isVerified:(BOOL)isVerified
                                context:(ManipulationContext *)context{
    Skill *sk = nil;
    sk = [self.knowledgeTracer generateSyntaxSkill:isVerified withComplexity:complexity context:context];
    
    return sk;
}

- (void)updateVocabSkillFor:(NSString *)word
                     skills:(NSMutableArray *)skills
                 isVerified:(BOOL)isVerified
             isFirstAttempt:(BOOL)isFirstAttempt
                    context:(ManipulationContext *)context {
    
    
    Skill *wordSkill = [self.knowledgeTracer generateSkillFor:word
                                                 isVerified:isVerified
                                                    context:context];
    
    if (wordSkill != nil) {
        [skills addObject:wordSkill];
    }
    
}

- (NSSet *)getObjectsInvolvedInCurrentSentence {
    NSMutableSet *objectsInvolved = [[NSMutableSet alloc] init];
    
    NSArray *currentSteps = [self.delegate getStepsForCurrentSentence:self];
    
    // Get all the objects (objects, locations, areas) involved in the sentence
    for (ActionStep *currentStep in currentSteps) {
        NSString *object1Id = [currentStep object1Id];
        NSString *object2Id = [currentStep object2Id];
        NSString *locationId = [currentStep locationId];
        NSString *areaId = [currentStep areaId];
        
        if (object1Id != nil) {
            [objectsInvolved addObject:object1Id];
        }
        
        if (object2Id != nil) {
            [objectsInvolved addObject:object2Id];
        }
        
        if (locationId != nil) {
            [objectsInvolved addObject:locationId];
        }
        
        if (areaId != nil) {
            [objectsInvolved addObject:areaId];
        }
    }
    
    NSArray *currentSentenceTextTokens = [[self.delegate getCurrentSentenceText:self] componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    
    // Get all the words involved in the sentence
    for (NSString *currentSentenceTextToken in currentSentenceTextTokens) {
        // Discard tokens that are too short
        if ([currentSentenceTextToken length] > 1) {
            [objectsInvolved addObject:currentSentenceTextToken];
        }
    }
    
    NSDictionary *wordMapping = [self.delegate getWordMapping];
    NSMutableSet *convertedObjectsInvolved = [[NSMutableSet alloc] init];
    
    // Convert objects involved to the mapped keys if present
    for (NSString *objectInvolved in objectsInvolved) {
        BOOL present = FALSE;
        
        for (NSString *key in wordMapping.allKeys) {
            NSArray *mappedWords = [wordMapping objectForKey:key];
            
            if ([mappedWords containsObject:objectInvolved]) {
                present = TRUE;
                [convertedObjectsInvolved addObject:[key copy]];
                break;
            }
        }
        
        if (!present) {
            // Nothing to convert, so just use the word itself
            [convertedObjectsInvolved addObject:objectInvolved];
        }
    }
    
    return convertedObjectsInvolved;
}


- (BOOL)isDestDistanceBelowThreshold:(NSSet *)destinationIDs :(NSString *)correctDestinationID {
    
    CGPoint correctMovedObjectOrDestinationLocation = [self.delegate locationOfObject:correctDestinationID analyzer:self];
    
    // Found correct moved object or destination
    if (!CGPointEqualToPoint(correctMovedObjectOrDestinationLocation, CGPointZero)) {
        // Calculate size and rect of correct moved object or destination
        CGSize correctMovedObjectOrDestinationSize = [self.delegate sizeOfObject:correctDestinationID analyzer:self];
        CGRect correctMovedObjectOrDestinationRect = CGRectMake(correctMovedObjectOrDestinationLocation.x, correctMovedObjectOrDestinationLocation.y, correctMovedObjectOrDestinationSize.width, correctMovedObjectOrDestinationSize.height);
        
        // For each moved object or destination, compare its distance to the correct moved object or destination.
        for (NSString *movedObjectOrDestinationID in destinationIDs) {
            float distance = 0.0;
            
            // Calculate size and rect of moved object or destination
            CGPoint movedObjectOrDestinationLocation = [self.delegate locationOfObject:movedObjectOrDestinationID analyzer:self];
            CGSize movedObjectOrDestinationSize = [self.delegate sizeOfObject:movedObjectOrDestinationID analyzer:self];
            CGRect movedObjectOrDestinationRect = CGRectMake(movedObjectOrDestinationLocation.x, movedObjectOrDestinationLocation.y, movedObjectOrDestinationSize.width, movedObjectOrDestinationSize.height);
            
            NSLog(@"Calculcated values Destinations = %@ - %f, %@ - %f", destinationIDs, movedObjectOrDestinationRect.origin.x, correctDestinationID, correctMovedObjectOrDestinationRect.origin.x);
            
            // Calculate distance
            distance = distanceBetween(movedObjectOrDestinationRect, correctMovedObjectOrDestinationRect);
            
            if (distance <= DISTANCE_THRESHOLD) {
                return true;
            }
        }
    }
    
    return false;
}

- (BOOL)isInitialDistanceBelowThreshold:(NSSet *)movedObjectIds :(NSString *)correctObjToBeMovedID {
    CGPoint correctMovedObjectOrDestinationLocation = [self.delegate locationOfObject:correctObjToBeMovedID analyzer:self];
    
    // Found correct moved object or destination
    if (!CGPointEqualToPoint(correctMovedObjectOrDestinationLocation, CGPointZero)) {
        // Calculate size and rect of correct moved object or destination
        CGSize correctMovedObjectOrDestinationSize = [self.delegate sizeOfObject:correctObjToBeMovedID analyzer:self];
        CGRect correctMovedObjectOrDestinationRect = CGRectMake(correctMovedObjectOrDestinationLocation.x, correctMovedObjectOrDestinationLocation.y, correctMovedObjectOrDestinationSize.width, correctMovedObjectOrDestinationSize.height);
        
        // For each moved object or destination, compare its distance to the correct moved object or destination.
        for (NSString *movedObjectOrDestinationID in movedObjectIds) {
            float distance = 0.0;
            
            // Calculate size and rect of moved object or destination
            CGPoint movedObjectOrDestinationLocation = [self.delegate analyzerInitialPositionOfMovedObject:self];
            CGSize movedObjectOrDestinationSize = [self.delegate sizeOfObject:movedObjectOrDestinationID analyzer:self];
            CGRect movedObjectOrDestinationRect = CGRectMake(movedObjectOrDestinationLocation.x, movedObjectOrDestinationLocation.y, movedObjectOrDestinationSize.width, movedObjectOrDestinationSize.height);
            
            NSLog(@"Calculcated values Initials = %@ - %f, %@ - %f", movedObjectIds, movedObjectOrDestinationRect.origin.x, correctObjToBeMovedID, correctMovedObjectOrDestinationRect.origin.x);
            
            // Calculate distance
            distance = distanceBetween(movedObjectOrDestinationRect, correctMovedObjectOrDestinationRect);
            
            if (distance <= DISTANCE_THRESHOLD) {
                return true;
            }
        }
    }
    
    return false;
}

#pragma mark - Feedback

- (ErrorFeedback *)feedbackToShow {
    return _currentFeedback;
}


- (void)determineFeedbackToShow:(NSArray *)skills {
    
    BOOL containsSyntaxt = NO;
    BOOL containsVocab = NO;
    BOOL containsUsability = NO;
    
    // First check if the list contains any vocab or syntax errror.
    for (id object in skills) {
        if (containsSyntaxt == NO && [object isKindOfClass:[SyntaxSkill class]]) {
            containsSyntaxt = YES;
            
        } else if (containsVocab == NO && [object isKindOfClass:[WordSkill class]]) {
            containsVocab = YES;
            
        }  else if (containsUsability == NO && [object isKindOfClass:[UsabilitySkill class]]) {
            containsUsability = YES;
            
        }
        
    }
    
    NSString *mostProbError = [self determineMostProbableErrorTypeFromSkills:skills];
    ErrorFeedback *feedbackObjc = [[ErrorFeedback alloc] init];
    
    if ([mostProbError isEqualToString:@"vocabulary"]) {
        self.currentSentenceStatus.numOfVocabErrors++;
        if (self.currentSentenceStatus.numOfVocabErrors == 1) {
            feedbackObjc.feedbackType = EMFeedbackType_Highlight;
            feedbackObjc.skillType = SkillType_Vocab;
            
        } else if (self.currentSentenceStatus.numOfVocabErrors > 1) {
            feedbackObjc.feedbackType = EMFeedbackType_AutoComplete;
            feedbackObjc.skillType = SkillType_Vocab;
        }
        
        
    } else if ([mostProbError isEqualToString:@"syntax"]) {
        
        self.currentSentenceStatus.numOfSyntaxErrors++;
        if (self.currentSentenceStatus.numOfSyntaxErrors == 1) {
            feedbackObjc.feedbackType = EMFeedbackType_Highlight;
            feedbackObjc.skillType = SkillType_Syntax;
            
        } else if (self.currentSentenceStatus.numOfSyntaxErrors > 1) {
            feedbackObjc.feedbackType = EMFeedbackType_AutoComplete;
            feedbackObjc.skillType = SkillType_Syntax;
        }
        
        
    } else if ([mostProbError isEqualToString:@"usability"]) {
        
        self.currentSentenceStatus.numOfUsabilityErrors++;
        if (self.currentSentenceStatus.numOfUsabilityErrors > 1) {
            feedbackObjc.feedbackType = EMFeedbackType_AutoComplete;
            feedbackObjc.skillType = SkillType_Usability;
        }
        
    } else {
        
        // If syntax error is present and we have already encountered syntax error
        if (containsSyntaxt) {
            
            self.currentSentenceStatus.numOfSyntaxErrors++;
            feedbackObjc.skillType = SkillType_Syntax;
            if (self.currentSentenceStatus.numOfSyntaxErrors == 2) {
                feedbackObjc.feedbackType = EMFeedbackType_Highlight;
                
            } else if (self.currentSentenceStatus.numOfSyntaxErrors > 2){
                feedbackObjc.feedbackType = EMFeedbackType_AutoComplete;
                
            }
        }
        // If vocab error is present and we have already encountered vocab error
        else if (containsVocab ) {
            
            self.currentSentenceStatus.numOfVocabErrors++;
            feedbackObjc.skillType = SkillType_Vocab;
            
            if (self.currentSentenceStatus.numOfVocabErrors == 2) {
                feedbackObjc.feedbackType = EMFeedbackType_Highlight;
                
            } else if (self.currentSentenceStatus.numOfVocabErrors > 2) {
                feedbackObjc.feedbackType = EMFeedbackType_AutoComplete;
                
            }
        }
    }
    
    NSString *errorType = @"Nil";
    NSInteger errorCount = 0;
    NSString *feedback = @"Nil";
    
    if (feedbackObjc.skillType == SkillType_Syntax) {
        errorType = @"Syntax";
        errorCount = self.currentSentenceStatus.numOfSyntaxErrors;
        
    } else if (feedbackObjc.skillType == SkillType_Vocab) {
        errorType = @"Vocab";
        errorCount = self.currentSentenceStatus.numOfVocabErrors;
        
    } else if (feedbackObjc.skillType == SkillType_Syntax) {
        errorType = @"Usability";
        errorCount = self.currentSentenceStatus.numOfUsabilityErrors;
        
    }
    
    if (feedbackObjc.feedbackType == EMFeedbackType_AutoComplete) {
        feedback = @"AutoComplete";
    } else if (feedbackObjc.feedbackType == EMFeedbackType_Highlight) {
        feedback = @"Highlight";
        
    }
    NSLog(@" Error type = %@ || Error count = %d || Type of feedback = %@ ", errorType, errorCount, feedback);
    self.currentFeedback = feedbackObjc;
    
}


- (NSString *)determineMostProbableErrorTypeFromSkills:(NSArray *)skills {
    // Calculate overall values for each of the skills
    NSMutableArray *skillValues = [[NSMutableArray alloc] initWithObjects:@0.0, @0.0, @0.0, nil];
    
    int INDEX_VOCABULARY = 0;
    int INDEX_SYNTAX = 1;
    int INDEX_USABILITY = 2;
    
    int numVocabularySkills = 0;
    double sumVocabularySkills = 0.0;
    
    for (Skill *skill in skills) {
        if ([skill isKindOfClass:[WordSkill class]]) {
            numVocabularySkills++;
            sumVocabularySkills += [skill skillValue];
            [skillValues replaceObjectAtIndex:INDEX_VOCABULARY withObject:@(sumVocabularySkills / numVocabularySkills)];
        }
        else if ([skill isKindOfClass:[SyntaxSkill class]]) {
            [skillValues replaceObjectAtIndex:INDEX_SYNTAX withObject:@([skill skillValue])];
        }
        else if ([skill isKindOfClass:[UsabilitySkill class]]) {
            [skillValues replaceObjectAtIndex:INDEX_USABILITY withObject:@([skill skillValue])];
        }
    }
    
    double VOCABULARY_THRESHOLD = 0.5;
    double SYNTAX_THRESHOLD = 0.65;
    double USABILITY_THRESHOLD = 0.75;
    
    NSString * mostProbableErrorType = nil;
    double lowestSkillValue = 1.0;
    
    // Select the most probable error type from the lowest skill below its corresponding threshold
    for (int i = 0; i < [skillValues count]; i++) {
        double skillValue = [[skillValues objectAtIndex:i] doubleValue];
        
        if (skillValue > 0.0) {
            if (i == INDEX_VOCABULARY) {
                if (skillValue <= VOCABULARY_THRESHOLD && skillValue <= lowestSkillValue) {
                    mostProbableErrorType = @"vocabulary";
                    lowestSkillValue = skillValue;
                }
            }
            else if (i == INDEX_SYNTAX) {
                if (skillValue <= SYNTAX_THRESHOLD && skillValue <= lowestSkillValue) {
                    mostProbableErrorType = @"syntax";
                    lowestSkillValue = skillValue;
                }
            }
            else if (i == INDEX_USABILITY) {
                if (skillValue <= USABILITY_THRESHOLD && skillValue <= lowestSkillValue) {
                    mostProbableErrorType = @"usability";
                    lowestSkillValue = skillValue;
                }
            }
        }
    }
    
    NSLog(@"mostProbableErrorType: %@   lowestSkillValue: %f", mostProbableErrorType, lowestSkillValue);
    return mostProbableErrorType;
}

- (void)showMessageWith:(NSArray *)skills {
    NSMutableString *message = [NSMutableString stringWithFormat:@"Skills updated: \n"];
    
    for (Skill *sk in skills) {
        [message appendString:[NSString stringWithFormat:@"%@\n", [sk description]]];
    }
    
    [self showMessage:message];
}

- (void)showMessage:(NSString *)message {
    [self.delegate analyzer:self showMessage:message];
}

- (NSArray *)pronounsFor:(NSString *)word inBook:(NSString *)bookTitle {
    NSString *fileName = [bookTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSArray *result = nil;
    
    if (data) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (error)
            NSLog(@"JSONObjectWithData error: %@", error);
        
        NSDictionary *pronounDict = [dict objectForKey:@"pronouns"];
        result = [pronounDict objectForKey:word];
    }
    
    return result;
}

- (NSMutableDictionary *)bookDictionaryForTitle:(NSString *)bookTitle {
    NSMutableDictionary *actionDict = [self.booksDict objectForKey:bookTitle];
    
    if (actionDict == nil) {
        actionDict = [[NSMutableDictionary alloc]init];
        [self.booksDict setObject:actionDict forKey:bookTitle];
    }
    
    return actionDict;
}

- (SentenceStatus *)getActionListFrom:(NSMutableDictionary *)bookDetails forChapter:(NSString *)chapterTitle sentenceNumber:(NSInteger)sentenceNumber andIdeaNumber:(NSInteger)ideaNumber {
    NSString *sentenceKey = [NSString stringWithFormat:@"%@_%ld_%ld",chapterTitle, (long)sentenceNumber, (long)ideaNumber];
    
    // Get the sentence details from the book if present.
    SentenceStatus *statementDetails = [bookDetails objectForKey:sentenceKey];
    
    if (statementDetails == nil) {
        statementDetails = [SentenceStatus new];
        statementDetails.chapterTitle = chapterTitle;
        statementDetails.sentenceNumber = sentenceNumber;
        statementDetails.ideaNumber = ideaNumber;
        
        [bookDetails setObject:statementDetails forKey:sentenceKey];
    }
    
    return statementDetails;
}

- (float) distanceBetween:(CGPoint)p1 and:(CGPoint)p2 {
    return sqrt(pow(p2.x-p1.x,2) + pow(p2.y-p1.y,2));
}

float distanceBetween(CGRect rect1, CGRect rect2) {
    if (CGRectIntersectsRect(rect1, rect2)) {
        return 0;
    }
    
    CGRect mostLeft = rect1.origin.x < rect2.origin.x ? rect1 : rect2;
    CGRect mostRight = rect2.origin.x < rect1.origin.x ? rect1 : rect2;
    
    CGFloat xDifference = mostLeft.origin.x == mostRight.origin.x ? 0 : mostRight.origin.x - (mostLeft.origin.x + mostLeft.size.width);
    xDifference = MAX(0, xDifference);
    
    CGRect upper = rect1.origin.y < rect2.origin.y ? rect1 : rect2;
    CGRect lower = rect2.origin.y < rect1.origin.y ? rect1 : rect2;
    
    CGFloat yDifference = upper.origin.y == lower.origin.y ? 0 : lower.origin.y - (upper.origin.y + upper.size.height);
    yDifference = MAX(0, yDifference);
    
    float diff = sqrt(pow(yDifference,2) + pow(xDifference,2));
    
    return diff;
}

@end
