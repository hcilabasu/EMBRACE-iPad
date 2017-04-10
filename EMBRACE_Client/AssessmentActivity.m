//
//  AssessmentActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "AssessmentActivity.h"

@implementation AssessmentActivity
@synthesize Answer1;
@synthesize Answer1Audio;
@synthesize Answer2;
@synthesize Answer2Audio;
@synthesize Answer3;
@synthesize Answer3Audio;
@synthesize Answer4;
@synthesize Answer4Audio;
@synthesize QuestionText;
@synthesize QuestionAudio;
@synthesize QuestionNumber;
@synthesize expectedSelection;

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext : (NSString*)questionAudio :(NSString*)answer1 : (NSString*)answer1Audio : (NSString*)answer2 : (NSString*)answer2Audio :(NSString*)answer3 : (NSString*)answer3Audio : (NSString *)answer4 : (NSString*)answer4Audio : (NSString*)selection
{
    if (self = [super init]) {
        self.Answer1=answer1;
        self.Answer1Audio=answer1Audio;
        self.Answer2=answer2;
        self.Answer2Audio=answer2Audio;
        self.Answer3=answer3;
        self.Answer3Audio=answer3Audio;
        self.Answer4=answer4;
        self.Answer4Audio=answer4Audio;
        self.QuestionNumber=QuestionNum;
        self.QuestionText=questiontext;
        self.QuestionAudio=questionAudio;
        self.expectedSelection=selection;
    }
    
    return self;
}


@end
