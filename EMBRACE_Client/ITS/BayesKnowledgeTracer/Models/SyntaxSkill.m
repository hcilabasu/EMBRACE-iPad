//
//  SyntaxSkill.m
//  EMBRACE
//
//  Created by Jithin on 8/12/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SyntaxSkill.h"

@interface SyntaxSkill ()

@property (nonatomic, assign) EMComplexity complexityLevel;

@end

@implementation SyntaxSkill


- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    if (copy) {
        [copy setComplexityLevel:self.complexityLevel];
    }
    
    return copy;
}

- (instancetype)initWithComplexity:(EMComplexity)level {
    self = [super init];
    
    if (self) {
        _complexityLevel = level;
    }
    
    return self;
}

- (NSString *)description {
    NSString *complexLevel = @"Easy Syntax";
    
    if (self.complexityLevel == EM_Medium) {
        complexLevel = @"Medium Syntax";
    }
    else if (self.complexityLevel == EM_Complex) {
        complexLevel = @"Complex Syntax";
        
    } else if (self.complexityLevel == EM_Default) {
        complexLevel = @"Default Syntax";
    }
    
    return  [NSString stringWithFormat:@"%@ -  %f",complexLevel, self.skillValue];
}

@end
