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

// Probability of correctly applying a not known skill
#define DEFAULT_GUESS 0.1

// Probability of make a mistake applying a known skill
#define DEFAULT_SLIP 0.2

// Probability of student’s knowledge of a skill transitioning
// from not known to known state after an opportunity to apply it.
#define DEFAULT_SYNTAX_TRANSITION 0.05
#define DEFAULT_VOCAB_TRANSITION 0.1
#define DEFAULT_USABILITY_TRANSITION 0.01

@interface KnowledgeTracer()

@property (nonatomic, strong) SkillSet *skillSet;


@property (nonatomic, assign) double dampenValue;

@end

@implementation KnowledgeTracer


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillSet = [[SkillSet alloc] init];

        
        _dampenValue = 1.0;
    }
    return self;
}

#pragma mark -

- (void)updateDampenValue:(BOOL)shouldDampen {
    if (shouldDampen) {
        self.dampenValue *= 10;
        
    } else {
        self.dampenValue = 1.0;
    }
}
#pragma mark -

- (Skill *)updateSkillFor:(NSString *)action
               isVerified:(BOOL)isVerified
             shouldDampen:(BOOL)shouldDampen {
    
    if (action == nil) {
        return nil;
    }
    
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
    
    [self updateDampenValue:shouldDampen];
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
    
    [self updateDampenValue:shouldDampen];
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
    
    return DEFAULT_SLIP;
}

- (double)getGuess {
    
    return DEFAULT_GUESS;
}

- (double)getSyntaxTransition {
    
    return DEFAULT_SYNTAX_TRANSITION;
}

- (double)getVocabTransition {

    return DEFAULT_VOCAB_TRANSITION;
}

- (double)getUsabilityTransition {

    return DEFAULT_USABILITY_TRANSITION;
}

- (double) calcCorrect:(double)prevSkillValue  {
    double slip = [self getSlip] / self.dampenValue;
    double guess = [self getGuess] / self.dampenValue;
    double noSlip = 1 - slip;
    
    return (prevSkillValue * noSlip)
				/ (prevSkillValue * noSlip + (1 - prevSkillValue) * guess);
    
}

- (double) calcIncorrect:(double) prevSkillValue {
    
    double slip = [self getSlip] / self.dampenValue;
    double guess = [self getGuess] / self.dampenValue;
    
    double noGuess = 1 - guess;
    
    return (prevSkillValue * slip)
				/ ((slip * prevSkillValue) + (noGuess * (1 - prevSkillValue)));
    
}

- (double) calcNewSkillValue:(double )skillEvaluated {
    return [self calcNewSkillValue:skillEvaluated skillType:SkillType_Usability];
}

- (double) calcNewSkillValue:(double )skillEvaluated skillType:(SkillType)type {
    double transition = 1.0;
    switch (type) {
        case SkillType_Usability:
            transition = [self getUsabilityTransition];
            break;
        case SkillType_Syntax:
            transition = [self getSyntaxTransition];
            break;
        case SkillType_Vocab:
            transition = [self getVocabTransition];
            break;
        default:
            break;
    }
    return skillEvaluated + ((1 - skillEvaluated) * transition);
}

#pragma mark - Playword

- (double) calcCorrectPlayWord:(double) prevSkillValue {
    
    
    return (prevSkillValue * (1 - [self getSlip]))
				/ (prevSkillValue * (1 - [self getSlip]) + (1 - prevSkillValue) * [self getGuess]);
}

- (double) calcIncorrectPlayWord:(double) prevSkillValue {
    
    return (prevSkillValue * [self getSlip])
				/ (([self getSlip] * prevSkillValue) + ((1 - [self getGuess]) * (1 - prevSkillValue)));
    
}

@end
