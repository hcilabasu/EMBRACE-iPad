//
//  SkillSet.m
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SkillSet.h"

@interface SkillSet()

@property (nonatomic, strong) NSMutableDictionary *wordSkillDict;

@end

@implementation SkillSet

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _wordSkillDict = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

- (void)addWordSkill:(Skill *)wordSkill forWord:(NSString *)word {
    [self.wordSkillDict setObject:wordSkill forKey:word];
}

- (Skill *)getSkillForWord:(NSString *)word {
    return [self.wordSkillDict objectForKey:word];
}

@end
