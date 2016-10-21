//
//  ConditionSetup.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 10/24/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "ConditionSetup.h"

@implementation ConditionSetup

@synthesize condition;
@synthesize language;
@synthesize reader;
@synthesize appMode;
@synthesize currentMode;
@synthesize newInstructions;
@synthesize isVocabPageEnabled;
@synthesize isAssessmentPageEnabled;
@synthesize assessmentMode;
@synthesize shouldShowITSMessages;

@synthesize allowFileSync;

+ (id)sharedInstance {
    static ConditionSetup *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        condition = EMBRACE;
        language = ENGLISH;
        reader = USER;
        appMode = Study;
        currentMode = IM_MODE;
        newInstructions = FALSE;
        isVocabPageEnabled = false;
        isAssessmentPageEnabled = FALSE;
        assessmentMode = ENDOFBOOK;
        shouldShowITSMessages = YES;
        
        allowFileSync = true; //NOTE: Still testing this functionality
    }
    
    return self;
}

/*
 * Returns a string with the current value of the Condition enumeration
 */
- (NSString *)returnConditionEnumToString:(Condition)type {
    NSString *result = nil;
    
    switch (type) {
        case EMBRACE:
            result = @"Embrace";
            break;
        case CONTROL:
            result = @"Control";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
            break;
    }
    
    return result;
}

/*
 * Returns a string with the current value of the Language enumeration
 */
- (NSString *)returnLanguageEnumtoString:(Language)type {
    NSString *result = nil;
    
    switch (type) {
        case ENGLISH:
            result = @"English";
            break;
        case BILINGUAL:
            result = @"Bilingual";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
            break;
    }
    
    return result;
}

@end
