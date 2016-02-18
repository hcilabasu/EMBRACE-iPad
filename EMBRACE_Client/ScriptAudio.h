//
//  ScriptAudio.h
//  EMBRACE
//
//  Created by Jithin on 2/16/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConditionSetup.h"

@interface ScriptAudio : NSObject

- (instancetype)initWithCondition:(Condition)condition
                  englishPreAudio:(NSArray *)engPreAudio
                 englishPostAudio:(NSArray *)engPostAudio
                bilingualPreAudio:(NSArray *)bilingualPreAudio
              bilingualaPostAudio:(NSArray *)bilingualPostAudio;

@property (nonatomic, readonly) Condition condition;

@property (nonatomic, readonly) NSArray *engPreAudio;
@property (nonatomic, readonly) NSArray *engPostAudio;

@property (nonatomic, readonly) NSArray *bilingualPreAudio;
@property (nonatomic, readonly) NSArray *bilingualPostAudio;

@end
