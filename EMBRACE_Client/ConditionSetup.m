//
//  ConditionSetup.m
//  EMBRACE
//
//  Created by James Rodriguez on 11/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "ConditionSetup.h"

@implementation ConditionSetup

@synthesize condition;
@synthesize language;

- (id) init {
    condition = @"Control";
    language = @"Bilingual";
    return self;
}

@end
