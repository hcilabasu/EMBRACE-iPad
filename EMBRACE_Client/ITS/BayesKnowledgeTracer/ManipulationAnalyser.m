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

- (void)userDidPlayWord:(NSString *)word {
    [self.playWords addObject:word];
    
    NSMutableArray *skillList = [NSMutableArray array];
    
    Skill *movedSkill = [self.knowledgeTracer updateSkillFor:word isVerified:NO];
    [skillList addObject:movedSkill];
    [self showMessageWith:skillList];
    
}

- (void)userDidVocabPreviewWord:(NSString *)word {
    [self.playWords addObject:word];
    
    NSMutableArray *skillList = [NSMutableArray array];
    
    Skill *movedSkill = [self.knowledgeTracer updateSkillFor:word isVerified:YES];
    [skillList addObject:movedSkill];
    [self showMessageWith:skillList];
}

- (NSMutableSet *)getRequestedVocab {
    return self.playWords;
}

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context
                               forSentence:(NSString *)sentence
                                isVerified:(BOOL)verified {
    
    
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
    
    NSString *bookTitle = context.bookTitle;
    NSMutableDictionary *bookDetails = [self bookDictionaryForTitle:bookTitle];
    SentenceStatus *status = [self getActionListFrom:bookDetails
                                          forChapter:context.chapterTitle
                                      sentenceNumber:context.sentenceNumber
                                       andIdeaNumber:context.ideaNumber];
    
    NSLog(@"Action performed for %@ %@ %d", bookTitle,context.chapterTitle, context.sentenceNumber);
    
    
    if ([status containsAction:userAction]) {
        // The sentence has been tried before
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:NO];
    } else {
        // First try by user
        [self analyzeAndUpdateSkill:userAction andContext:context isFirstAttempt:YES];
    }
    [status addUserAction:userAction];
    
}


- (void)analyzeAndUpdateSkill:(UserAction *)userAction
                   andContext:(ManipulationContext *)context
               isFirstAttempt:(BOOL)isFirstAttempt {
    
    NSLog(@"Book Title - %@", [context.bookTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"]);
    
    if (userAction.isVerified) {
        
        NSMutableArray *skillList = [NSMutableArray array];
        
        // Update the two object's skills
        Skill *movedSkill = [self.knowledgeTracer
                             updateSkillFor:userAction.movedObjectId
                             isVerified:YES
                             shouldDampen:!isFirstAttempt];
        [skillList addObject:movedSkill];
        
        Skill *destSkill = nil;
        if (userAction.actionStepDestinationObjectId && ![userAction.actionStepDestinationObjectId isEqualToString:@""]) {
            destSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStepDestinationObjectId
                                                  isVerified:YES
                                                shouldDampen:!isFirstAttempt];
            [skillList addObject:destSkill];
        }
        
        // Update the syntax and usability skill
        EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *synSkill = [self.knowledgeTracer updateSyntaxSkill:YES
                                                   withComplexity:com
                                                     shouldDampen:!isFirstAttempt];
        [skillList addObject:synSkill];
        Skill *useSkill = [self.knowledgeTracer updateUsabilitySkill:YES
                                                        shouldDampen:!isFirstAttempt];
        [skillList addObject:useSkill];
        
        [self showMessageWith:skillList];
        
        
    } else {
        
        // If the action is not verified, find out the kind of error the user made.
        //
        [self updateSkillBasedOnMovedObject:userAction
                                 andContext:context
                             isFirstAttempt:isFirstAttempt];
    }
}

- (void)updateSkillBasedOnMovedObject:(UserAction *)userAction
                           andContext:(ManipulationContext *)context
                       isFirstAttempt:(BOOL)isFirstAttempt {
    
    NSMutableArray *skills = [NSMutableArray array];
    
    // Check for syntax error
    // Check if the student mixed up subject and object
    if ([userAction.destinationObjectId isEqualToString:userAction.actionStepMovedObjectId] &&
        [userAction.movedObjectId isEqualToString:userAction.actionStepDestinationObjectId]) {
        
        NSLog(@"Mixed up objects");
        EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                withComplexity:com
                                                  shouldDampen:!isFirstAttempt];
        
        [skills addObject:skill];
        [self showMessageWith:skills];
        [self determineMostProbableErrorTypeFromSkills:skills];
        return;
    } else {
        // Check if the user preformed a future step
        //
        NSArray *nextSteps = [self.delegate getNextStepsForCurrentSentence:self];
        for (ActionStep *nextStep in nextSteps) {
            
            
            
            NSString *correctDest = nil;
            if (nextStep.object2Id != nil) {
                correctDest = nextStep.object2Id;
                
            } else if (nextStep.locationId != nil) {
                correctDest = nextStep.locationId;
                
            } else if (nextStep.areaId != nil) {
                correctDest = nextStep.areaId;
            }
            
            // Check if any of the step uses 
            if (([nextStep.object1Id isEqualToString:userAction.movedObjectId] &&
                [correctDest isEqualToString:userAction.destinationObjectId] )||
                
                ([nextStep.object1Id isEqualToString:userAction.destinationObjectId] &&
                [correctDest isEqualToString:userAction.movedObjectId])) {
                NSLog(@"Performed a future step");
                
                EMComplexity com = [self.delegate analyzer:self
                                  getComplexityForSentence:context.sentenceNumber];
                Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                        withComplexity:com
                                                          shouldDampen:!isFirstAttempt];
                [skills addObject:skill];
                [self showMessageWith:skills];
                [self determineMostProbableErrorTypeFromSkills:skills];
                return;
            }
        }
        
        
    }
    
    // Moved incorrect subject
    if (![userAction.movedObjectId isEqualToString:userAction.actionStepMovedObjectId]) {
        
        CGPoint movedFromLocation = [self.delegate locationOfObject:userAction.movedObjectId
                                                           analyzer:self];
        CGPoint actualLocation = [self.delegate locationOfObject:userAction.actionStepMovedObjectId
                                                        analyzer:self];
        CGSize firstObjectSize = [self.delegate sizeOfObject:userAction.movedObjectId
                                                    analyzer:self];
        CGSize secondObjectSize = [self.delegate sizeOfObject:userAction.actionStepMovedObjectId
                                                     analyzer:self];
        
        CGRect firstRect = CGRectMake(movedFromLocation.x, movedFromLocation.y, firstObjectSize.width, firstObjectSize.height);
        CGRect secondRect = CGRectMake(actualLocation.x, actualLocation.y, secondObjectSize.width, secondObjectSize.height);
        
        float distance = distanceBetween(firstRect, secondRect);
        
        if (distance > DISTANCE_THRESHOLD) {
            // Vocabulary error
            Skill *movedSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId
                                                          isVerified:NO
                                                        shouldDampen:!isFirstAttempt];
            
            Skill *actionObjSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStepMovedObjectId
                                                              isVerified:NO
                                                            shouldDampen:!isFirstAttempt];
            
            [skills addObject:movedSkill];
            [skills addObject:actionObjSkill];
        } else {
            // Usability error
            Skill *skill = [self.knowledgeTracer updateUsabilitySkill:NO
                                                         shouldDampen:!isFirstAttempt];
            [skills addObject:skill];
        }
    } else {
        Skill *skill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId
                                                 isVerified:YES
                                               shouldDampen:!isFirstAttempt];
        [skills addObject:skill];
    }
    
    NSString *correctDest = userAction.actionStepDestinationObjectId;
    
    // If user action destination is nil, it means user doesnot know the object
    // so update the vocab skill for the object.
    if (userAction.destinationObjectId == nil) {
        Skill *skill = [self.knowledgeTracer updateSkillFor:correctDest isVerified:NO
                                               shouldDampen:!isFirstAttempt];
        [skills addObject:skill];
        
    } else if (![userAction.destinationObjectId isEqualToString:correctDest]) {
        
        CGPoint movedFromLocation = [self.delegate locationOfObject:userAction.destinationObjectId
                                                           analyzer:self];
        CGPoint actualLocation = [self.delegate locationOfObject:correctDest
                                                        analyzer:self];
        
        CGSize firstObjectSize = [self.delegate sizeOfObject:userAction.destinationObjectId
                                                    analyzer:self];
        CGSize secondObjectSize = [self.delegate sizeOfObject:correctDest
                                                     analyzer:self];
        
        CGRect firstRect = CGRectMake(movedFromLocation.x, movedFromLocation.y, firstObjectSize.width, firstObjectSize.height);
        CGRect secondRect = CGRectMake(actualLocation.x, actualLocation.y, secondObjectSize.width, secondObjectSize.height);
        
        
        float distance = distanceBetween(firstRect, secondRect);
        if (distance > DISTANCE_THRESHOLD) {
            // Vocabulary error
            Skill *destObjSkill = [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId
                                                            isVerified:NO
                                                          shouldDampen:!isFirstAttempt];
            
            Skill *actualDestSkill = [self.knowledgeTracer updateSkillFor:correctDest
                                                               isVerified:NO
                                                             shouldDampen:!isFirstAttempt];
            
            [skills addObject:destObjSkill];
            [skills addObject:actualDestSkill];
            
        } else {
            // Usability error
            Skill *skill = [self.knowledgeTracer updateUsabilitySkill:NO
                                                         shouldDampen:!isFirstAttempt];
            [skills addObject:skill];
        }
    } else {
        Skill *skill = [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId
                                                 isVerified:YES
                                               shouldDampen:!isFirstAttempt];
        [skills addObject:skill];
    }
    [self showMessageWith:skills];
    [self determineMostProbableErrorTypeFromSkills:skills];
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
    
    // Determine the most probable error type from the lowest skill value
    NSString *mostProbableErrorType;
    double lowestSkillValue = [[skillValues firstObject] doubleValue];
    
    for (int i = 0; i < [skillValues count]; i++) {
        double skillValue = [[skillValues objectAtIndex:i] doubleValue];
        
        if (skillValue > 0.0 && skillValue <= lowestSkillValue) {
            lowestSkillValue = skillValue;
            
            if (i == INDEX_VOCABULARY) {
                mostProbableErrorType = @"vocabulary";
            }
            else if (i == INDEX_SYNTAX) {
                mostProbableErrorType = @"syntax";
            }
            else if (i == INDEX_USABILITY) {
                mostProbableErrorType = @"usability";
            }
        }
    }
    
    self.mostProbableErrorType = nil;
    
    // Set the most probable error type if the skill value is below the threshold
    if ([mostProbableErrorType isEqualToString:@"vocabulary"]) {
        double VOCABULARY_THRESHOLD = 0.5;
        
        if (lowestSkillValue <= VOCABULARY_THRESHOLD) {
            self.mostProbableErrorType = @"vocabulary";
        }
    }
    else if ([mostProbableErrorType isEqualToString:@"syntax"]) {
        double SYNTAX_THRESHOLD = 0.5;
        
        if (lowestSkillValue <= SYNTAX_THRESHOLD) {
            self.mostProbableErrorType = @"syntax";
        }
    }
    else if ([mostProbableErrorType isEqualToString:@"usability"]) {
        double USABILITY_THRESHOLD = 0.5;
        
        if (lowestSkillValue <= USABILITY_THRESHOLD) {
            self.mostProbableErrorType = @"usability";
        }
    }
    
    NSLog(@"*** lowestSkillValue: %f", lowestSkillValue);
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
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
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

- (SentenceStatus *)getActionListFrom:(NSMutableDictionary *)bookDetails
                           forChapter:(NSString *)chapterTitle
                       sentenceNumber:(NSInteger)sentenceNumber
                        andIdeaNumber:(NSInteger)ideaNumber {
    
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

- (float) distanceBetween:(CGPoint)p1
                      and:(CGPoint)p2 {
    
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
    NSLog(@"%f", diff);
    
    return diff;
}


@end
