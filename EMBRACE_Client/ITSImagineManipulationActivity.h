//
//  ITSImagineManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "ActionStep.h"
#import "ITSImagineManipulationSolution.h"

@interface ITSImagineManipulationActivity : Activity

@property (nonatomic, strong) NSMutableDictionary *ITSIMSolutions;

- (void)addITSIMSolution:(ITSImagineManipulationSolution *)ITSIMSolution forActivityId:(NSString *)activityId;

@end
