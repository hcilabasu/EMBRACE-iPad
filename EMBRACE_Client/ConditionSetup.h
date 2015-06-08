//
//  ConditionSetup.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 10/24/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

//describes the condition in which the app will be deployed
typedef enum Condition{
    MENU,
    HOTSPOT,
    CONTROL,
    OTHER,
    EMBRACE
} Condition;

//Defines the types of language conditions to be used
typedef enum Language{
    ENGLISH,
    BILINGUAL
} Language;

//defines the types of mode conditions to be used
typedef enum AppMode{
    Authoring,
    Study,
    ITS
} AppMode;

@interface ConditionSetup : NSObject {

    Condition condition;
    Language language;
    AppMode appmode;
    
}

@property(nonatomic) Condition condition;
@property(nonatomic) Language language;
@property(nonatomic) AppMode appmode;

-(NSString*)ReturnModeEnumToString:(AppMode) type;
-(NSString*)ReturnLanguageEnumtoString:(Language) type;
-(NSString*)ReturnConditionEnumToString:(Condition) type;

@end