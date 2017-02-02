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
#define DEFAULT_VOCAB_GUESS 0.3
#define DEFAULT_USABILITY_GUESS 0.4

#define PREVIEW_VOCAB_GUESS 0.5

// Probability of making a mistake applying a known skill
#define DEFAULT_SLIP 0.2

#define DEFAULT_SYNTAX_SLIP 0.2
#define DEFAULT_VOCAB_SLIP 0.2
#define DEFAULT_USABILITY_SLIP 0.5

// Probability of student’s knowledge of a skill transitioning from not known to known state after an opportunity to apply it.
#define DEFAULT_SYNTAX_TRANSITION 0.05
#define DEFAULT_VOCAB_TRANSITION 0.1
#define DEFAULT_USABILITY_TRANSITION 0.05

#define DEFAULT_DAMPENING_FACTOR 2

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
        self.dampenValue /= DEFAULT_DAMPENING_FACTOR;
    }
    else {
        self.dampenValue = 1.0;
    }
    NSLog(@"Dampenvalue - %f \n",self.dampenValue);
}

- (Skill *)updateSkill:(Skill *)skill isVerified:(BOOL)isVerified {
    double newSkill = 0.0;
    
    NSLog(@"\n");
    
    if (isVerified) {
        double skillEvaluated = [self calcCorrect:skill.skillValue skillType:[skill skillType]];
        newSkill = [self calcNewSkillValue:skillEvaluated skillType:[skill skillType] prevSkillValue:skill.skillValue];
        [skill updateSkillValue:newSkill];
    }
    else {
        double skillEvaluated = [self calcIncorrect:skill.skillValue skillType:[skill skillType]];
        newSkill = [self calcNewSkillValue:skillEvaluated skillType:[skill skillType] prevSkillValue:skill.skillValue];
        [skill updateSkillValue:newSkill];
    }
    
    return skill;
}

- (void)updateSkills:(NSArray *)skills {
    
    for (Skill *sk in skills) {
        
        switch (sk.skillType) {
            case SkillType_Prev_Vocab:
            case SkillType_Vocab: {
                WordSkill *wordSkill = (WordSkill *)sk;
                Skill *skill = [self.skillSet skillForWord:wordSkill.word withPreviewType:NO];
                [skill updateSkillValue:wordSkill.skillValue];
                break;
            }
                
            case SkillType_Syntax: {
                SyntaxSkill *syntaxSkill = (SyntaxSkill *)sk;
                Skill *skill = [self.skillSet syntaxSkillFor:syntaxSkill.complexityLevel];
                [skill updateSkillValue:syntaxSkill.skillValue];
                break;
            }
            case SkillType_Usability: {
                UsabilitySkill *usabilitySkill = (UsabilitySkill *)sk;
                Skill *skill = [self.skillSet usabilitySkill];
                [skill updateSkillValue:usabilitySkill.skillValue];
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Updating Vocabulary Skills

- (Skill *)generateSkillFor:(NSString *)word
                 isVerified:(BOOL)isVerified
                    context:(ManipulationContext *)context
              isFromPreview:(BOOL)isFromPreview {
    
    if (word == nil || [word isEqualToString:@""]) {
        return nil;
    }
    
    
    Skill *sk = [self.skillSet skillForWord:word withPreviewType:isFromPreview];
    
    
    double prevSkillValue = [sk skillValue];
    Skill *updatingSK = [sk copy];
    updatingSK = [self updateSkill:updatingSK isVerified:isVerified];
    double newSkillValue = [updatingSK skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:word ofType:@"Vocabulary" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Vocabulary Skill: %@\nPrevious Value: %f\nNew Value: %f", word, prevSkillValue, newSkillValue);
    
    return updatingSK;
}

- (Skill *)generateSkillFor:(NSString *)word
                 isVerified:(BOOL)isVerified
                    context:(ManipulationContext *)context {
    
    return  [self generateSkillFor:word
                        isVerified:isVerified
                           context:context
                     isFromPreview:NO];
}


#pragma mark - Updating Usability Skill

- (Skill *)generateUsabilitySkill:(BOOL)isVerified context:(ManipulationContext *)context {
    
    
    Skill *sk = [self.skillSet usabilitySkill];
    double prevSkillValue = [sk skillValue];
    
    Skill *updatingSK = [sk copy];
    updatingSK = [self updateSkill:updatingSK isVerified:isVerified];
    double newSkillValue = [updatingSK skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:@"Usability" ofType:@"Usability" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Usability Skill\nPrevious Value: %f\nNew Value: %f", prevSkillValue, newSkillValue);
    
    return updatingSK;
}

#pragma mark - Updating Syntax Skills

- (Skill *)generateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex context:(ManipulationContext *)context {
    
    
    Skill *sk = [self.skillSet syntaxSkillFor:complex];
    double prevSkillValue = [sk skillValue];
    
    Skill *updatingSK = [sk copy];
    updatingSK = [self updateSkill:updatingSK isVerified:isVerified];
    double newSkillValue = [updatingSK skillValue];
    
    [[ServerCommunicationController sharedInstance] logUpdateSkill:[NSString stringWithFormat:@"%d", complex] ofType:@"Syntax" prevValue:prevSkillValue newSkillValue:newSkillValue context:context];
    NSLog(@"\nUpdated Syntax Skill: %d Previous Value: %f New Value: %f", complex, prevSkillValue, newSkillValue);
    
    return updatingSK;
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
        case SkillType_Prev_Vocab:
            guess = PREVIEW_VOCAB_GUESS;
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
    double guess = [self getGuessForSkillType:type];
    double noSlip = (1 - slip);
    NSLog(@"\n\n\n(prevSkillValue * noSlip) / (prevSkillValue * noSlip + (1 - prevSkillValue) * guess) \n(%f * %f) / (%f * %f + (1 - %f) * %f)", prevSkillValue ,noSlip,prevSkillValue,noSlip , prevSkillValue,guess);
    return (prevSkillValue * noSlip) / (prevSkillValue * noSlip + (1 - prevSkillValue) * guess);
}

- (double)calcIncorrect:(double)prevSkillValue skillType:(SkillType)type {
    double slip = [self getSlipForSkillType:type];
    double guess = [self getGuessForSkillType:type];
    double noGuess = (1 - guess) ;
    
    NSLog(@"\n\n\n(prevSkillValue * slip) / ((slip * prevSkillValue) + (noGuess * (1 - prevSkillValue))) \n(%f * %f) / (%f * %f + %f * (1 - %f) ", prevSkillValue ,slip,slip,prevSkillValue,noGuess ,prevSkillValue);
    return (prevSkillValue * slip) / ((slip * prevSkillValue) + (noGuess * (1 - prevSkillValue)));
}

- (double)calcNewSkillValue:(double)skillEvaluated skillType:(SkillType)type prevSkillValue:(double)prevSkillValue {
    
    double transition = [self getTransitionForSkillType:type];
    double newSkillValue = skillEvaluated + ((1 - skillEvaluated) * transition);
    
    NSLog(@"New value = \nskillEvaluated + ((1 - skillEvaluated) * transition) - \n%f + ((1 - %f) * %f) ", skillEvaluated,skillEvaluated,transition);
    NSLog(@"New skill - %f Dampenvalue - %f", newSkillValue, self.dampenValue);
    
    newSkillValue = prevSkillValue - (prevSkillValue - newSkillValue) * self.dampenValue;
    
    
    
    if (newSkillValue >= 0.99) {
        newSkillValue = 0.99;
    }
    
    
    return newSkillValue;
}

//- (double)calcNewSkillValue:(double)skillEvaluated
//                  prevSkill:(double)prevSkillValue
//                  skillType:(SkillType)type {
//
//    double transition = [self getTransitionForSkillType:type];
//    double newSkillValue = skillEvaluated + ((1 - skillEvaluated) * transition);
//
//    double diff = newSkillValue - prevSkillValue;
//    double change = diff * self.dampenValue;
//
//    double finalCalValue = prevSkillValue + change;
//    if (finalCalValue >= 0.99) {
//        finalCalValue = 0.99;
//    }
//
//    return finalCalValue;
//}

#pragma mark - Playword

- (double)calcCorrectPlayWord:(double)prevSkillValue {
    return (prevSkillValue * (1 - [self getSlipForSkillType:SkillType_Vocab])) / (prevSkillValue * (1 - [self getSlipForSkillType:SkillType_Vocab]) + (1 - prevSkillValue) * [self getGuessForSkillType:SkillType_Vocab]);
}

- (double) calcIncorrectPlayWord:(double) prevSkillValue {
    return (prevSkillValue * [self getSlipForSkillType:SkillType_Vocab]) / (([self getSlipForSkillType:SkillType_Vocab] * prevSkillValue) + ((1 - [self getGuessForSkillType:SkillType_Vocab]) * (1 - prevSkillValue)));
}

@end
