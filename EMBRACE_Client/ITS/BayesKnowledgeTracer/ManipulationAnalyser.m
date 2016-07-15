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

// TODO: Figure out whether the error is due to Syntax, usability
// pronoun
// Syntax can have 3 values - complex, med, easy
- (void)analyzeAndUpdateSkill:(UserAction *)userAction
                   andContext:(ManipulationContext *)context {
    
    NSLog(@"Book Title - %@", [context.bookTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"]);
    
    if (userAction.isVerified) {
        
        // Update the two object's skills
        [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
        
        if (userAction.actionStep.object2Id && ![userAction.actionStep.object2Id isEqualToString:@""]) {
            [self.knowledgeTracer updateSkillFor:userAction.actionStep.object2Id isVerified:YES];
            
        } else if (userAction.actionStep.locationId &&
                   ![userAction.actionStep.locationId isEqualToString:@""]) {
            
            [self.knowledgeTracer updateSkillFor:userAction.actionStep.locationId isVerified:YES];
        }
        
        // Update the syntax and usability skill
        [self.knowledgeTracer updateSyntaxSkill:YES];
        [self.knowledgeTracer updateUsabilitySkill:YES];
        
    } else {
        
        // If the action is not verified, find out the kind of error the user made.
        if (userAction.movedObjectId && userAction.destinationObjectId) {
            [self updateSkillBasedOnMovedObject:userAction
                                     andContext:context];
            
        }
    }
}

- (void)updateSkillBasedOnMovedObject:(UserAction *)userAction
                           andContext:(ManipulationContext *)context  {
    
    // Check for syntax error
    // Check if the student mixed up subject and object
    if ([userAction.destinationObjectId isEqualToString:userAction.actionStep.object1Id] &&
        [userAction.movedObjectId isEqualToString:userAction.actionStep.object2Id]) {
        
        NSLog(@"Mixed up objects");
        [self.knowledgeTracer updateSyntaxSkill:NO];
        return;
    } else {
        //TODO: Check if the user performed a later step
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
            [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:NO];
            
        } else {
            // Usability error
            [self.knowledgeTracer updateUsabilitySkill:NO];
        }
    } else {
        [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
    }
    
    NSString *correctDest = nil;
    if (userAction.actionStep.object2Id != nil) {
        correctDest = userAction.actionStep.object2Id;
        
    } else if (userAction.actionStep.locationId != nil) {
        correctDest = userAction.actionStep.locationId;
        
    } else if (userAction.actionStep.areaId != nil) {
        correctDest = userAction.actionStep.areaId;
    }
    
    
    if (![userAction.destinationObjectId isEqualToString:correctDest]) {
       
        CGPoint movedFromLocation = [self.delegate locationOfObject:userAction.destinationObjectId
                                                           analyzer:self];
        CGPoint actualLocation = [self.delegate locationOfObject:userAction.actionStep.object2Id
                                                        analyzer:self];
        float distance = [self distanceBetween:movedFromLocation
                                           and:actualLocation];
        if (distance > DISTANCE_THRESHOLD) {
            // Vocabulary error
            [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId isVerified:NO];
            
        } else {
            // Usability error
            [self.knowledgeTracer updateUsabilitySkill:NO];
        }
    } else {
        [self.knowledgeTracer updateSkillFor:userAction.destinationObjectId isVerified:YES];
    }
}


- (void)updateSkillForObject:(NSString *)objectId
               correctObject:(NSString *)correctObjectId
                 forSentence:(NSString *)sentence
                 inBookTitle:(NSString *)bookTitle {
    
    // Object was correct
    if ([objectId isEqualToString:correctObjectId]) {
        [self.knowledgeTracer updateSkillFor:objectId isVerified:YES];
        
    } else {
        
        [self.knowledgeTracer updateSkillFor:objectId isVerified:NO];
        
        // Check if the sentence has any pronoun
        NSArray *pronouns = [self pronounsFor:objectId inBook:[bookTitle lowercaseString]];
        if (pronouns) {
            sentence = [sentence lowercaseString];
            for (NSString *word in pronouns) {
                if ([sentence containsString:word]) {
                    [self.knowledgeTracer updatePronounSkill:NO];
                    break;
                }
            }
        }
        
    }
    
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
