//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserAction;

@interface KnowledgeTracer : NSObject

- (void)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified;
- (void)updateSyntaxSkill:(BOOL)isVerified;
- (void)updatePronounSkill:(BOOL)isVerified;
- (void)updateUsabilitySkill:(BOOL)isVerified;
//- (void)updateVocabSkill:(BOOL)isVerified;


@end
