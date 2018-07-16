//
//  ScriptAudio.m
//  EMBRACE
//
//  Created by Jithin on 2/16/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ScriptAudio.h"

@interface ScriptAudio()

@property (nonatomic, assign) Condition condition;

@property (nonatomic, strong) NSArray *embPreAudio;
@property (nonatomic, strong) NSArray *embPostAudio;

@property (nonatomic, strong) NSArray *controlPreAudio;
@property (nonatomic, strong) NSArray *controlPostAudio;

@end

@implementation ScriptAudio

- (instancetype)initWithCondition:(Condition)condition
                  englishPreAudio:(NSArray *)engPreAudio
                 englishPostAudio:(NSArray *)engPostAudio
                bilingualPreAudio:(NSArray *)bilingualPreAudio
              bilingualaPostAudio:(NSArray *)bilingualPostAudio {
    
    
    
    self = [super init];
    if (self) {
        _condition = condition;
        
        _engPostAudio = engPostAudio;
        _engPreAudio = engPreAudio;
        
        _bilingualPostAudio = bilingualPostAudio;
        _bilingualPreAudio = bilingualPreAudio;
        
    }
    return  self;
}



@end
