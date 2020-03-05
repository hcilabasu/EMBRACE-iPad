//
//  SentenceContext.h
//  EMBRACE
//
//  Created by James Rodriguez on 7/21/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface SentenceContext : Context

@property (nonatomic) NSInteger currentSentence; //Active sentence to be completed
@property (nonatomic, copy) NSString *currentSentenceText; //Text of current sentence
@property (nonatomic) NSUInteger totalSentences; //Total number of sentences on this page
@property (nonatomic, strong) NSMutableArray *pageSentences; //AlternateSentences on current page
@property (nonatomic, strong) NSMutableArray *sentenceComplexityList;
@property (nonatomic) NSInteger currentIdea; //Current idea number to be completed

@end
