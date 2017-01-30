//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSController.h"

@class UserAction, Skill, SkillSet;

@interface KnowledgeTracer : NSObject

- (SkillSet *)getSkillSet;
- (void)setSkillSet:(SkillSet *)skillSet;

// Update vocabulary skill
- (Skill *)generateSkillFor:(NSString *)action isVerified:(BOOL)isVerified context:(ManipulationContext *)context;
- (Skill *)generateSkillFor:(NSString *)word
                 isVerified:(BOOL)isVerified
                    context:(ManipulationContext *)context
              isFromPreview:(BOOL)isFromPreview;


// Update usability skill
- (Skill *)generateUsabilitySkill:(BOOL)isVerified context:(ManipulationContext *)context;

// Update syntax skill
- (Skill *)generateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex context:(ManipulationContext *)context;

- (Skill *)syntaxSkillFor:(EMComplexity)complex;
- (Skill *)vocabSkillForWord:(NSString *)word;

- (void)updateSkills:(NSArray *)skills;

- (void)updateDampenValue:(BOOL)shouldDampen;

@end
