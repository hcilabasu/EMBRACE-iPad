//
//  HotSpotHandler.m
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import "HotSpotHandler.h"
#import "ManipulationViewController.h"
#import "StepContext.h"
#import "SolutionStepController.h"
#import "ResourceStrings.h"
#import "InteractionModel.h"
@implementation HotSpotHandler
//@synthesize stepContext;
//@synthesize ssc;
//@synthesize model;
@synthesize parentManipulaitonCtr;

/*
 * Returns true if the hotspot of an object (for a check step type) is inside the correct location.
 * Otherwise, returns false.
 */
- (BOOL)isHotspotInsideLocation:(BOOL)isPreviousStep {
    //Check solution only if it exists for the sentence
    if (parentManipulaitonCtr.stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
        //Get current step to be completed
        ActionStep *currSolStep;
        if (isPreviousStep) {
            currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 2];
        }
        else{
            currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        }
        
        if ([[currSolStep stepType] isEqualToString:CHECK] ||
            [[currSolStep stepType] isEqualToString:CHECKPATH] ||
            [[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *locationId = [currSolStep locationId];
            //Get hotspot location of correct subject
            Hotspot *hotspot = [parentManipulaitonCtr.model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [parentManipulaitonCtr.manipulationView getHotspotLocation:hotspot];
            //Get location that hotspot should be inside
            Location *location = [parentManipulaitonCtr.model getLocationWithId:locationId];
            
            //Calculate the x,y coordinates and the width and height in pixels from %
            float locationX = [location.originX floatValue] / 100.0 * [parentManipulaitonCtr.bookView frame].size.width;
            float locationY = [location.originY floatValue] / 100.0 * [parentManipulaitonCtr.bookView  frame].size.height;
            float locationWidth = [location.width floatValue] / 100.0 * [parentManipulaitonCtr.bookView  frame].size.width;
            float locationHeight = [location.height floatValue] / 100.0 * [parentManipulaitonCtr.bookView  frame].size.height;
            
            //Check if hotspot is inside location
            if (((hotspotLocation.x < locationX + locationWidth) && (hotspotLocation.x > locationX)
                 && (hotspotLocation.y < locationY + locationHeight) && (hotspotLocation.y > locationY)) || [locationId isEqualToString:ANYWHERE]) {
                return true;
            }
        }
    }
    return false;
}


- (BOOL)isHotspotInsideArea {
    //Check solution only if it exists for the sentence
    if (parentManipulaitonCtr.stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:CHECK] || [[currSolStep stepType] isEqualToString:CHECKPATH]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [parentManipulaitonCtr.model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [parentManipulaitonCtr.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area* area = [parentManipulaitonCtr.model getArea:areaId:parentManipulaitonCtr.pageContext.currentPageId];
            
            if ([area.aPath containsPoint:hotspotLocation]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Returns true if the start location and the end location of an object are within the same area. Otherwise, returns false.
 */
- (BOOL)areHotspotsInsideArea {
    //Check solution only if it exists for the sentence
    if (parentManipulaitonCtr.stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [parentManipulaitonCtr.model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [parentManipulaitonCtr.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [parentManipulaitonCtr.model getArea:areaId : parentManipulaitonCtr.pageContext.currentPageId];
            
            if (([area.aPath containsPoint:hotspotLocation] && [area.aPath containsPoint:parentManipulaitonCtr.startLocation]) || [areaId isEqualToString:ANYWHERE]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Returns true if a location belongs to an area path. Otherwise, returns false.
 */
- (BOOL)isHotspotOnPath {
    //Check solution only if it exists for the sentence
    if (parentManipulaitonCtr.stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:CHECKPATH]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [parentManipulaitonCtr.model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [parentManipulaitonCtr.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [parentManipulaitonCtr.model getArea:areaId :parentManipulaitonCtr.pageContext.currentPageId];
            
            if ([area.aPath containsPoint:hotspotLocation]) {
                return true;
            }
        }
    }
    
    return false;
}


@end
