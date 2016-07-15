//
//  KnowledgeTracer.m
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "KnowledgeTracer.h"
#import "SkillSet.h"
#import "UserAction.h"
#import "ActionStep.h"

#define ITS_PRONOUN @"ITS_PRONOUN"
#define ITS_SYNTAX @"ITS_SYNTAX"
#define ITS_USABILITY @"ITS_USABILITY"
#define ITS_VOCAB @"ITS_VOCAB"

@interface KnowledgeTracer()

@property (nonatomic, strong) SkillSet *skillSet;

@end

@implementation KnowledgeTracer


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillSet = [[SkillSet alloc] init];
        [_skillSet skillForWord:ITS_PRONOUN];
        [_skillSet skillForWord:ITS_SYNTAX];
        [_skillSet skillForWord:ITS_VOCAB];
        [_skillSet skillForWord:ITS_USABILITY];
    }
    return self;
}

#pragma mark -

- (void)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified {
    
    if (action == nil) {
        return;
    }
    
    double newSkill = 0.0;
    if (isVerified) {

        Skill *prevSkill = [self.skillSet skillForWord:action];
        double skillEvaluated = [self calcCorrect:prevSkill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [prevSkill updateSkillValue:newSkill];
        
    } else {
        
        Skill *prevSkill = [self.skillSet skillForWord:action];
        double skillEvaluated = [self calcIncorrect:prevSkill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [prevSkill updateSkillValue:newSkill];

    }
    
    NSLog(@"Skill value %@ - %f", action, newSkill);
}

- (void)updateSyntaxSkill:(BOOL)isVerified {
    [self updateSkillFor:ITS_SYNTAX isVerified:isVerified];
}

- (void)updatePronounSkill:(BOOL)isVerified {
    [self updateSkillFor:ITS_PRONOUN isVerified:isVerified];
}

- (void)updateUsabilitySkill:(BOOL)isVerified {
    [self updateSkillFor:ITS_USABILITY isVerified:isVerified];
}

- (void)updateVocabSkill:(BOOL)isVerified {
    [self updateSkillFor:ITS_VOCAB isVerified:isVerified];
}

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
