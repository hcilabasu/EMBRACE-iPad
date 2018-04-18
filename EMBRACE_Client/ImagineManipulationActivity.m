//
//  ImagineManipulationActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ImagineManipulationActivity.h"

@implementation ImagineManipulationActivity

@synthesize IMSolutions;

- (id)init {
    if (self = [super init]) {
        IMSolutions = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/*
 * Add ImagineManipulationSolution to specific activity (page) with id
 */
- (void)addIMSolution:(ImagineManipulationSolution *)IMSolution forActivityId:(NSString *)actId {
    //Check to see if the key (activity id) exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the IMSolution created.
    NSMutableArray *IMSolutionsForKey = [IMSolutions objectForKey:actId];
    
    if (IMSolutionsForKey == nil) {
        IMSolutionsForKey = [[NSMutableArray alloc] init];
        [IMSolutionsForKey addObject:IMSolution];
        
        if ([activityId length] != 0)
            [IMSolutions setObject:IMSolutionsForKey forKey:actId];
    }
    //If it does, we just add the IMSolution to the array.
    else {
        [IMSolutionsForKey addObject:IMSolution];
    }
}

@end
