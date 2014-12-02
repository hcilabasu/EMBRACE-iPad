//
//  ConditionSetup.h
//  EMBRACE
//
//  Created by James Rodriguez on 11/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

////Describes the condition in which the app will be deployed
//typedef enum Condition {
//    MENU,
//    HOTSPOT,
//    CONTROL,
//    OTHER,
//} Condition;
//
////Defines the types of language conditions to be used
//typedef enum Language {
//    ENGLISH,
//    BILINGUAL
//} Language;

//NSString* condition = @"Control";

@interface ConditionSetup : NSObject {
    
    NSString *condition;
    NSString *language;
    
}

@property (nonatomic,strong)  NSString * condition;
@property (nonatomic,strong)  NSString * language;

@end
