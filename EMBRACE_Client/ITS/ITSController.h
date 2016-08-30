//
//  ITSController.h
//  EMBRACE
//
//  Created by Jithin on 6/1/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationContext.h"
#import "ActionStep.h"

typedef NS_ENUM(NSInteger, EMComplexity) {
    EM_Easy = 1,
    EM_Medium,
    EM_Complex
};

@interface ITSController : NSObject

+ (instancetype)sharedInstance;

- (void)setAnalyzerDelegate:(id)delegate;

- (void)movedObject:(NSString *)objectId
  destinationObjects:(NSArray *)destinationObjs
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context
        forSentence:(NSString *)sentence;

- (void)userDidPlayWord:(NSString *)word;

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context
                               forSentence:(NSString *)sentence
                                isVerified:(BOOL)verified;

- (EMComplexity)getCurrentComplexity;

- (double)vocabSkillValueForWord:(NSString *)word;

@end
