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
#define ITS_SYNTAX_EASY @"ITS_SYNTAX_EASY"
#define ITS_SYNTAX_MED @"ITS_SYNTAX_MED"
#define ITS_SYNTAX_HARD @"ITS_SYNTAX_HARD"

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
        [_skillSet skillForWord:ITS_SYNTAX_EASY];
        [_skillSet skillForWord:ITS_SYNTAX_MED];
        [_skillSet skillForWord:ITS_SYNTAX_HARD];
        [_skillSet skillForWord:ITS_VOCAB];
        [_skillSet skillForWord:ITS_USABILITY];
    }
    return self;
}

#pragma mark -

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified {
    
    if (action == nil) {
        return nil;
    }
    
    double newSkill = 0.0;
    Skill *prevSkill = nil;
    if (isVerified) {

        prevSkill = [self.skillSet skillForWord:action];
        double skillEvaluated = [self calcCorrect:prevSkill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [prevSkill updateSkillValue:newSkill];
        
    } else {
        
        prevSkill = [self.skillSet skillForWord:action];
        double skillEvaluated = [self calcIncorrect:prevSkill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [prevSkill updateSkillValue:newSkill];

    }
    
    NSLog(@"Skill value %@ - %f", action, newSkill);
    return prevSkill;
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified {
    return [self updateSyntaxSkill:isVerified
             withComplexity:2];
}

- (Skill *)updatePronounSkill:(BOOL)isVerified {
    return [self updateSkillFor:ITS_PRONOUN isVerified:isVerified];
}

- (Skill *)updateUsabilitySkill:(BOOL)isVerified {
    return [self updateSkillFor:ITS_USABILITY isVerified:isVerified];
}

- (Skill *)updateVocabSkill:(BOOL)isVerified {
    return [self updateSkillFor:ITS_VOCAB isVerified:isVerified];
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
           withComplexity:(NSUInteger)complex {
    Skill *sk  = nil;
    switch (complex) {
        case 1:
            sk = [self updateSkillFor:ITS_SYNTAX_EASY isVerified:isVerified];
            break;
        case 2:
            sk = [self updateSkillFor:ITS_SYNTAX_MED isVerified:isVerified];
            break;
        case 3:
            sk = [self updateSkillFor:ITS_SYNTAX_HARD isVerified:isVerified];
            break;
        default:
            break;
    }
    return sk;
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
