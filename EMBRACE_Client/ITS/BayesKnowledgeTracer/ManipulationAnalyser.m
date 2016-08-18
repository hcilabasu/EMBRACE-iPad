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

#define DISTANCE_THRESHOLD 150

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
        
        // Update the two object's skills
        Skill *movedSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
        Skill *destSkill = nil;
        if (userAction.actionStep.object2Id && ![userAction.actionStep.object2Id isEqualToString:@""]) {
           destSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStep.object2Id isVerified:YES];
            
        } else if (userAction.actionStep.locationId &&
                   ![userAction.actionStep.locationId isEqualToString:@""]) {
            
            destSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStep.locationId isVerified:YES];
        }
        
        // Update the syntax and usability skill
        NSUInteger com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *synSkill = [self.knowledgeTracer updateSyntaxSkill:YES
                                                                    withComplexity:com];
        Skill *useSkill = [self.knowledgeTracer updateUsabilitySkill:YES];
        [self showMessageWith:@[movedSkill,destSkill,synSkill,useSkill]];
        
        
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
    if ([userAction.destinationObjectId isEqualToString:userAction.actionStep.object1Id] &&
        [userAction.movedObjectId isEqualToString:userAction.actionStep.object2Id]) {
        
        NSLog(@"Mixed up objects");
        NSUInteger com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
        Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                                    withComplexity:com];
        
        [skills addObject:skill];
        [self showMessageWith:skills];
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
                
                if ([nextStep.object1Id isEqualToString:userAction.movedObjectId] &&
                    [correctDest isEqualToString:userAction.destinationObjectId]) {
                    NSLog(@"Performed a future step");
                    
                    NSUInteger com = [self.delegate analyzer:self getComplexityForSentence:context.sentenceNumber];
                    Skill *skill = [self.knowledgeTracer updateSyntaxSkill:NO
                                                            withComplexity:com];
                    [skills addObject:skill];
                    [self showMessageWith:skills];
                    return;
                }
                
            
            
            
        }
        
    }
    
    // Moved incorrect subject
    if (![userAction.movedObjectId isEqualToString:userAction.actionStep.object1Id]) {
        
        CGPoint movedFromLocation = [self.delegate locationOfObject:userAction.movedObjectId
                                                           analyzer:self];
        CGPoint actualLocation = [self.delegate locationOfObject:userAction.actionStep.object1Id
                                                        analyzer:self];
        float distance = [self distanceBetween:movedFromLocation
                                                 and:actualLocation];
        
        if (distance > DISTANCE_THRESHOLD) {
            // Vocabulary error
           Skill *movedSkill = [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:NO];
           Skill *actionObjSkill = [self.knowledgeTracer updateSkillFor:userAction.actionStep.object1Id isVerified:NO];
            
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
    
    NSString *correctDest = nil;
    if (userAction.actionStep.object2Id != nil) {
        correctDest = userAction.actionStep.object2Id;
        
    } else if (userAction.actionStep.locationId != nil) {
        correctDest = userAction.actionStep.locationId;
        
    } else if (userAction.actionStep.areaId != nil) {
        correctDest = userAction.actionStep.areaId;
    }
    
    // If user action destination is nil, it means user doesnot know the object
    // so update the vocab skill for the object.
    if (userAction.destinationObjectId == nil) {
        Skill *skill = [self.knowledgeTracer updateSkillFor:correctDest isVerified:NO];
        [skills addObject:skill];
        
    } else if (![userAction.destinationObjectId isEqualToString:correctDest]) {
       
        CGPoint movedFromLocation = [self.delegate locationOfObject:userAction.destinationObjectId
                                                           analyzer:self];
        CGPoint actualLocation = [self.delegate locationOfObject:userAction.actionStep.object2Id
                                                        analyzer:self];
        float distance = [self distanceBetween:movedFromLocation
                                           and:actualLocation];
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
@end
