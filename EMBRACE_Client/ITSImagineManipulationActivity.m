//
//  ITSImagineManipulationActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ITSImagineManipulationActivity.h"

@implementation ITSImagineManipulationActivity

@synthesize ITSIMSolutions;
@synthesize alternateSentences;

- (id)init {
    if (self = [super init]) {
        alternateSentences = [[NSMutableDictionary alloc] init];
        ITSIMSolutions = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/*
 * Add ImagineManipulationSolution to specific activity (page) with id
 */
- (void)addITSIMSolution:(ITSImagineManipulationSolution *)ITSIMSolution forActivityId:(NSString *)actId {
    //Check to see if the key (activity id) exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the ITSIMSolution created.
    NSMutableArray *ITSIMSolutionsForKey = [ITSIMSolutions objectForKey:actId];
    
    if (ITSIMSolutionsForKey == nil) {
        ITSIMSolutionsForKey = [[NSMutableArray alloc] init];
        [ITSIMSolutionsForKey addObject:ITSIMSolution];
        
        if ([activityId length] != 0)
            [ITSIMSolutions setObject:ITSIMSolutionsForKey forKey:actId];
    }
    //If it does, we just add the ITSIMSolution to the array.
    else {
        [ITSIMSolutionsForKey addObject:ITSIMSolution];
    }
}

/*
 * Add alternate sentence to specific page with id
 */
- (void)addAlternateSentence:(AlternateSentence *)altSent forPageId:(NSString *)pageId {
    //Check to see if the key (page id) exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the alternate sentence created.
    NSMutableArray *altSentsForKey = [alternateSentences objectForKey:pageId];
    
    if (altSentsForKey == nil) {
        altSentsForKey = [[NSMutableArray alloc] init];
        [altSentsForKey addObject:altSent];
        
        if ([pageId length] != 0)
            [alternateSentences setObject:altSentsForKey forKey:pageId];
    }
    //If it does, we just add the alternate sentence to the array.
    else {
        [altSentsForKey addObject:altSent];
    }
}

@end
