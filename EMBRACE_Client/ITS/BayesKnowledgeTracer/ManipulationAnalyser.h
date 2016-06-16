//
//  ManipulationAnalyser.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserAction;
@class ManipulationContext;

@interface ManipulationAnalyser : NSObject


- (void)actionPerformed:(UserAction *)userAction
    manipulationContext:(ManipulationContext *)context;


@end
