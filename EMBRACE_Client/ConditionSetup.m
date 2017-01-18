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
@synthesize animatedStepCompletionMode;
@synthesize isAutomaticAnimationEnabled;
@synthesize useKnowledgeTracing;
@synthesize shouldShowITSMessages;
@synthesize isOnDemandVocabEnabled;
@synthesize isBackButtonEnabled;
@synthesize isSpeakerButtonEnabled;

@synthesize allowFileSync;

static ConditionSetup *sharedInstance = nil;

+ (ConditionSetup *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[ConditionSetup alloc] init];
    }
    
    return sharedInstance;
}

+ (void)resetSharedInstance {
    sharedInstance = nil;
}

- (id)init {
    if (self = [super init]) {
        condition = EMBRACE;
        language = ENGLISH;
        reader = SYSTEM;
        appMode = ITS;
        currentMode = PM_MODE;

        newInstructions = NO;
        isVocabPageEnabled = YES;
        isAssessmentPageEnabled = YES;
        assessmentMode = ENDOFCHAPTER;
        isOnDemandVocabEnabled = YES;
        
        isAutomaticAnimationEnabled = YES;
        animatedStepCompletionMode = PERSTEP;
        
        isBackButtonEnabled = NO;
        isSpeakerButtonEnabled = NO;
        
        useKnowledgeTracing = YES;
        shouldShowITSMessages = YES;
        
        allowFileSync = YES;
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
 * Returns a string with the current value of the AppMode enumeration
 */
- (NSString *)returnAppModeEnumToString:(AppMode)type {
    NSString *result = nil;
    
    switch (type) {
        case Authoring:
            result = @"Authoring";
            break;
        case Study:
            result = @"Study";
            break;
        case ITS:
            result = @"ITS";
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
