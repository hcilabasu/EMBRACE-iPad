//
//  VocabularyStep.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 7/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "VocabularyStep.h"

@implementation VocabularyStep

@synthesize wordNumber;
@synthesize englishAudioFileName;
@synthesize spanishAudioFileName;
@synthesize englishText;
@synthesize spanishText;
@synthesize expectedSelection;
@synthesize expectedAction;
@synthesize expectedInput;

- (id) initWithValues:(NSInteger)wordNum :(NSString*)englishAudioFile :(NSString*)spanishAudioFile :(NSString*)english :(NSString*)spanish :(NSString*)selection :(NSString*)action :(NSString*)input {
    if (self = [super init]) {
        self.wordNumber = wordNum;
        self.englishAudioFileName = englishAudioFile;
        self.spanishAudioFileName = spanishAudioFile;
        self.englishText = english;
        self.spanishText = spanish;
        self.expectedSelection = selection;
        self.expectedAction = action;
        self.expectedInput = input;
    }
    return self;
}

@end
