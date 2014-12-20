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
@synthesize Answer2;
@synthesize Answer3;
@synthesize Answer4;
@synthesize QuestionText;
@synthesize QuestionNumber;
@synthesize expectedSelection;

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext :(NSString*)answer1 :(NSString*)answer2 :(NSString*)answer3 : (NSString *)answer4 : (NSInteger)selection
{
    if (self = [super init]) {
        Answer1=answer1;
        Answer2=answer2;
        Answer3=answer3;
        Answer4=answer4;
        QuestionNumber=QuestionNum;
        QuestionText=questiontext;
        expectedSelection=selection;
    }
    
    return self;
}


@end
