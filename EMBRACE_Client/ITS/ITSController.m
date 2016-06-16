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
    
}


- (void)movedObject:(NSString *)objectId
  destinationObject:(NSString *)destinationId
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context {
    
    UserAction *userAction = [[UserAction alloc] initWithMovedObjectId:objectId
                                                         destinationId:destinationId
                                                            actionStep:actionStep
                                                            isVerified:verified];

}

- (void)movedObject:(NSString *)objectId
     destinationLoc:(NSString *)destinationLoc
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context {
    
}

- (void)movedObject:(NSString *)objectId
destinationWaypoint:(NSString *)waypoint
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context {
    
}

@end
