//
//  ActivityMode.h
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConditionSetup.h"

//Defines who should read text
typedef enum Reader {
    SYSTEM_READER,
    USER_READER
} Reader;

//Type of intervention to use
typedef enum InterventionType {
    PM_INTERVENTION, //physical manipulation
    IM_INTERVENTION, //imagine manipulation
    NO_INTERVENTION //read-only
} InterventionType;

@interface ActivityMode : NSObject

@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, assign) Reader reader;
@property (nonatomic, assign) Language language;
@property (nonatomic, assign) InterventionType interventionType; //English or Spanish-support (i.e., bilingual)

- (id)initWithValues:(NSString *)title :(Reader)read :(Language)lang :(InterventionType)type;

@end
