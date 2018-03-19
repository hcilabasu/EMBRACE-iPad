//
//  ErrorFeedback.m
//  EMBRACE
//
//  Created by Jithin Roy on 1/27/17.
//  Copyright © 2017 Andreea Danielescu. All rights reserved.
//

#import "ErrorFeedback.h"
#import "Skill.h"

@implementation ErrorFeedback

- (instancetype)init {
    self = [super init];
    if (self ) {
        _feedbackType = EMFeedbackType_None;
        _skillType = SkillType_None;
    }
    return self;
}

@end
