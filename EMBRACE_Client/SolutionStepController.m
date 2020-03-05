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
    
    if (conditionSetup.appMode == ITS && ![pageContext.currentPageId containsString:DASH_INTRO] && !([pageContext.currentPageId.lowercaseString containsString:@"story1"])) {
        if (sentenceContext.currentSentence > 0) {
            currSolSteps = [[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] solutionSteps];
        }
    }
    else {
        if (conditionSetup.condition == CONTROL) {
            currSolSteps = [stepContext.PMSolution getStepsForSentence:sentenceContext.currentSentence];
        }
        else if (conditionSetup.condition == EMBRACE) {
            if (conditionSetup.currentMode == ITSPM_MODE && [pageContext.currentPageId rangeOfString:DASH_INTRO].location == NSNotFound) {
                    currSolSteps = [stepContext.ITSPMSolution getStepsForSentence:sentenceContext.currentIdea];
            }
            else if(conditionSetup.currentMode == ITSPM_MODE && [pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound){
                currSolSteps = [stepContext.ITSPMSolution getStepsForSentence:sentenceContext.currentSentence];
            }
            else if(conditionSetup.currentMode == PM_MODE){
                    currSolSteps = [stepContext.PMSolution getStepsForSentence:sentenceContext.currentSentence];
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                currSolSteps = [stepContext.IMSolution getStepsForSentence:sentenceContext.currentSentence];
            }
            else if (conditionSetup.currentMode == ITSIM_MODE && [pageContext.currentPageId containsString:DASH_INTRO] == NSNotFound) {
                currSolSteps = [stepContext.ITSIMSolution getStepsForSentence:sentenceContext.currentIdea];
            }
            else if (conditionSetup.currentMode == ITSIM_MODE && [pageContext.currentPageId containsString:DASH_INTRO] != NSNotFound) {
                currSolSteps = [stepContext.ITSIMSolution getStepsForSentence:sentenceContext.currentSentence];
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
    Language preLanguage=conditionSetup.language;
    NSString* is004=[[NSUserDefaults standardUserDefaults] stringForKey:@"004"];
    if ( [is004 isEqualToString:@"YES"]){
        conditionSetup.language = BILINGUAL;
    }
    
    Chapter *chapter = [mvc.book getChapterWithTitle:mvc.chapterTitle];
    BOOL shouldSkip=NO;
    NSMutableSet *newVocab = [[NSMutableSet alloc] init];
    NSMutableArray *vocabSolutionSteps = [[NSMutableArray alloc] init];
    
    // Adds new vocabulary introduced in the chapter
    for (int i = 1; i < sentenceContext.totalSentences + 1; i++) {
        NSString *vocabText = [[mvc.manipulationView getVocabAtId:i] lowercaseString];
        
        if (conditionSetup.language == BILINGUAL) {
            if (![[mvc.sc getEnglishTranslation:vocabText] isEqualToString:NULL_TXT]) {
                vocabText = [mvc.sc getEnglishTranslation:vocabText];
            }
        }
        
        [newVocab addObject:vocabText];
            ActionStep *vocabSolutionStep = [[ActionStep alloc] initAsSolutionStep:i :nil :1 :@"tapWord" :vocabText :nil :nil :nil :nil :nil :nil];
            [vocabSolutionSteps addObject:vocabSolutionStep];
    }
    

    BOOL isExtraIntropage=NO;
    if(0==[newVocab count]){
        isExtraIntropage=YES;
    }
    
    
    
    if (conditionSetup.appMode == ITS && conditionSetup.useKnowledgeTracing && ![mvc.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
        NSMutableSet *vocabToAdd = [[ITSController sharedInstance] getExtraIntroductionVocabularyForChapter:chapter inBook:mvc.book];
        [vocabToAdd minusSet:newVocab];
        if (isExtraIntropage&& 0==[vocabToAdd count]){
            shouldSkip=YES;
        }
        
        [[ServerCommunicationController sharedInstance] logAdaptVocabulary:[NSArray arrayWithArray:[vocabToAdd allObjects]] context:manipulationContext];
        
        for (NSString *vocab in vocabToAdd) {
            sentenceContext.totalSentences++;
            
            NSString *englishText = vocab;
            NSString *spanishText = [NSString stringWithFormat:@""];
            
            if (conditionSetup.language == BILINGUAL) {
                if (![[mvc.sc getEnglishTranslation:vocab] isEqualToString:NULL_TXT]) {
                    englishText = [mvc.sc getEnglishTranslation:vocab];
                    spanishText = vocab;
                }
                else if(![[mvc.sc getSpanishTranslation:vocab] isEqualToString:NULL_TXT]){
                    englishText = vocab;
                    spanishText = [mvc.sc getSpanishTranslation:vocab];
                }
                else{
                    englishText = vocab;
                    spanishText = vocab;
                }
            }
            
            [mvc.manipulationView addVocabularyWithID:sentenceContext.totalSentences englishText:englishText spanishText:spanishText];
            
            ActionStep *vocabSolutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceContext.totalSentences :nil :1 :@"tapWord" :englishText :nil :nil :nil :nil :nil :nil];
            [vocabSolutionSteps addObject:vocabSolutionStep];
        }
    }
    
    if (conditionSetup.currentMode == PM_MODE || conditionSetup.condition == CONTROL) {
        stepContext.PMSolution = [[PhysicalManipulationSolution alloc] init];
        stepContext.PMSolution.solutionSteps = vocabSolutionSteps;
        
        PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE];
        [PMActivity addPMSolution:stepContext.PMSolution forActivityId:pageContext.currentPageId];
    }
    else if (conditionSetup.currentMode == ITSPM_MODE) {
        
        stepContext.ITSPMSolution = [[ITSPhysicalManipulationSolution alloc] init];
        stepContext.ITSPMSolution.solutionSteps = vocabSolutionSteps;
        
        ITSPhysicalManipulationActivity *ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE];
        [ITSPMActivity addITSPMSolution:stepContext.ITSPMSolution forActivityId:pageContext.currentPageId];
    }
    else if (conditionSetup.currentMode == IM_MODE) {
        stepContext.IMSolution = [[ImagineManipulationSolution alloc] init];
        stepContext.IMSolution.solutionSteps = vocabSolutionSteps;
        
        ImagineManipulationActivity *IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE];
        [IMActivity addIMSolution:stepContext.IMSolution forActivityId:pageContext.currentPageId];
    }
    else if (conditionSetup.currentMode == ITSIM_MODE) {
        stepContext.ITSIMSolution = [[ITSImagineManipulationSolution alloc] init];
        stepContext.ITSIMSolution.solutionSteps = vocabSolutionSteps;
        
        ITSImagineManipulationActivity *ITSIMActivity = (ITSImagineManipulationActivity *)[chapter getActivityOfType:ITSIM_MODE];
        [ITSIMActivity addITSIMSolution:stepContext.ITSIMSolution forActivityId:pageContext.currentPageId];
    }
    
    NSMutableSet *vocabToAdd = [[ITSController sharedInstance] getExtraIntroductionVocabularyForChapter:chapter inBook:mvc.book];
    [vocabToAdd minusSet:newVocab];
    if (isExtraIntropage&& 0==[vocabToAdd count]){
        shouldSkip=YES;
    }
    if( Study== conditionSetup.appMode && isExtraIntropage){
        shouldSkip=YES;
    }
    if(shouldSkip){
        [mvc SkipIntro];
    }
    
    
    conditionSetup.language=preLanguage;
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
    
    //Check if we able to increment current step
    if (stepContext.currentStep < stepContext.numSteps) {
        stepContext.numAttempts = 0;
        
        if (conditionSetup.appMode == ITS && conditionSetup.useKnowledgeTracing && ![[manipulationContext chapterTitle] isEqualToString:@"The Naughty Monkey"]) {
            stepContext.numSyntaxErrors = 0;
            [[ITSController sharedInstance] resetSyntaxErrorCountWithContext:manipulationContext];
        }
        
        //if the current solution step is a custom pm, then increment current step minMenuOption times
        if ([PM_CUSTOM isEqualToString:[currSolStep menuType]]) {
            for (int i = 0; i < minMenuItems; i++) {
                stepContext.currentStep++;
            }
        }
        //current solution step is normal and just increment once
        else {
            stepContext.currentStep++;
        }
        
        manipulationContext.stepNumber = stepContext.currentStep;
        if(!mvc.allowInteractions) {
            mvc.allowInteractions = YES;
            [mvc performAutomaticSteps]; //automatically perform ungroup or move steps if necessary
            mvc.allowInteractions = NO;
        }
        else{
            [mvc performAutomaticSteps]; //automatically perform ungroup or move steps if necessary
        }
    }
    else {
        stepContext.stepsComplete = TRUE; //no more steps to complete
    }
}

@end
