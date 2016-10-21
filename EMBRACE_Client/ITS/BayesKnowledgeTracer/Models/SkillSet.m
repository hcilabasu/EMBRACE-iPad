//
//  SkillSet.m
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SkillSet.h"

@interface SkillSet()

@property (nonatomic, strong) NSMutableDictionary *wordSkillDict;
@property (nonatomic, strong) SyntaxSkill *easySyntaxSkill;
@property (nonatomic, strong) SyntaxSkill *medSyntaxSkill;
@property (nonatomic, strong) SyntaxSkill *complexSyntaxSkill;

@property (nonatomic, strong) UsabilitySkill *usabilitySkill;

@end

@implementation SkillSet

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _wordSkillDict = [[NSMutableDictionary alloc] init];
        
        _easySyntaxSkill = [[SyntaxSkill alloc] initWithComplexity:EM_Easy];
        _medSyntaxSkill = [[SyntaxSkill alloc] initWithComplexity:EM_Medium];
        _complexSyntaxSkill = [[SyntaxSkill alloc] initWithComplexity:EM_Complex];
        
        [_easySyntaxSkill updateSkillValue:0.99];
        
        _usabilitySkill = [[UsabilitySkill alloc] init];
        
    }
    
    return self;
}

- (void)addWordSkill:(Skill *)wordSkill forWord:(NSString *)word {
    [self.wordSkillDict setObject:wordSkill forKey:word];
}

- (Skill *)skillForWord:(NSString *)word {
    Skill *skill = [self.wordSkillDict objectForKey:word];
    
    if (skill == nil) {
        skill = [Skill skillForWord:word];
        [self addWordSkill:skill forWord:word];
    }
    
    return skill;
}

- (SyntaxSkill *)syntaxSkillFor:(EMComplexity)complexity {
    SyntaxSkill *sk = nil;
    
    switch (complexity) {
        case EM_Easy:
            sk = self.easySyntaxSkill;
            break;
        case EM_Medium:
            sk = self.medSyntaxSkill;
            break;
        case EM_Complex:
            sk = self.complexSyntaxSkill;
            break;
        default:
            break;
    }
    
    return sk;
}

- (UsabilitySkill *)usabilitySkill {
    return _usabilitySkill;
}

@end
