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

@property (nonatomic, strong) SyntaxSkill *defaultSyntaxSkill;
@property (nonatomic, strong) UsabilitySkill *usabilitySkill;

@end

@implementation SkillSet

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _wordSkillDict = [[NSMutableDictionary alloc] init];
        
        _easySyntaxSkill = (SyntaxSkill *) [Skill syntaxSkillWithComplexity:EM_Easy];
        _medSyntaxSkill = (SyntaxSkill *) [Skill syntaxSkillWithComplexity:EM_Medium];
        _complexSyntaxSkill = (SyntaxSkill *) [Skill syntaxSkillWithComplexity:EM_Complex];
        _defaultSyntaxSkill = (SyntaxSkill *) [Skill syntaxSkillWithComplexity:EM_Default];
        [_defaultSyntaxSkill updateSkillValue:0.5];
        [_easySyntaxSkill updateSkillValue:0.9];
        
        _usabilitySkill = (UsabilitySkill *) [Skill usabilitySkill];        
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
        
        if (skill != nil) {
            [self addWordSkill:skill forWord:word];
        }
    }
    
    return skill;
}

- (SyntaxSkill *)syntaxSkillFor:(EMComplexity)complexity {
    return self.defaultSyntaxSkill;
//    SyntaxSkill *sk = nil;
//    
//    switch (complexity) {
//        case EM_Easy:
//            sk = self.easySyntaxSkill;
//            break;
//        case EM_Medium:
//            sk = self.medSyntaxSkill;
//            break;
//        case EM_Complex:
//            sk = self.complexSyntaxSkill;
//            break;
//        default:
//            sk = self.defaultSyntaxSkill;
//            break;
//    }
//    
//    return sk;
}

- (UsabilitySkill *)usabilitySkill {
    return _usabilitySkill;
}

- (NSMutableDictionary *)getVocabularySkills {
    return _wordSkillDict;
}

@end
