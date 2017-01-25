//
//  Skill.h
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSController.h"

typedef NS_ENUM(NSInteger, SkillType) {
    SkillType_Vocab,
    SkillType_Prev_Vocab,
    SkillType_Usability,
    SkillType_Syntax
};

@interface Skill : NSObject

+ (Skill *)skillForWord:(NSString *)word;

+ (Skill *)syntaxSkillWithComplexity:(EMComplexity)complexity;

+ (Skill *)usabilitySkill;

+ (double)defaultInitialValue;

- (void)updateSkillValue:(double)value;

@property (nonatomic, assign) BOOL isVerified;

@property (nonatomic, readonly) double skillValue;

@property (nonatomic, assign) SkillType skillType;

@end
