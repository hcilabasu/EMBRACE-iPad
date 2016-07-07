//
//  ITSController.m
//  EMBRACE
//
//  Created by Jithin on 6/1/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ITSController.h"
#import "ManipulationAnalyser.h"
#import "UserAction.h"

@interface ITSController()

@property (nonatomic, strong) ManipulationAnalyser *manipulationAnalyser;

@end

@implementation ITSController

+ (instancetype)sharedInstance {
    
    static ITSController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ITSController alloc] init];

    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manipulationAnalyser = [[ManipulationAnalyser alloc] init];
    }
    return self;
}

#pragma  mark - 

- (void)userDidPlayWord:(NSString *)word {
    [self.manipulationAnalyser userDidPlayWord:word];
    
}


- (void)movedObject:(NSString *)objectId
  destinationObjects:(NSArray *)destinationObjs
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context
        forSentence:(NSString *)sentence {
    
    NSString *dest = nil;
    if ([destinationObjs count] > 0) {
           dest = [destinationObjs objectAtIndex:0];
        if ([destinationObjs containsObject:actionStep.object2Id]) {
            dest = [actionStep.object2Id copy];
        }
    }

    UserAction *userAction = [[UserAction alloc] initWithMovedObjectId:objectId
                                                         destinationId:dest
                                                            actionStep:actionStep
                                                            isVerified:verified
                                                           forSentence:sentence];
    [self.manipulationAnalyser actionPerformed:userAction
                           manipulationContext:context];

}



@end
