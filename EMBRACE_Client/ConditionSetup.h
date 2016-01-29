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

@interface ConditionSetup : NSObject {
    Condition condition;
    Language language;
    AppMode appMode;
    Mode currentMode; //PM or IM
}

@property (nonatomic) Condition condition;
@property (nonatomic) Language language;
@property (nonatomic) AppMode appMode;
@property (nonatomic) Mode currentMode;

+ (ConditionSetup*) sharedInstance;

- (NSString*) returnLanguageEnumtoString:(Language)type;
- (NSString*) returnConditionEnumToString:(Condition)type;

@end