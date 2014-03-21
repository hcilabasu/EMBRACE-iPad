//
//  Setup.m
//  EMBRACE
//
//  Created by Administrator on 3/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Setup.h"

@implementation Setup

@synthesize storyTitle;
@synthesize setupSteps;

- (id) initWithTitle:(NSString*)title {
    if(self = [super init]) {
        storyTitle = title;
        setupSteps = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) addSetupStep:(SetupStep*)setupStep {
    [setupSteps addObject:setupStep];
}

@end
