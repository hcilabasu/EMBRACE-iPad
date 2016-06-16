//
//  KnowledgeTracer.m
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "KnowledgeTracer.h"
#import "SkillSet.h"

@interface KnowledgeTracer()

@property (nonatomic, strong) SkillSet *skillSet;

@end

@implementation KnowledgeTracer


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillSet = [[SkillSet alloc] init];
    }
    return self;
}

#pragma mark -



#pragma mark -

- (double)getSlip {
    
    return 0.2;
}

- (double)getSlip2 {
    
    return 0.1;
}

- (double)getGuess {
    
    return 0.1;
}

- (double)getGuess2 {
    
    return 0.3;
}

- (double)getTransition {
    return 0.1;
}

- (double) calcCorrect:(double) prevSkillValue  {
    
    return (prevSkillValue * (1 - [self getSlip]))
				/ (prevSkillValue * (1 - [self getSlip]) + (1 - prevSkillValue) * [self getGuess]);
    
}

- (double) calcIncorrect:(double) prevSkillValue {
    
    return (prevSkillValue * [self getSlip])
				/ (([self getSlip] * prevSkillValue) + ((1 - [self getGuess]) * (1 - prevSkillValue)));
    
}

- (double) calcCorrectPlayWord:(double) prevSkillValue {
    
    
    return (prevSkillValue * (1 - [self getSlip2]))
				/ (prevSkillValue * (1 - [self getSlip2]) + (1 - prevSkillValue) * [self getGuess2]);
}

- (double) calcIncorrectPlayWord:(double) prevSkillValue {
    
    return (prevSkillValue * [self getSlip2])
				/ (([self getSlip2] * prevSkillValue) + ((1 - [self getGuess2]) * (1 - prevSkillValue)));
    
}

- (double) calcNewSkillValue:(double )skillEvaluated {
    return skillEvaluated + ((1 - skillEvaluated) * [self getTransition]);
}



@end
