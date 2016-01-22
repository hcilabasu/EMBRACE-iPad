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
    @synthesize appmode;

- (id) init {
    condition = EMBRACE;
    language = ENGLISH;
    appmode = Study;
    return self;
}

-(NSString*)ReturnModeEnumToString:(AppMode)type{
    return @"Authoring";
}

//Returns a string with the current value of the condition enumeration
-(NSString*)ReturnConditionEnumToString:(Condition)type{
    NSString *result =nil;
    
    switch (type) {
        case EMBRACE:
            result = @"Embrace";
            break;
        case CONTROL:
            result = @"Control";
            break;
        default: [NSException raise:NSGenericException format:@"Unexpected FormatType."];
            break;
    }
    
    return result;
}

//Returns a string with the current value of the language enumeration
-(NSString*)ReturnLanguageEnumtoString:(Language)type{
    NSString *result =nil;
    
    switch (type) {
        case ENGLISH:
            result = @"English";
            break;
        case BILINGUAL:
            result = @"Bilingual";
            break;
        default:[NSException raise:NSGenericException format:@"Unexpected FormatType."];
            break;
    }
    
    return result;
}

@end
