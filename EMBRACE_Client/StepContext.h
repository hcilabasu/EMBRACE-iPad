//
//  StepContext.h
//  EMBRACE
//
//  Created by James Rodriguez on 7/21/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"
#import "PhysicalManipulationSolution.h"
#import "ITSPhysicalManipulationSolution.h"
#import "ImagineManipulationSolution.h"
#import "ITSImagineManipulationSolution.h"

@interface StepContext : NSObject

@property (nonatomic, strong) PhysicalManipulationSolution *PMSolution; //PM solution steps for current chapter
@property (nonatomic, strong) ITSPhysicalManipulationSolution *ITSPMSolution; //ITSPM solution steps for current chapter
@property (nonatomic, strong) ImagineManipulationSolution *IMSolution; //IM solution steps for current chapter
@property (nonatomic, strong) ITSImagineManipulationSolution *ITSIMSolution; //ITSIM solution steps for current chapter
@property (nonatomic) BOOL stepsComplete; //True if all steps have been completed for a sentence
@property (nonatomic) NSUInteger numSteps; //Number of steps for current sentence
@property (nonatomic) NSInteger currentStep; //Active step to be completed
@property (nonatomic) NSUInteger maxAttempts; // Maximum number of attempts user can make before system automatically performs step
@property (nonatomic) NSUInteger numAttempts; // Number of attempts user has made for current step
@property (nonatomic) NSUInteger numSyntaxErrors; // Number of syntax errors for current step
@property (nonatomic) NSUInteger numVocabErrors; // Number of vocab errors for current step

@property (nonatomic) NSUInteger numUsabilityErrors;

@end
