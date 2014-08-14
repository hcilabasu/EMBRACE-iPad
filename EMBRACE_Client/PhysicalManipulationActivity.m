//
//  PhysicalManipulationActivity.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PhysicalManipulationActivity.h"

@implementation PhysicalManipulationActivity

@synthesize setupSteps;
@synthesize PMSolution;

- (id) init {
    if (self = [super init]) {
        setupSteps = [[NSMutableDictionary alloc] init];
        PMSolution = [[PhysicalManipulationSolution alloc] init];
    }
    
    return self;
}

//Add setup step to specific page with id
- (void) addSetupStep:(ActionStep*)setupStep forPageId:(NSString*)pageId {
    //Check to see if the key (page id) exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the setup step created.
    NSMutableArray* setupStepsForKey = [setupSteps objectForKey:pageId];
    
    if (setupStepsForKey == nil) {
        setupStepsForKey = [[NSMutableArray alloc] init];
        [setupStepsForKey addObject:setupStep];
        [setupSteps setObject:setupStepsForKey forKey:pageId];
    }
    //If it does, we just add the setup step to the array.
    else {
        [setupStepsForKey addObject:setupStep];
    }
}

@end