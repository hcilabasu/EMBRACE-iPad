//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSController.h"

@class UserAction, Skill;

@interface KnowledgeTracer : NSObject

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified;
- (Skill *)updateUsabilitySkill:(BOOL)isVerified;
- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex;

- (Skill *)syntaxSkillFor:(EMComplexity)complex;

- (Skill *)syntaxSkillForWord:(NSString *)word;

@end
