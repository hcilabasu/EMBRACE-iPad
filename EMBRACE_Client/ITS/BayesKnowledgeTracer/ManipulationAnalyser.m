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
#import "StatementStatus.h"

@interface ManipulationAnalyser ()

@property (nonatomic, strong) KnowledgeTracer *knowledgeTracer;

// List of books that the user currently have read.
// Key: BookTitle Value: Dictionary
// Internal Dictionary contains the actions performed for each sentence
// Key : ChapterTitle_SentenceNumber Value: StatementStatus
@property (nonatomic, strong) NSMutableDictionary *booksDict;

@end

@implementation ManipulationAnalyser


- (instancetype)init {
    self = [super init];

    if (self) {
    
        _knowledgeTracer = [[KnowledgeTracer alloc] init];
        _booksDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)userDidPlayWord:(NSString *)word {
    
}


- (void)actionPerformed:(UserAction *)userAction
    manipulationContext:(ManipulationContext *)context {
    
    NSString *bookTitle = context.bookTitle;
    
    
    NSMutableDictionary *bookDetails = [self bookDictionaryForTitle:bookTitle];
    StatementStatus *status = [self getActionListFrom:bookDetails
                                                     forChapter:context.chapterTitle
                                         andStentenceNumber:context.sentenceNumber];
}

- (NSMutableDictionary *)bookDictionaryForTitle:(NSString *)bookTitle {
    NSMutableDictionary *actionDict = [self.booksDict objectForKey:bookTitle];
    if (actionDict == nil) {
        actionDict = [[NSMutableDictionary alloc]init];
        [self.booksDict setObject:actionDict forKey:bookTitle];
    }
    return actionDict;
}

- (StatementStatus *)getActionListFrom:(NSMutableDictionary *)bookDetails
                           forChapter:(NSString *)chapterTitle
                   andStentenceNumber:(NSInteger)sentenceNumber {
    
     NSString *sentenceKey = [NSString stringWithFormat:@"%@_%ld",chapterTitle, (long)sentenceNumber];
    StatementStatus *statementDetails = [bookDetails objectForKey:sentenceKey];
    if (statementDetails == nil) {
        statementDetails = [StatementStatus new];
        statementDetails.chapterTitle = chapterTitle;
        statementDetails.sentenceNumber = sentenceNumber;
        [bookDetails setObject:statementDetails forKey:sentenceKey];
    }

    return statementDetails;
}

@end
