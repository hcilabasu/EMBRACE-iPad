//
//  Skill.m
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Skill.h"
#import "WordSkill.h"

#define DEFAULT_INITIAL_VALUE 0.15

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

+ (double)defaultInitialValue {
    return DEFAULT_INITIAL_VALUE;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _skillValue = DEFAULT_INITIAL_VALUE;
    }
    return self;
}

- (void)updateSkillValue:(double)value {
    self.skillValue = value;
}

- (NSString *)description {
    return  [NSString stringWithFormat:@"Skill -  %f", self.skillValue];
}

@end
