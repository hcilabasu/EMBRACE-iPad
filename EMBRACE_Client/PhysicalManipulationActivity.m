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
@synthesize alternateSentences;
@synthesize PMSolution;

- (id) init {
    if (self = [super init]) {
        setupSteps = [[NSMutableDictionary alloc] init];
        alternateSentences = [[NSMutableDictionary alloc] init];
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
        if ([pageId length] != 0)
            [setupSteps setObject:setupStepsForKey forKey:pageId];
    }
    //If it does, we just add the setup step to the array.
    else {
        [setupStepsForKey addObject:setupStep];
    }
}

//Add alternate sentence to specific page with id
- (void) addAlternateSentence:(AlternateSentence*)altSent forPageId:(NSString*)pageId {
    //Check to see if the key (page id) exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the alternate sentence created.
    NSMutableArray* altSentsForKey = [alternateSentences objectForKey:pageId];
    
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