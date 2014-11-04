//
//  BuildHTMLString.m
//  EMBRACE
//
//  Created by James Rodriguez on 10/21/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "BuildHTMLString.h"

@implementation BuildHTMLString

/*
 * Builds the format of the action sentence that allows words to be clickable
 */

//+(NSString*) buildHTMLString:(NSString *)htmlText :(NSString *)selectionType :(NSString *)clickableWord :(NSString *)sentenceType{
 //   return [self buildHTMLString:htmlText :selectionType :clickableWord :sentenceType];
//}

-(NSString*) buildHTMLString:(NSString*)htmlText :(NSString*)selectionType :(NSString*)clickableWord :(NSString*) sentenceType {
    //String to build
    NSString* stringToBuild;
    
    //If string contains the special character "'"
    if ([htmlText rangeOfString:@"'"].location != NSNotFound) {
        htmlText = [htmlText stringByReplacingCharactersInRange:NSMakeRange([htmlText rangeOfString:@"'"].location,1) withString:@"&#39;"];
    }
    
    NSArray* splits = [htmlText componentsSeparatedByString:clickableWord];
    
    if ([sentenceType isEqualToString:@"move"] || [sentenceType isEqualToString:@"group"]) {
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence actionSentence\" id=\"s1\">%@</span>",htmlText];
    }
    else if ([selectionType isEqualToString:@"word"]){
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence\" id=\"s1\">%@<span class=\"audible\">%@</span>%@</span>",splits[0],clickableWord,splits[1]];
    }
    else {
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence\" id=\"s1\">%@</span>",htmlText];
    }
    
    return stringToBuild;
}


@end
