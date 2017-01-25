//
//  Skill.m
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Skill.h"
#import "WordSkill.h"
#import "SyntaxSkill.h"
#import "UsabilitySkill.h"

#define DEFAULT_INITIAL_VALUE 0.15

@interface Skill ()

@property (nonatomic, assign) double skillValue;



@end

@implementation Skill

+ (Skill *)skillForWord:(NSString *)word {
    if (word == nil || [word isEqualToString:@""]) {
        return nil;
    }
    
    WordSkill *skill = [[WordSkill alloc] initWithWord:word];
    skill.skillType = SkillType_Vocab;
    
    return skill;
}

+ (Skill *)skillForPreviewWord:(NSString *)word {
    if (word == nil || [word isEqualToString:@""]) {
        return nil;
    }
    
    WordSkill *skill = [[WordSkill alloc] initWithWord:word];
    skill.skillType = SkillType_Prev_Vocab;
    
    return skill;
}

+ (Skill *)syntaxSkillWithComplexity:(EMComplexity)complexity {
    SyntaxSkill *skill = [[SyntaxSkill alloc] initWithComplexity:complexity];
    skill.skillType = SkillType_Syntax;
    
    return skill;
}

+ (Skill *)usabilitySkill {
    UsabilitySkill *skill = [[UsabilitySkill alloc] init];
    skill.skillType = SkillType_Usability;
    
    return skill;
}

+ (double)defaultInitialValue {
    return DEFAULT_INITIAL_VALUE;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _skillValue = DEFAULT_INITIAL_VALUE;
    }
    
    return self;
}

- (void)updateSkillValue:(double)value {
    self.skillValue = value;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Skill -  %f", self.skillValue];
}

@end
