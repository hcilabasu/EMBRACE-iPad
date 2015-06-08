//
//  PhysicalManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "ActionStep.h"
#import "AlternateSentence.h"
#import "PhysicalManipulationSolution.h"

@interface PhysicalManipulationActivity : Activity {
    NSMutableDictionary *setupSteps;
    NSMutableDictionary *alternateSentences;
    NSMutableDictionary *PMSolutions;
    //PhysicalManipulationSolution *PMSolution;
}

@property (nonatomic, strong) NSMutableDictionary *setupSteps;
@property (nonatomic, strong) NSMutableDictionary *alternateSentences;
@property (nonatomic, strong) NSMutableDictionary *PMSolutions;
//@property (nonatomic, strong) PhysicalManipulationSolution *PMSolution;

- (void) addSetupStep:(ActionStep*)setupStep forPageId:(NSString*)pageId;
- (void) addAlternateSentence:(AlternateSentence*)altSent forPageId:(NSString*)pageId;
- (void) addPMSolution:(PhysicalManipulationSolution*)PMSolution forActivityId:(NSString*)activityId;

@end

