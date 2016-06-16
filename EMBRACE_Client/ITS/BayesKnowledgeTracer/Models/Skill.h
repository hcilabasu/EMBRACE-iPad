//
//  Skill.h
//  EMBRACE
//
//  Created by Jithin on 6/13/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Skill : NSObject

+ (Skill *)skillForWord:(NSString *)word;

- (void)updateSkillValue:(double)value;

@property (nonatomic, assign) BOOL isVerified;

@property (nonatomic, readonly) double skillValue;

@end
