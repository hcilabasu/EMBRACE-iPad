//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserAction, Skill;

@interface KnowledgeTracer : NSObject

- (Skill *)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified;
- (Skill *)updateSyntaxSkill:(BOOL)isVerified;
- (Skill *)updatePronounSkill:(BOOL)isVerified;
- (Skill *)updateUsabilitySkill:(BOOL)isVerified;

- (Skill *)updateSyntaxSkill:(BOOL)isVerified withComplexity:(NSUInteger)complex;


@end
