//
//  ImagineManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "ActionStep.h"
#import "ImagineManipulationSolution.h"

@interface ImagineManipulationActivity : Activity

@property (nonatomic, strong) NSMutableDictionary *IMSolutions;

- (void)addIMSolution:(ImagineManipulationSolution *)IMSolution forActivityId:(NSString *)activityId;

@end
