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
- (void)analyzeAndUpdateSkill:(UserAction *)userAction
                   andContext:(ManipulationContext *)context {
    
    NSLog(@"Book Title - %@", [context.bookTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"]);
    
    if (userAction.isVerified) {
        
        // Update the two object's skills
        [self.knowledgeTracer updateSkillFor:userAction.movedObjectId isVerified:YES];
        
        if (userAction.actionStep.object2Id && ![userAction.actionStep.object2Id isEqualToString:@""]) {
            [self.knowledgeTracer updateSkillFor:userAction.actionStep.object2Id isVerified:YES];
            
        } else if (userAction.actionStep.locationId && ![userAction.actionStep.locationId isEqualToString:@""]) {
            [self.knowledgeTracer updateSkillFor:userAction.actionStep.locationId isVerified:YES];
        }
        // Update the syntax skill
        [self.knowledgeTracer updateSyntaxSkill:YES];
        
    } else {
        
        [self.knowledgeTracer updateSyntaxSkill:NO];
        
        // If the action is not verified, find out the kind of error the user made.
        if (userAction.movedObjectId && userAction.destinationObjectId) {
            
            [self updateSkillForObject:userAction.movedObjectId
                         correctObject:userAction.actionStep.object1Id
                           forSentence:userAction.sentenceText
                           inBookTitle:context.bookTitle];
            
            [self updateSkillForObject:userAction.destinationObjectId
                         correctObject:userAction.actionStep.object2Id
                           forSentence:userAction.sentenceText
                           inBookTitle:context.bookTitle];
            
        }
        
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

@end
