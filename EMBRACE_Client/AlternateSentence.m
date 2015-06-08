//
//  AlternateSentence.m
//  EMBRACE
//
//  Created by Administrator on 2/11/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "AlternateSentence.h"

@implementation AlternateSentence

@synthesize sentenceNumber;
@synthesize actionSentence;
@synthesize complexity;
@synthesize text;
@synthesize ideas;
@synthesize solutionSteps;

- (id) initWithValues:(NSUInteger)sentNum :(BOOL)action :(NSUInteger)complex :(NSString*)txt :(NSMutableArray*)ideaNums :(NSMutableArray*)solSteps {
    if(self = [super init]) {
        sentenceNumber = sentNum;
        actionSentence = action;
        complexity = complex;
        text = txt;
        solutionSteps = solSteps;
        ideas = ideaNums;
    }
    
    return self;
}

@end
