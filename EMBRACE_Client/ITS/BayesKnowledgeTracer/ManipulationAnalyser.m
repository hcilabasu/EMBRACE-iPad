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

@interface ManipulationAnalyser ()

@property (nonatomic, strong) KnowledgeTracer *knowledgeTracer;

// List of books that the user currently have read.
// Key: BookTitle Value: Dictionary
// Internal Dictionary contains the actions performed for each sentence
// Key : ChapterTitle_SentenceNumber Value: StatementStatus
@property (nonatomic, strong) NSMutableDictionary *booksDict;

@property (nonatomic, strong) NSMutableSet *playWords;

@property (nonatomic, strong) NSString *mostProbableErrorType;

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

- (void)userDidPlayWord:(NSString *)word context:(ManipulationContext *)context {
    [self.playWords addObject:word];
    
    NSMutableArray *skillList = [NSMutableArray array];
    Skill *movedSkill = [self.knowledgeTracer updateSkillFor:word isVerified:NO context:context];
    [skillList addObject:movedSkill];
    [self showMessageWith:skillList];
}

- (void)userDidVocabPreviewWord:(NSString *)word context:(ManipulationContext *)context {
    [self.playWords addObject:word];
    
    NSMutableArray *skillList = [NSMutableArray array];
    Skill *movedSkill = [self.knowledgeTracer updateSkillFor:word isVerified:YES context:context];
    [skillList addObject:movedSkill];
    [self showMessageWith:skillList];
}

- (NSMutableSet *)getRequestedVocab {
    return self.playWords;
}

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context forSentence:(NSString *)sentence isVerified:(BOOL)verified {
    // TODO
}

- (double)easySyntaxSkillValue {
    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Easy];
    
    return sk.skillValue;
}

- (double)medSyntaxSkillValue {
    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Medium];
    
    return sk.skillValue;
}

- (double)complexSyntaxSkillValue {
    Skill *sk = [self.knowledgeTracer syntaxSkillFor:EM_Complex];
    
    return sk.skillValue;
}

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
    SentenceStatus *status = [self getActionListFrom:bookDetails forChapter:context.chapterTitle sentenceNumber:context.sentenceNumber andIdeaNumber:context.ideaNumber];
    
    if ([status containsAction:userAction]) {
        // The sentence has been tried before
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:NO];
    }
    else {
        // First try by user
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:YES];
    }
    
    [status addUserAction:userAction];
}

- (void)analyzeAndUpdateSkill:(UserAction *)userAction andContext:(ManipulationContext *)context isFirstAttempt:(BOOL)isFirstAttempt {
    // Correct action
    if (userAction.isVerified) {
        NSMutableArray *skills = [NSMutableArray array];
        
        // Increase vocabulary skill for the object(s) moved
        for (NSString *movedObjectID in [userAction movedObjectIDs]) {
            Skill *wordSkill = [self.knowledgeTracer updateSkillFor:movedObjectID isVerified:YES shouldDampen:!isFirstAttempt context:context];
            [skills addObject:wordSkill];
        }
        
        NSString *correctDestinationID = [userAction correctDestinationID];
        
        // Increase vocabulary skill for the destination
        if (correctDestinationID != nil && ![correctDestinationID isEqualToString:@""]) {
            Skill *wordSkill = [self.knowledgeTracer updateSkillFor:correctDestinationID isVerified:YES shouldDampen:!isFirstAttempt context:context];
            [skills addObject:wordSkill];
        }
        
        // Increase syntax skill
        EMComplexity complexity = [self.delegate getComplexityForCurrentSentence:self];
        Skill *syntaxSkill = [self.knowledgeTracer updateSyntaxSkill:YES withComplexity:complexity shouldDampen:!isFirstAttempt context:context];
        [skills addObject:syntaxSkill];
        
        // Increase usability skill
        Skill *usabilitySkill = [self.knowledgeTracer updateUsabilitySkill:YES shouldDampen:!isFirstAttempt context:context];
        [skills addObject:usabilitySkill];
        
        [self showMessageWith:skills];
    }
    // Incorrect action
    else {
        // Determine what skills to adjust based on error
        [self updateSkillBasedOnMovedObject:userAction andContext:context isFirstAttempt:isFirstAttempt];
    }
}

- (void)updateSkillBasedOnMovedObject:(UserAction *)userAction andContext:(ManipulationContext *)context isFirstAttempt:(BOOL)isFirstAttempt {
    NSMutableArray *skills = [NSMutableArray array];
    
    // Get user action information
    NSSet *movedObjectIDs = [userAction movedObjectIDs];
    NSSet *destinationIDs = [userAction destinationIDs];
    NSString *correctMovedObjectID = [userAction correctMovedObjectID];
    NSString *correctDestinationID = [userAction correctDestinationID];
    
    // Check for syntax error
    // Mixed up order of subject and object
    if ([destinationIDs containsObject:correctMovedObjectID] && [movedObjectIDs containsObject:correctDestinationID]) {
        // Decrease syntax skill
        EMComplexity complexity = [self.delegate getComplexityForCurrentSentence:self];
        Skill *syntaxSkill = [self.knowledgeTracer updateSyntaxSkill:NO withComplexity:complexity shouldDampen:!isFirstAttempt context:context];
        [skills addObject:syntaxSkill];
        [self showMessageWith:skills];
        [self determineMostProbableErrorTypeFromSkills:skills];
        
        return;
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
                    EMComplexity complexity = [self.delegate getComplexityForCurrentSentence:self];
                    Skill *syntaxSkill = [self.knowledgeTracer updateSyntaxSkill:NO withComplexity:complexity shouldDampen:!isFirstAttempt context:context];
                    [skills addObject:syntaxSkill];
                    [self showMessageWith:skills];
                    [self determineMostProbableErrorTypeFromSkills:skills];
                    
                    return;
                }
            }
        }
    }
    
    Skill *usabilitySkill;
    
    // Check for vocabulary or usability errors
    // Moved incorrect object
    if (![movedObjectIDs containsObject:correctMovedObjectID]) {
        // Vocabulary error
        if (![self isDistanceBelowThreshold:movedObjectIDs :correctMovedObjectID]) {
            // Decrease vocabulary skills for the moved objects
            for (NSString *movedObjectID in movedObjectIDs) {
                Skill *wordSkill = [self.knowledgeTracer updateSkillFor:movedObjectID isVerified:NO shouldDampen:!isFirstAttempt context:context];
                [skills addObject:wordSkill];
            }
            
            // Decrease vocabulary skill for the correct object to move
            Skill *wordSkill = [self.knowledgeTracer updateSkillFor:correctMovedObjectID isVerified:NO shouldDampen:!isFirstAttempt context:context];
            [skills addObject:wordSkill];
        }
        // Usability error
        else {
            // Decrease usability skill
            usabilitySkill = [self.knowledgeTracer updateUsabilitySkill:NO shouldDampen:!isFirstAttempt context:context];
        }
    }
    // Moved correct object
    else {
        for (NSString *movedObjectID in movedObjectIDs) {
            // Increase vocabulary skill for the moved object
            Skill *wordSkill = [self.knowledgeTracer updateSkillFor:movedObjectID isVerified:YES shouldDampen:!isFirstAttempt context:context];
            [skills addObject:wordSkill];
        }
    }
    
    // Check for vocabulary or usability errors
    // Vocabulary error
    if ([destinationIDs count] == 0) {
        // Decrease vocabulary error for the correct destination
        Skill *wordSkill = [self.knowledgeTracer updateSkillFor:correctDestinationID isVerified:NO shouldDampen:!isFirstAttempt context:context];
        [skills addObject:wordSkill];
    }
    // Moved to incorrect destination
    else if (![destinationIDs containsObject:correctDestinationID]) {
        // Vocabulary error
        if (![self isDistanceBelowThreshold:destinationIDs :correctDestinationID]) {
            // Decrease vocabulary skills for the destinations
            for (NSString *destinationID in destinationIDs) {
                Skill *wordSkill = [self.knowledgeTracer updateSkillFor:destinationID isVerified:NO shouldDampen:!isFirstAttempt context:context];
                [skills addObject:wordSkill];
            }
            
            // Decrease vocabulary skill for the correct destination
            Skill *wordSkill = [self.knowledgeTracer updateSkillFor:correctDestinationID isVerified:NO shouldDampen:!isFirstAttempt context:context];
            [skills addObject:wordSkill];
        }
        // Usability error
        else {
            // Decrease usability skill
            usabilitySkill = [self.knowledgeTracer updateUsabilitySkill:NO shouldDampen:!isFirstAttempt context:context];
        }
    }
    // Moved to correct destination
    else {
        // Increase vocabulary skill for the destination
        Skill *wordSkill = [self.knowledgeTracer updateSkillFor:correctDestinationID isVerified:YES shouldDampen:!isFirstAttempt context:context];
        [skills addObject:wordSkill];
    }
    
    // Add usability skill if it was updated
    if (usabilitySkill != nil) {
        [skills addObject:usabilitySkill];
    }
    
    [self showMessageWith:skills];
    [self determineMostProbableErrorTypeFromSkills:skills];
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
    
    return objectsInvolved;
}

- (BOOL)isDistanceBelowThreshold:(NSSet *)movedObjectOrDestinationIDs :(NSString *)correctMovedObjectOrDestinationID {
    CGPoint correctMovedObjectOrDestinationLocation = [self.delegate locationOfObject:correctMovedObjectOrDestinationID analyzer:self];
    
    // Found correct moved object or destination
    if (!CGPointEqualToPoint(correctMovedObjectOrDestinationLocation, CGPointZero)) {
        // Calculate size and rect of correct moved object or destination
        CGSize correctMovedObjectOrDestinationSize = [self.delegate sizeOfObject:correctMovedObjectOrDestinationID analyzer:self];
        CGRect correctMovedObjectOrDestinationRect = CGRectMake(correctMovedObjectOrDestinationLocation.x, correctMovedObjectOrDestinationLocation.y, correctMovedObjectOrDestinationSize.width, correctMovedObjectOrDestinationSize.height);
        
        // For each moved object or destination, compare its distance to the correct moved object or destination.
        for (NSString *movedObjectOrDestinationID in movedObjectOrDestinationIDs) {
            float distance = 0.0;
            
            // Calculate size and rect of moved object or destination
            CGPoint movedObjectOrDestinationLocation = [self.delegate locationOfObject:movedObjectOrDestinationID analyzer:self];
            CGSize movedObjectOrDestinationSize = [self.delegate sizeOfObject:movedObjectOrDestinationID analyzer:self];
            CGRect movedObjectOrDestinationRect = CGRectMake(movedObjectOrDestinationLocation.x, movedObjectOrDestinationLocation.y, movedObjectOrDestinationSize.width, movedObjectOrDestinationSize.height);
            
            // Calculate distance
            distance = distanceBetween(movedObjectOrDestinationRect, correctMovedObjectOrDestinationRect);
            
            if (distance <= DISTANCE_THRESHOLD) {
                return true;
            }
        }
    }
    
    return false;
}

- (NSString *)getMostProbableErrorType {
    return [self mostProbableErrorType];
}

- (void)determineMostProbableErrorTypeFromSkills:(NSMutableArray *)skills {
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
    double SYNTAX_THRESHOLD = 0.5;
    double USABILITY_THRESHOLD = 0.5;
    
    self.mostProbableErrorType = nil;
    double lowestSkillValue = 1.0;
    
    // Select the most probable error type from the lowest skill below its corresponding threshold
    for (int i = 0; i < [skillValues count]; i++) {
        double skillValue = [[skillValues objectAtIndex:i] doubleValue];
        
        if (skillValue > 0.0) {
            if (i == INDEX_VOCABULARY) {
                if (skillValue <= VOCABULARY_THRESHOLD && skillValue <= lowestSkillValue) {
                    self.mostProbableErrorType = @"vocabulary";
                    lowestSkillValue = skillValue;
                }
            }
            else if (i == INDEX_SYNTAX) {
                if (skillValue <= SYNTAX_THRESHOLD && skillValue <= lowestSkillValue) {
                    self.mostProbableErrorType = @"syntax";
                    lowestSkillValue = skillValue;
                }
            }
            else if (i == INDEX_USABILITY) {
                if (skillValue <= USABILITY_THRESHOLD && skillValue <= lowestSkillValue) {
                    self.mostProbableErrorType = @"usability";
                    lowestSkillValue = skillValue;
                }
            }
        }
    }
    
    NSLog(@"mostProbableErrorType: %@   lowestSkillValue: %f", self.mostProbableErrorType, lowestSkillValue);
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
