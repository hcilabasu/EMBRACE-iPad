//
//  ITSPhysicalManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "ActionStep.h"
#import "AlternateSentence.h"
#import "ITSPhysicalManipulationSolution.h"

@interface ITSPhysicalManipulationActivity : Activity

@property (nonatomic, strong) NSMutableDictionary *setupSteps;
@property (nonatomic, strong) NSMutableDictionary *alternateSentences;
@property (nonatomic, strong) NSMutableDictionary *ITSPMSolutions;

- (void)addSetupStep:(ActionStep *)setupStep forPageId:(NSString *)pageId;
- (void)addAlternateSentence:(AlternateSentence *)altSent forPageId:(NSString* )pageId;
- (void)addITSPMSolution:(ITSPhysicalManipulationSolution *)ITSPMSolution forActivityId:(NSString *)activityId;

@end

