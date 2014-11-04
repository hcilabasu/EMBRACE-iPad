//
//  IntroductionStep.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "IntroductionStep.h"

@implementation IntroductionStep

@synthesize stepNumber;
@synthesize englishAudioFileName;
@synthesize spanishAudioFileName;
@synthesize englishText;
@synthesize spanishText;
@synthesize expectedSelection;
@synthesize expectedAction;
@synthesize expectedInput;

- (id) initWithValues:(NSInteger)stepNum :(NSString*)englishAudioFile :(NSString*)spanishAudioFile :(NSString*)english :(NSString*)spanish :(NSString*)selection :(NSString*)action :(NSString*)input {
    if (self = [super init]) {
        stepNumber = stepNum;
        englishAudioFileName = englishAudioFile;
        spanishAudioFileName = spanishAudioFile;
        englishText = english;
        spanishText = spanish;
        expectedSelection = selection;
        expectedAction = action;
        expectedInput = input;
    }    
    return self;
}

@end
