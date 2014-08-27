//
//  Introduction.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Introduction.h"

@implementation Introduction

@synthesize title;
@synthesize steps;

- (id) initWithTitle:(NSString*)introTitle
                    : (NSMutableArray*)introSteps {
    if (self = [super init]) {
        title = introTitle;
        steps = introSteps;
    }
    
    return self;
}

/*
 * Returns an array containing all the introduction steps for a given story title
 */
-(NSMutableArray*) getStepsForIntroduction:(NSString*)introTitle {
    NSMutableArray* stepsForIntroduction = [[NSMutableArray alloc] init];
    
    for (IntroductionStep* step in steps) {
        //If the title matches it means the step belongs to the introduction being passed
        if ([title isEqualToString: introTitle]) {
            [stepsForIntroduction addObject:step];
        }
    }
    
    return stepsForIntroduction;
}

@end
