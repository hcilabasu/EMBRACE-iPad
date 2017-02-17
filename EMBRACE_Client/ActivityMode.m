//
//  ActivityMode.m
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ActivityMode.h"

@implementation ActivityMode

@synthesize chapterTitle;
@synthesize newInstructions;
@synthesize reader;
@synthesize language;
@synthesize interventionType;
@synthesize vocabPageEnabled;
@synthesize onDemandVocabEnabled;
@synthesize assessmentPageEnabled;

- (id)initWithValues:(NSString *)title :(BOOL)newInstruct :(Actor)read :(Language)lang :(InterventionType)type :(BOOL) isVocabPageEnabled :(BOOL) isOnDemandVocabEnabled : (BOOL) isAssessmentPageEnabled {
    if (self = [super init]) {
        chapterTitle = title;
        newInstructions = newInstruct;
        reader = read;
        language = lang;
        interventionType = type;
        vocabPageEnabled = isVocabPageEnabled;
        onDemandVocabEnabled = isOnDemandVocabEnabled;
        assessmentPageEnabled = isAssessmentPageEnabled;
    }
    
    return self;
}

@end
