//
//  SyntaxSkill.h
//  EMBRACE
//
//  Created by Jithin on 8/12/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Skill.h"
#import "ITSController.h"

@interface SyntaxSkill : Skill

- (instancetype)initWithComplexity:(EMComplexity)level;

@property (nonatomic, readonly) EMComplexity complexityLevel;

@end
