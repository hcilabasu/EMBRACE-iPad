//
//  SolutionStepController.m
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SolutionStepController.h"
#import "SentenceController.h"
#import "PossibleInteractionController.h"
#import "Statistics.h"
#import "PieContextualMenu.h"

@implementation SolutionStepController

@synthesize mvc;
@synthesize stepContext;
@synthesize conditionSetup;
@synthesize pageContext;
@synthesize sentenceContext;
@synthesize manipulationContext;

-(id)initWithController:(ManipulationViewController *) superMvc {
    self = [super init];
    
    if (self) {
        //Create local Pointers to needed classes, variables and properties within mvc
        self.mvc = superMvc;
        self.stepContext = mvc.stepContext;
        self.conditionSetup = mvc.conditionSetup;
        self.pageContext = mvc.pageContext;
        self.sentenceContext = mvc.sentenceContext;
        self.manipulationContext = mvc.manipulationContext;
    }
    
    return self;
}

/*
 * Returns true if the correct object is selected as the subject based on the solutions
 * for group step types. Otherwise, it returns false.
 */
- (BOOL)checkSolutionForSubject:(NSString *)subject {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0 && !stepContext.stepsComplete) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT]) {
            //Get next sentence step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            //Correct subject for a transfer and group step is the obj1 of the next transfer and group step
            NSString *correctSubject = [nextSolStep object1Id];
            
            //Selected object is the correct subject
            if ([correctSubject isEqualToString:subject]) {
                return true;
            }
            else {
                //Check if selected object is in a group with the correct subject
                BOOL isSubjectInGroup = [mvc isSubject:correctSubject ContainedInGroupWithObject:subject];
                return isSubjectInGroup;
            }
        }
        else {
            NSString *correctSubject = [currSolStep object1Id];
            
            //Selected object is the correct subject
            if ([correctSubject isEqualToString:subject]) {
                return true;
            }
            else {
                //Check if selected object is in a group with the correct subject
                BOOL isSubjectInGroup = [mvc isSubject:correctSubject ContainedInGroupWithObject:subject];
                return isSubjectInGroup;
            }
        }
    }
    else {
        stepContext.stepsComplete = TRUE; //no steps to complete for current sentence
        
        //User cannot move anything if there are no steps to be performed
        return false;
    }
}

/*
 * Returns true if the active object is overlapping the correct object based on the solutions.
 * Otherwise, it returns false.
 */
- (BOOL)checkSolutionForObject:(NSString *)overlappingObject {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        //If current step requires transference and group, the correct object depends on the format used.
        //transferAndGroup steps may be written in two different ways:
        //   1. obj2Id is the same for both steps, so correct object is object1 of next step
        //      (ex. farmer give bucket; cat accept bucket)
        //   2. obj2Id of first step is obj1Id of second step, so correct object is object2 of next step
        //      (ex. farmer putDown hay; hay getIn cart)
        if ([[currSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT]) {
            //Get next step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            if ([[currSolStep object2Id] isEqualToString:[nextSolStep object2Id]]) {
                if ([overlappingObject isEqualToString:[nextSolStep object1Id]]) {
                    return true;
                }
            }
            else {
                if ([overlappingObject isEqualToString:[nextSolStep object2Id]]) {
                    return true;
                }
            }
        }
        //If current step requires transference and disapppear, the correct object should be the object1 of the next step
        else if ([[currSolStep stepType] isEqualToString:TRANSFERANDDISAPPEAR_TXT]) {
            //Get next step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            if ([overlappingObject isEqualToString:[nextSolStep object1Id]]) {
                return true;
            }
        }
        else {
            if ([overlappingObject isEqualToString:[currSolStep object2Id]]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Moves an object to another object or waypoint for move step types
 */
- (void)moveObjectForSolution {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:MOVE]) {
            //Get information for move step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *object2Id = [currSolStep object2Id];
            NSString *waypointId = [currSolStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction *correctInteraction = [mvc.pic getCorrectInteraction];
                [mvc.pic performInteraction:correctInteraction]; //performs solution step
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot *hotspot = [mvc.model getHotspotforObjectWithActionAndRole:object1Id :action :SUBJECT];
                CGPoint hotspotLocation = [mvc getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint *waypoint = [mvc.model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [mvc getWaypointLocation:waypoint];
                
                if ([mvc.manipulationView isObjectCenter:object1Id]) {
                    hotspotLocation.x = 0;
                    hotspotLocation.y = 0;
                }
                
                //Move the object
                [mvc moveObject:object1Id :waypointLocation :hotspotLocation :false];
                
                //Clear highlighting
                [mvc.manipulationView clearAllHighLighting];
                
                [[ServerCommunicationController sharedInstance] logMoveObject:object1Id toDestination:[waypoint waypointId] ofType:WAYPOINT startPos:mvc.startLocation endPos:waypointLocation performedBy:SYSTEM context:manipulationContext];
            }
        }
    }
}

/*
 *  Returns an array of solution steps for the current sentence based on the condition
 */
- (NSMutableArray *)returnCurrentSolutionSteps {
    NSMutableArray *currSolSteps;
    
    if (conditionSetup.appMode == ITS) {
        currSolSteps = [[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] solutionSteps];
    }
    else {
        if (conditionSetup.condition == CONTROL) {
            currSolSteps = [stepContext.PMSolution getStepsForSentence:sentenceContext.currentSentence];
        }
        else if (conditionSetup.condition == EMBRACE) {
            if (conditionSetup.currentMode == PM_MODE) {
                //NOTE: Currently hardcoded because The Best Farm Solutions-MetaData.xml is different format from other stories
                if ([mvc.bookTitle rangeOfString:@"The Best Farm"].location != NSNotFound &&
                    [pageContext.currentPageId rangeOfString:DASH_INTRO].location == NSNotFound) {
                    currSolSteps = [stepContext.PMSolution getStepsForSentence:sentenceContext.currentIdea];
                }
                else {
                    currSolSteps = [stepContext.PMSolution getStepsForSentence:sentenceContext.currentSentence];
                }
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                currSolSteps = [stepContext.IMSolution getStepsForSentence:sentenceContext.currentSentence];
            }
        }
    }
    
    return currSolSteps;
}

/*
 * Gets the current solution step and returns it
 */
- (NSString *)getCurrentSolutionStep {
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        //If step type involves transference, we must manually create the PossibleInteraction object.
        //Otherwise, it can be directly converted.
        return [currSolStep stepType];
    }
    else {
        return nil;
    }
}

/*
 * Dynamically creates pm and im vocab solutions for an intro page
 */
- (void)createVocabSolutionsForPage {
    
    stepContext.PMSolution = [[PhysicalManipulationSolution alloc] init];
    stepContext.IMSolution = [[ImagineManipulationSolution alloc] init];
    
    for (int i = 1; i < sentenceContext.totalSentences + 1; i++) {
        
        NSString *sentenceText = [[mvc.manipulationView getVocabAtId:i] lowercaseString];
        
        if (conditionSetup.language == BILINGUAL) {
            if (![[mvc.sc getEnglishTranslation:sentenceText] isEqualToString:NULL_TXT]) {
                sentenceText = [mvc.sc getEnglishTranslation:sentenceText];
            }
        }
        
        ActionStep *solutionStep = [[ActionStep alloc] initAsSolutionStep:i :nil : 1 : TAPWORD : sentenceText : nil : nil: nil : nil : nil : nil];
        
        if (conditionSetup.currentMode == PM_MODE || conditionSetup.condition == CONTROL) {
            [stepContext.PMSolution addSolutionStep:solutionStep];
        }
        else if (conditionSetup.currentMode == IM_MODE) {
            [stepContext.IMSolution addSolutionStep:solutionStep];
        }
    }
    
    Chapter *chapter = [mvc.book getChapterWithTitle:mvc.chapterTitle]; //get current chapter
    
    //Add PMSolution to page
    if (conditionSetup.currentMode == PM_MODE || conditionSetup.condition == CONTROL) {
        PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
        [PMActivity addPMSolution:stepContext.PMSolution forActivityId:pageContext.currentPageId];
    }
    //Add IMSolution to page
    else if (conditionSetup.currentMode == IM_MODE) {
        ImagineManipulationActivity *IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE]; //get IM Activity only
        [IMActivity addIMSolution:stepContext.IMSolution forActivityId:pageContext.currentPageId];
    }
}

/*
 * Moves to next step in a sentence if possible. The step is performed automatically
 * if it is ungroup, move, or swap image.
 */
- (void)incrementCurrentStep {
    //TODO: change currSolSteps && currSolStep to private and accessible to all functions in this view controller
    
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
    
    //Get current step to be completed
    ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
    
    if (conditionSetup.appMode == ITS) {
        //Not automatic step
        if (!([[currSolStep stepType] isEqualToString:UNGROUP_TXT] || [[currSolStep stepType] isEqualToString:MOVE] || [[currSolStep stepType] isEqualToString:SWAPIMAGE])) {
            mvc.endTime = [NSDate date];
            double elapsedTime = [mvc.endTime timeIntervalSinceDate:mvc.startTime];
            
            //Record time for complexity
            [[mvc.pageStatistics objectForKey:pageContext.currentPageId] addTime:elapsedTime ForComplexity:(mvc.currentComplexity - 1)];
            
            mvc.startTime = [NSDate date];
        }
    }
    
    //Check if we able to increment current step
    if (stepContext.currentStep < stepContext.numSteps) {
        
        //if the current solution step is a custom pm, then increment current step minMenuOption times
        if ([PM_CUSTOM isEqualToString: [currSolStep menuType]]){
            for (int i=0; i<minMenuItems; i++) {
                stepContext.currentStep++;
            }
        }
        //current solution step is normal and just increment once
        else{
            stepContext.currentStep++;
        }
        
        manipulationContext.stepNumber = stepContext.currentStep;
        [mvc performAutomaticSteps]; //automatically perform ungroup or move steps if necessary
    }
    else {
        stepContext.stepsComplete = TRUE; //no more steps to complete
    }
}

@end
