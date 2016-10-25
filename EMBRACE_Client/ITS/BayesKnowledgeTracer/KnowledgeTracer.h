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

// Update vocabulary skill
- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified context:(ManipulationContext *)context;

// Update usability skill
- (Skill *)updateUsabilitySkill:(BOOL)isVerified context:(ManipulationContext *)context;

// Update syntax skill
- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex context:(ManipulationContext *)context;

// Calling this method will have lesser change in skill value if shouldDampen is TRUE
- (Skill *)updateSkillFor:(NSString *)action
               isVerified:(BOOL)isVerified
             shouldDampen:(BOOL)shouldDampen
                  context:(ManipulationContext *)context;

- (Skill *)updateUsabilitySkill:(BOOL)isVerified
                   shouldDampen:(BOOL)shouldDampen
                        context:(ManipulationContext *)context;

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
              withComplexity:(EMComplexity)complex
                shouldDampen:(BOOL)shouldDampen
                     context:(ManipulationContext *)context;

- (Skill *)syntaxSkillFor:(EMComplexity)complex;
- (Skill *)vocabSkillForWord:(NSString *)word;

@end
