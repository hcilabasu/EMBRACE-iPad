//
//  PageContext.m
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ManipulationContext.h"

@implementation ManipulationContext

@synthesize bookTitle;

@synthesize chapterTitle;
@synthesize chapterNumber;

@synthesize pageNumber;
@synthesize pageName;
@synthesize pageLanguage;
@synthesize pageMode;

@synthesize sentenceNumber;
@synthesize sentenceText;

@synthesize stepNumber;

@synthesize ideaNumber;

- (id)init {
    return [super init];
}

- (void)extractPageInformationFromPath:(NSString *)pageFilePath {
    //Chapter and page information
    NSString *cNumber = @"NULL";
    NSString *pNumber = @"NULL";
    NSString *pName = @"NULL";
    NSString *pMode = @"NULL";
    NSString *pLanguage = @"NULL";
    
    //Parse the page file path to set chapter and page information
    //Page file path format: story#- (story name)- (im/pm/intro)- (#/#s/E/S).xhtml
    if (![pageFilePath isEqualToString:@"NULL"] && ![pageFilePath isEqualToString:@"Page Finished"]) {
        NSString* pageFileName = [NSString stringWithFormat:@"%@", [pageFilePath lastPathComponent]];
        
        //Set page language type, number, and name
        if ([pageFileName rangeOfString:@"S.xhtml"].location != NSNotFound) {
            pLanguage = @"S";
            
            NSRange range = [pageFileName rangeOfString:@"S.xhtml"];
            range.length = 1;
            range.location = range.location - 1;
            
            pNumber = [pageFileName substringWithRange:range];
            
            pName = [pageFileName substringToIndex:range.location];
            pName = [pName substringFromIndex:5];
            pName = [pName stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        }
        else {
            pLanguage = @"E";
            
            NSRange range = [pageFileName rangeOfString:@".xhtml"];
            range.length = 1;
            range.location = range.location - 1;
            
            pNumber = [pageFileName substringWithRange:range];
            
            if ([pNumber isEqualToString:@"E"] || [pNumber isEqualToString:@"S"]) {
                pNumber = @"NULL";
            }
            
            pName = [pageFileName substringToIndex:range.location];
            pName = [pName substringFromIndex:5];
            pName = [pName stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        }
        
        //Set page mode
        if ([pageFileName rangeOfString:@"IM"].location != NSNotFound) {
            pMode = @"IM";
        }
        else if ([pageFileName rangeOfString:@"PM"].location != NSNotFound) {
            pMode = @"PM";
        }
        else if ([pageFileName rangeOfString:@"Intro"].location != NSNotFound) {
            pMode = @"INTRO";
            pNumber = @"0";
        }
        
        //Set chapter number
        cNumber = [pageFileName substringToIndex:6];
        cNumber = [cNumber substringFromIndex:5];
    }
    
    chapterNumber = [cNumber intValue];
    
    pageNumber = [pNumber intValue];
    pageName = pName;
    pageLanguage = pLanguage;
}

@end
