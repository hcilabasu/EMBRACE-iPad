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

@interface ITSController : NSObject

+ (instancetype)sharedInstance;

- (void)movedObject:(NSString *)objectId
  destinationObjects:(NSArray *)destinationObjs
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context
        forSentence:(NSString *)sentence;

- (void)userDidPlayWord:(NSString *)word;

@end
