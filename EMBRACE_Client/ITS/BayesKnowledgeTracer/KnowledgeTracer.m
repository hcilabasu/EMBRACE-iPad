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
#import "ServerCommunicationController.h"

// Probability of correctly applying a not known skill
#define DEFAULT_GUESS 0.1

#define DEFAULT_SYNTAX_GUESS 0.5
#define DEFAULT_VOCAB_GUESS 0.4
#define DEFAULT_USABILITY_GUESS 0.4

// Probability of making a mistake applying a known skill
#define DEFAULT_SLIP 0.2

#define DEFAULT_SYNTAX_SLIP 0.3
#define DEFAULT_VOCAB_SLIP 0.2
#define DEFAULT_USABILITY_SLIP 0.5

// Probability of student’s knowledge of a skill transitioning from not known to known state after an opportunity to apply it.
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

- (SkillSet *)getSkillSet {
    return _skillSet;
}

- (void)setSkillSet:(SkillSet *)skillSet {
    _skillSet = skillSet;
}

#pragma mark -

- (void)updateDampenValue:(BOOL)shouldDampen {
    if (shouldDampen) {
        self.dampenValue *= 10;
    }
    else {
        self.dampenValue = 1.0;
    }
}

- (Skill *)updateSkill:(Skill *)skill isVerified:(BOOL)isVerified {
    double newSkill = 0.0;
    
    NSLog(@"\n");
    
    if (isVerified) {
        double skillEvaluated = [self calcCorrect:skill.skillValue skillType:[skill skillType]];
        newSkill = [self calcNewSkillValue:skillEvaluated skillType:[skill skillType]];
        [skill updateSkillValue:newSkill];
    }
    else {
        double skillEvaluated = [self calcIncorrect:skill.skillValue skillType:[skill skillType]];
        newSkill = [self calcNewSkillValue:skillEvaluated skillType:[skill skillType]];
        [skill updateSkillValue:newSkill];
    }
    
    return skill;
}

#pragma mark - Updating Vocabulary Skills

- (Skill *)updateSkillFor:(NSString *)word isVerified:(BOOL)isVerified shouldDampen:(BOOL)shouldDampen context:(ManipulationContext *)context {
    if (word == nil || [word isEqualToString:@""]) {
        return nil;
    }
    
    [self updateDampenValue:shouldDampen];
    
    Skill *sk = [self.skillSet skillForWord:word];
    double prevSkillValue = [sk skillValue];
    
    sk = [self updateSkill:sk isVerified:isVerified];
    double newSkillValue = [sk skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:word ofType:@"Vocabulary" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Vocabulary Skill: %@\nPrevious Value: %f\nNew Value: %f", word, prevSkillValue, newSkillValue);
    
    return sk;
}

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified context:(ManipulationContext *)context {
    return [self updateSkillFor:action isVerified:isVerified shouldDampen:NO context:context];
}

#pragma mark - Updating Usability Skill

- (Skill *)updateUsabilitySkill:(BOOL)isVerified shouldDampen:(BOOL)shouldDampen context:(ManipulationContext *)context {
    [self updateDampenValue:shouldDampen];
    
    Skill *sk = [self.skillSet usabilitySkill];
    double prevSkillValue = [sk skillValue];
    
    sk = [self updateSkill:sk isVerified:isVerified];
    double newSkillValue = [sk skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:@"Usability" ofType:@"Usability" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Usability Skill\nPrevious Value: %f\nNew Value: %f", prevSkillValue, newSkillValue);
    
    return sk;
}

- (Skill *)updateUsabilitySkill:(BOOL)isVerified context:(ManipulationContext *)context {
    return [self updateUsabilitySkill:isVerified shouldDampen:NO context:context];
}

#pragma mark - Updating Syntax Skills

- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex shouldDampen:(BOOL)shouldDampen context:(ManipulationContext *)context {
    [self updateDampenValue:shouldDampen];
    
    Skill *sk = [self.skillSet syntaxSkillFor:complex];
    double prevSkillValue = [sk skillValue];
    
    sk = [self updateSkill:sk isVerified:isVerified];
    double newSkillValue = [sk skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:[NSString stringWithFormat:@"%d", complex] ofType:@"Syntax" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Syntax Skill: %d\nPrevious Value: %f\nNew Value: %f", complex, prevSkillValue, newSkillValue);
    
    return sk;
}

- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex context:(ManipulationContext *)context {
    return [self updateSyntaxSkill:isVerified withComplexity:complex shouldDampen:NO context:context];
}

#pragma mark - Getter methods for skills

- (Skill *)syntaxSkillFor:(EMComplexity)complex {
    Skill *sk  = [self.skillSet syntaxSkillFor:complex];
    
    return sk;
}

- (Skill *)vocabSkillForWord:(NSString *)word {
    Skill *sk  = [self.skillSet skillForWord:word];
    
    return sk;
}

#pragma mark -

- (double)getSlipForSkillType:(SkillType)type {
    double slip = DEFAULT_SLIP;
    
    switch (type) {
        case SkillType_Usability:
            slip = DEFAULT_USABILITY_SLIP;
            break;
        case SkillType_Syntax:
            slip = DEFAULT_SYNTAX_SLIP;
            break;
        case SkillType_Vocab:
            slip = DEFAULT_VOCAB_SLIP;
            break;
        default:
            break;
    }
    
    return slip;
}

- (double)getGuessForSkillType:(SkillType)type {
    double guess = DEFAULT_GUESS;
    
    switch (type) {
        case SkillType_Usability:
            guess = DEFAULT_USABILITY_GUESS;
            break;
        case SkillType_Syntax:
            guess = DEFAULT_SYNTAX_GUESS;
            break;
        case SkillType_Vocab:
            guess = DEFAULT_VOCAB_GUESS;
            break;
        default:
            break;
    }

    return guess;
}

- (double)getTransitionForSkillType:(SkillType)type {
    double transition = 1.0;
    
    switch (type) {
        case SkillType_Usability:
            transition = DEFAULT_USABILITY_TRANSITION;
            break;
        case SkillType_Syntax:
            transition = DEFAULT_SYNTAX_TRANSITION;
            break;
        case SkillType_Vocab:
            transition = DEFAULT_VOCAB_TRANSITION;
            break;
        default:
            break;
    }
    
    return transition;
}

- (double)calcCorrect:(double)prevSkillValue skillType:(SkillType)type {
    double slip = [self getSlipForSkillType:type];
    double guess = [self getGuessForSkillType:type] / self.dampenValue;
    double noSlip = (1 - slip) / self.dampenValue;
    
    return (prevSkillValue * noSlip) / (prevSkillValue * noSlip + (1 - prevSkillValue) * guess);
}

- (double)calcIncorrect:(double)prevSkillValue skillType:(SkillType)type {
    double slip = [self getSlipForSkillType:type] / self.dampenValue;
    double guess = [self getGuessForSkillType:type];
    double noGuess = (1 - guess) / self.dampenValue;
    
    return (prevSkillValue * slip) / ((slip * prevSkillValue) + (noGuess * (1 - prevSkillValue)));
}

- (double)calcNewSkillValue:(double)skillEvaluated skillType:(SkillType)type {
    double transition = [self getTransitionForSkillType:type];
    double newSkillValue = skillEvaluated + ((1 - skillEvaluated) * transition);
    
    if (newSkillValue >= 0.99) {
        newSkillValue = 0.99;
    }
    
    return newSkillValue;
}

#pragma mark - Playword

- (double)calcCorrectPlayWord:(double)prevSkillValue {
    return (prevSkillValue * (1 - [self getSlipForSkillType:SkillType_Vocab])) / (prevSkillValue * (1 - [self getSlipForSkillType:SkillType_Vocab]) + (1 - prevSkillValue) * [self getGuessForSkillType:SkillType_Vocab]);
}

- (double) calcIncorrectPlayWord:(double) prevSkillValue {
    return (prevSkillValue * [self getSlipForSkillType:SkillType_Vocab]) / (([self getSlipForSkillType:SkillType_Vocab] * prevSkillValue) + ((1 - [self getGuessForSkillType:SkillType_Vocab]) * (1 - prevSkillValue)));
}

@end
