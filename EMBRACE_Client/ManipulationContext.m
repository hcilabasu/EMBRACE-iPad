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

@synthesize pageLanguage;
@synthesize pageMode;
@synthesize pageNumber;
@synthesize pageComplexity;

@synthesize sentenceNumber;
@synthesize sentenceComplexity;
@synthesize sentenceText;
@synthesize manipulationSentence;

@synthesize stepNumber;

@synthesize ideaNumber;

- (id)init {
    return [super init];
}

@end
