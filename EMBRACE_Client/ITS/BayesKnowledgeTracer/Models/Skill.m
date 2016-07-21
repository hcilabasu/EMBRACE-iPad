//
//  Skill.m
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Skill.h"
#import "WordSkill.h"

@interface Skill ()

@property (nonatomic, assign) double skillValue;

@end

@implementation Skill

+ (Skill *)skillForWord:(NSString *)word {
    if (word == nil || [word isEqualToString:@""]) {
        return nil;
    }
    
    WordSkill *skill = [[WordSkill alloc] initWithWord:word];
    return skill;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillValue = 0.15;
    }
    return self;
}

- (void)updateSkillValue:(double)value {
    self.skillValue = value;
}

@end
