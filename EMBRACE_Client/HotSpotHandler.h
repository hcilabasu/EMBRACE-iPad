//
//  HotSpotHandler.h
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//
@class ManipulationViewController;
@class StepContext;
@class SolutionStepController;
@class InteractionModel;
#import <Foundation/Foundation.h>

@interface HotSpotHandler : NSObject
//@property (nonatomic, strong) StepContext *stepContext;
//@property (nonatomic, strong) SolutionStepController *ssc;
//@property (nonatomic, strong) InteractionModel *model;
@property (nonatomic, strong) ManipulationViewController* parentManipulaitonCtr;

- (BOOL)isHotspotInsideLocation:(BOOL)isPreviousStep;
- (BOOL)isHotspotInsideArea;
- (BOOL)areHotspotsInsideArea;
- (BOOL)isHotspotOnPath;
@end
