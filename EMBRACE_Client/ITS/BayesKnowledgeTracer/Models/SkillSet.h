//
//  SkillSet.h
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Skill.h"
#import "WordSkill.h"
#import "SyntaxSkill.h"
#import "UsabilitySkill.h"

@interface SkillSet : NSObject

- (void)addWordSkill:(Skill *)wordSkill forWord:(NSString *)word;

- (Skill *)skillForWord:(NSString *)word;

- (SyntaxSkill *)syntaxSkillFor:(EMComplexity)complexity;

- (UsabilitySkill *)usabilitySkill;

@end
