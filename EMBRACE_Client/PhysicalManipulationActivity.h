//
//  PhysicalManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "ActionStep.h"
#import "PhysicalManipulationSolution.h"

@interface PhysicalManipulationActivity : Activity {
    NSMutableArray *setupSteps;
    PhysicalManipulationSolution *PMSolution;
}

@property (nonatomic, strong) NSMutableArray *setupSteps;
@property (nonatomic, strong) PhysicalManipulationSolution *PMSolution;

- (void) addSetupStep:(ActionStep*)setupStep;

@end
