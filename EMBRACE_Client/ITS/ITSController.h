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

- (void)movedObject:(NSString *)objectId
  destinationObject:(NSString *)destinationId
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context;

- (void)movedObject:(NSString *)objectId
     destinationLoc:(NSString *)destinationLoc
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context;

- (void)movedObject:(NSString *)objectId
destinationWaypoint:(NSString *)waypoint
         isVerified:(BOOL)verified
         actionStep:(ActionStep *)actionStep
manipulationContext:(ManipulationContext *)context;

@end
