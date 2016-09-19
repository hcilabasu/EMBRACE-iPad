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

#define DEFAULT_GUESS 0.1
#define DEFAULT_SLIP 0.2
#define DEFAULT_TRANSITION 0.1

@interface KnowledgeTracer()

@property (nonatomic, strong) SkillSet *skillSet;

@property (nonatomic, assign) BOOL shouldDampen;

@property (nonatomic, assign) double guess;

@property (nonatomic, assign) double slip;

@property (nonatomic, assign) double transition;

@end

@implementation KnowledgeTracer


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillSet = [[SkillSet alloc] init];
        _shouldDampen = NO;
        
        _guess = DEFAULT_GUESS;
        _slip = DEFAULT_SLIP;
        _transition = DEFAULT_TRANSITION;
    }
    return self;
}

#pragma mark -

- (Skill *)updateSkillFor:(NSString *)action
               isVerified:(BOOL)isVerified
             shouldDampen:(BOOL)shouldDampen {
    
    if (action == nil) {
        return nil;
    }
    
    self.shouldDampen = shouldDampen;
    
    Skill *prevSkill = [self.skillSet skillForWord:action];
    Skill *sk = [self updateSkill:prevSkill isVerified:isVerified];
    NSLog(@"Skill value %@ - %f", action, sk.skillValue);
    return prevSkill;
}

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified {
    
    return [self updateSkillFor:action isVerified:isVerified shouldDampen:NO];
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


- (Skill *)updateUsabilitySkill:(BOOL)isVerified
                   shouldDampen:(BOOL)shouldDampen {
    
    self.shouldDampen = shouldDampen;
    Skill *sk  = [self.skillSet usabilitySkill];
    sk = [self updateSkill:sk isVerified:isVerified];
    return sk;
}

- (Skill *)updateUsabilitySkill:(BOOL)isVerified  {
    return [self updateUsabilitySkill:isVerified shouldDampen:NO];
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
              withComplexity:(EMComplexity)complex
                shouldDampen:(BOOL)shouldDampen {
    
    self.shouldDampen = shouldDampen;
    Skill *sk  = [self.skillSet syntaxSkillFor:complex];
    sk = [self updateSkill:sk isVerified:isVerified];
    return sk;
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
           withComplexity:(EMComplexity)complex {
    
    return  [self updateSyntaxSkill:isVerified
                     withComplexity:complex
                       shouldDampen:NO];
    
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
    
    if (self.shouldDampen) {
        self.slip /= 10;
    } else {
        self.slip = DEFAULT_SLIP;
    }
    return self.slip;
}

- (double)getSlip2 {
    
    return 0.1;
}

- (double)getGuess {
    
    if (self.shouldDampen) {
        self.guess *= 10;
    } else {
        self.guess = DEFAULT_GUESS;
    }
    
    return self.guess;
    
}

- (double)getGuess2 {
    
    return 0.3;
}

- (double)getTransition {
    if (self.shouldDampen) {
        self.transition /= 10;
    } else {
        self.transition = DEFAULT_TRANSITION;
    }
    
    return self.transition;
}

- (double) calcCorrect:(double)prevSkillValue  {
    
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
