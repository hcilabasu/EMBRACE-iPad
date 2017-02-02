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
#import "AlternateSentence.h"

@interface ITSImagineManipulationActivity : Activity

@property (nonatomic, strong) NSMutableDictionary *ITSIMSolutions;
@property (nonatomic, strong) NSMutableDictionary *alternateSentences;

- (void)addAlternateSentence:(AlternateSentence *)altSent forPageId:(NSString* )pageId;
- (void)addITSIMSolution:(ITSImagineManipulationSolution *)ITSIMSolution forActivityId:(NSString *)activityId;

@end
