//
//  WordSkill.h
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Skill.h"

@interface WordSkill : Skill

- (instancetype)initWithWord:(NSString *)word;

@property (nonatomic, readonly) NSString *word;

@end
