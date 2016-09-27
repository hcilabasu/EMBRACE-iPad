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

/*
 Update the vocabulary skill
 */
- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified;

/*
 Update the usability skill
 */
- (Skill *)updateUsabilitySkill:(BOOL)isVerified;

/*
 Update the syntax skill
 */
- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(EMComplexity)complex;

// Calling this method will have lesser change in skill value if shouldDampen is TRUE
- (Skill *)updateSkillFor:(NSString *)action
               isVerified:(BOOL)isVerified
             shouldDampen:(BOOL)shouldDampen;

- (Skill *)updateUsabilitySkill:(BOOL)isVerified
                   shouldDampen:(BOOL)shouldDampen;

- (Skill *)updateSyntaxSkill:(BOOL)isVerified
              withComplexity:(EMComplexity)complex
                shouldDampen:(BOOL)shouldDampen;

- (Skill *)syntaxSkillFor:(EMComplexity)complex;
- (Skill *)vocabSkillForWord:(NSString *)word;

@end
