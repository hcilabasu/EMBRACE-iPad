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

- (id)init {
    if (self = [super init]) {
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

@end
