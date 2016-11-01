//
//  ConditionSetup.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 10/24/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Activity.h"

//Condition in which the app will be deployed
typedef enum Condition {
    CONTROL, //no manipulation
    EMBRACE //manipulation (PM or IM)
} Condition;

//Language of text/audio
typedef enum Language {
    ENGLISH,
    BILINGUAL //English + Spanish
} Language;

//Different modes of the app
typedef enum AppMode {
    Authoring, //authoring of epubs
    Study, //normal use
    ITS //intelligent tutoring system
} AppMode;

//Differentiates system from user
typedef enum Actor {
    SYSTEM,
    USER
} Actor;

//Differentiates system from user
typedef enum Assessment {
    ENDOFCHAPTER,
    ENDOFBOOK
} Assessment;

@interface ConditionSetup : NSObject

@property (nonatomic) Condition condition;
@property (nonatomic) Language language;
@property (nonatomic) Actor reader; //who should read the text
@property (nonatomic) AppMode appMode;
@property (nonatomic) Mode currentMode; //PM or IM
@property (nonatomic) Assessment assessmentMode;
@property (nonatomic) BOOL newInstructions; //whether new audio instructions should be played (for sequences)
@property (nonatomic) BOOL isVocabPageEnabled; //whether the vocab page should be displayed
@property (nonatomic) BOOL isAssessmentPageEnabled; //whether the assessment page should be displayed
@property (nonatomic) BOOL allowFileSync; //whether log and progress files should be synced with Dropbox

@property (nonatomic) BOOL useKnowledgeTracing; //whether to update skills
@property (nonatomic) BOOL shouldShowITSMessages; //whether to show ITS skill changes as popup messages

+ (ConditionSetup*)sharedInstance;

- (NSString *)returnLanguageEnumtoString:(Language)type;
- (NSString *)returnConditionEnumToString:(Condition)type;

@end
