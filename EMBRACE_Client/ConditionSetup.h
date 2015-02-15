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

@interface ConditionSetup : NSObject {

    Condition condition;
    Language language;
    
}
@property(nonatomic) Condition condition;
@property(nonatomic) Language language;

-(NSString*)ReturnLanguageEnumtoString:(Language) type;
-(NSString*)ReturnConditionEnumToString:(Condition) type;

@end