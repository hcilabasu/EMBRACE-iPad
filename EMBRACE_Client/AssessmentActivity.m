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

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext : (NSString*)questionAudio :(NSString*)answer1 : (NSString*)answer1Audio : (NSString*)answer2 : (NSString*)answer2Audio :(NSString*)answer3 : (NSString*)answer3Audio : (NSString *)answer4 : (NSString*)answer4Audio : (NSInteger)selection
{
    if (self = [super init]) {
        Answer1=answer1;
        Answer1Audio=answer1Audio;
        Answer2=answer2;
        Answer2Audio=answer2Audio;
        Answer3=answer3;
        Answer3Audio=answer3Audio;
        Answer4=answer4;
        Answer4Audio=answer4Audio;
        QuestionNumber=QuestionNum;
        QuestionText=questiontext;
        QuestionAudio=questionAudio;
        expectedSelection=selection;
    }
    
    return self;
}


@end
