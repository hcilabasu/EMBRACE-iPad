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
#import "WordSkill.h"


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

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified {
    
    if (action == nil) {
        return nil;
    }
    
    Skill *prevSkill = [self.skillSet skillForWord:action];
    Skill *sk = [self updateSkill:prevSkill isVerified:isVerified];
    NSLog(@"Skill value %@ - %f", action, sk.skillValue);
    return prevSkill;
}

- (Skill *)updateSkill:(Skill *)skill isVerified:(BOOL)isVerified {
   
    double newSkill = 0.0;
    
    if (isVerified) {
            
        double skillEvaluated = [self calcCorrect:skill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [skill updateSkillValue:newSkill];
        
    } else {
    
        double skillEvaluated = [self calcIncorrect:skill.skillValue];
        newSkill = [self calcNewSkillValue:skillEvaluated];
        [skill updateSkillValue:newSkill];
        
    }
    return skill;
}



- (Skill *)updateUsabilitySkill:(BOOL)isVerified {
    Skill *sk  = [self.skillSet usabilitySkill];
    sk = [self updateSkill:sk isVerified:isVerified];
    return sk;
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
           withComplexity:(EMComplexity)complex {
    
    
    Skill *sk  = [self.skillSet syntaxSkillFor:complex];
    sk = [self updateSkill:sk isVerified:isVerified];
    return sk;
}

- (WordSkill *)getWordSkillFor:(NSString *)word {
    Skill *skill = [self.skillSet skillForWord:word];
    return (WordSkill *)skill;
}


- (Skill *)syntaxSkillFor:(EMComplexity)complex {
    Skill *sk  = [self.skillSet syntaxSkillFor:complex];
    return sk;
}

- (Skill *)vocabSkillForWord:(NSString *)word {
    Skill *sk  = [self.skillSet skillForWord:word];
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
