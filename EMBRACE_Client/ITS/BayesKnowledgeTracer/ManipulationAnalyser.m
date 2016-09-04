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

#define DISTANCE_THRESHOLD 90

@interface ManipulationAnalyser ()

@property (nonatomic, strong) KnowledgeTracer *knowledgeTracer;

// List of books that the user currently have read.
// Key: BookTitle Value: Dictionary
// Internal Dictionary contains the actions performed for each sentence
// Key : ChapterTitle_SentenceNumber Value: StatementStatus
@property (nonatomic, strong) NSMutableDictionary *booksDict;

@property (nonatomic, strong) NSMutableSet *playWords;

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
    
    
    NSString *bookTitle = context.bookTitle;
    NSMutableDictionary *bookDetails = [self bookDictionaryForTitle:bookTitle];
    SentenceStatus *status = [self getActionListFrom:bookDetails
                                          forChapter:context.chapterTitle
                                      sentenceNumber:context.sentenceNumber
                                             andStep:context.stepNumber];
    
    NSLog(@"Action performed for %@ %@ %d", bookTitle,context.chapterTitle, context.sentenceNumber);
    
    [self analyzeAndUpdateSkill:userAction andContext:context];
    if ([status containsAction:userAction]) {
        // The sentence has been tried before
        
    } else {
        // First try by user
    }
    [status addUserAction:userAction];
    
}


- (void)analyzeAndUpdateSkill:(UserAction *)userAction
                   andContext:(ManipulationContext *)context {
   
    NSLog(@"Book Title - %@", [context.bookTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"]);
    
    if (userAction.isVerified) {
        
        NSMutableArray *skillList = [NSMutableArray array];
        
        // Update the two object's skills
        Skill *movedSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
        [skillList addObject:movedSkill];
        
        Skill *destSkill = nil;
        if (userAction.actionStepDestinationObjectId && ![userAction.actionStepDestinationObjectId isEqualToString:@""]) {
           destSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStepDestinationObjectId isVerified:YES];
            [skillList addObject:destSkill];
        }
        
        // Update the syntax and usability skill
        EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *synSkill = [self.knowledgeTracer updateSyntaxSkill:YES
                                                                    withComplexity:com];
        [skillList addObject:synSkill];
        Skill *useSkill = [self.knowledgeTracer updateUsabilitySkill:YES];
        [skillList addObject:useSkill];
        
        [self showMessageWith:skillList];
        
        
    } else {
        
        // If the action is not verified, find out the kind of error the user made.
       
        [self updateSkillBasedOnMovedObject:userAction
                                 andContext:context];
            
        
    }
}

- (void)updateSkillBasedOnMovedObject:(UserAction *)userAction
                           andContext:(ManipulationContext *)context  {
    
    NSMutableArray *skills = [NSMutableArray array];
    
    // Check for syntax error
    // Check if the student mixed up subject and object
    if ([userAction.destinationObjectId isEqualToString:userAction.actionStepMovedObjectId] &&
        [userAction.movedObjectId isEqualToString:userAction.actionStepDestinationObjectId]) {
        
        NSLog(@"Mixed up objects");
        EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                                    withComplexity:com];
        
        [skills addObject:skill];
        [self showMessageWith:skills];
        return;
    } else {
        // Check if the user preformed a future step
        //
//        NSArray *nextSteps = [self.delegate getNextStepsForCurrentSentence:self];
//        for (ActionStep *nextStep in nextSteps) {
//            
//            
//                
//                NSString *correctDest = nil;
//                if (nextStep.object2Id != nil) {
//                    correctDest = nextStep.object2Id;
//                    
//                } else if (nextStep.locationId != nil) {
//                    correctDest = nextStep.locationId;
//                    
//                } else if (nextStep.areaId != nil) {
//                    correctDest = nextStep.areaId;
//                }
//                
//                if ([nextStep.object1Id isEqualToString:userAction.movedObjectId] &&
//                    [correctDest isEqualToString:userAction.destinationObjectId]) {
//                    NSLog(@"Performed a future step");
//                    
//                    EMComplexity com = [self.delegate analyzer:self
//                                      getComplexityForSentence:context.sentenceNumber];
//                    Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
//                                                            withComplexity:com];
//                    [skills addObject:skill];
//                    [self showMessageWith:skills];
//                    return;
//                }
//                
//            
//            
//            
//        }
        
//        // Check if one of the step is correct
//        //
//        if ([userAction.movedObjectId isEqualToString:userAction.actionStep.object1Id] &&
//            ![userAction.destinationObjectId isEqualToString:userAction.actionStep.object2Id]) {
//            
//            NSLog(@"Subject is wrong");
//            EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
//            Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
//                                                    withComplexity:com];
//            Skill *objSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
//            
//            [skills addObject:skill];
//            [skills addObject:objSkill];
//            [self showMessageWith:skills];
//            return;
//        }
        
        if (![userAction.movedObjectId isEqualToString:userAction.actionStepMovedObjectId] &&
            [userAction.destinationObjectId isEqualToString:userAction.actionStepDestinationObjectId]) {
            
            NSLog(@"Object is wrong");
            EMComplexity com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
            Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                    withComplexity:com];
            Skill *objSkill = [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId isVerified:YES];
            
            [skills addObject:skill];
            [skills addObject:objSkill];
            [self showMessageWith:skills];
            return;
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
           Skill *movedSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:NO];
           Skill *actionObjSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStepMovedObjectId isVerified:NO];
            
            [skills addObject:movedSkill];
            [skills addObject:actionObjSkill];
        } else {
            // Usability error
            Skill *skill = [self.knowledgeTracer updateUsabilitySkill:NO];
            [skills addObject:skill];
        }
    } else {
        Skill *skill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
        [skills addObject:skill];
    }
    
    NSString *correctDest = userAction.actionStepDestinationObjectId;
    
    // If user action destination is nil, it means user doesnot know the object
    // so update the vocab skill for the object.
    if (userAction.destinationObjectId == nil) {
        Skill *skill = [self.knowledgeTracer updateSkillFor:correctDest isVerified:NO];
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
            Skill *destObjSkill = [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId isVerified:NO];
            Skill *actualDestSkill = [self.knowledgeTracer updateSkillFor:correctDest isVerified:NO];
            
            [skills addObject:destObjSkill];
            [skills addObject:actualDestSkill];
            
        } else {
            // Usability error
            Skill *skill = [self.knowledgeTracer updateUsabilitySkill:NO];
            [skills addObject:skill];
        }
    } else {
        Skill *skill = [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId isVerified:YES];
        [skills addObject:skill];
    }
    [self showMessageWith:skills];
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
                              andStep:(NSInteger)stepNumber {
    
    NSString *sentenceKey = [NSString stringWithFormat:@"%@_%ld_%ld",chapterTitle, (long)sentenceNumber, (long)stepNumber];
    SentenceStatus *statementDetails = [bookDetails objectForKey:sentenceKey];
    if (statementDetails == nil) {
        statementDetails = [SentenceStatus new];
        statementDetails.chapterTitle = chapterTitle;
        statementDetails.sentenceNumber = sentenceNumber;
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
