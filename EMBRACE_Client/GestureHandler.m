//
//  GestureHandler.m
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import "GestureHandler.h"
#import "ManipulationViewController.h"
#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
#import "Translation.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Statistics.h"
#import "LibraryViewController.h"
#import "NSString+HTML.h"
#import "PageController.h"
#import "SentenceController.h"
#import "SolutionStepController.h"
#import "PossibleInteractionController.h"
#import "ManipulationAnalyser.h"
#import "NSString+MD5.h"

@implementation GestureHandler
@synthesize parentManipulaitonCtr;
/*
 * Tap gesture handles taps on parentManipulaitonCtr.menus, words, images
 */
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:parentManipulaitonCtr.view];
    
    if ((parentManipulaitonCtr.conditionSetup.condition == EMBRACE && (parentManipulaitonCtr.conditionSetup.currentMode == IM_MODE || parentManipulaitonCtr.conditionSetup.currentMode == ITSIM_MODE)) && !parentManipulaitonCtr.allowInteractions) {
        parentManipulaitonCtr.allowInteractions = true;
    }
    
    //Check to see if we have a parentManipulaitonCtr.menu open. If so, process parentManipulaitonCtr.menu click.
    if (parentManipulaitonCtr.menu && parentManipulaitonCtr.allowInteractions) {
        [self tapGestureOnMenu:location];
    }
    //TODO: Figure out how to switch on object vs word type
    else {
        if (parentManipulaitonCtr.stepContext.numSteps > 0 && parentManipulaitonCtr.allowInteractions) {
            [self tapGestureOnObject:location];
        }
        //Capture the clicked text id, if it exists
        NSString *sentenceID = [parentManipulaitonCtr.manipulationView getElementAtLocation:location];
        int sentenceIDNum = [[sentenceID substringFromIndex:0] intValue];
        
        NSString *sentenceText;
        
        //Capture the clicked text, if it exists
        if ([parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO]) {
            //Capture the clicked text, if it exists
            sentenceText = [parentManipulaitonCtr.manipulationView getVocabAtId:sentenceIDNum];
        }
        else if ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"-PM"]) {
            sentenceText = [parentManipulaitonCtr.manipulationView getTextAtLocation:location];
        }
        
        //Convert to lowercase so the sentence text can be mapped to objects
        sentenceText = [sentenceText lowercaseString];
        NSString *englishSentenceText = sentenceText;
        
        //Capture the spanish extension
        NSString *spanishExt = [parentManipulaitonCtr.manipulationView getSpanishExtention:location];
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
            if (![[parentManipulaitonCtr.sc getEnglishTranslation:sentenceText] isEqualToString:NULL_TXT]) {
                englishSentenceText = [parentManipulaitonCtr.sc getEnglishTranslation:sentenceText];
            }
        }
        
        
        //Vocabulary introduction mode
        if ([parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO]) {
            [self tapGestureOnVocabWord: englishSentenceText:sentenceText:sentenceIDNum];
        }
        //Taps on vocab word in story
        else if ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"-PM"] && parentManipulaitonCtr.conditionSetup.isOnDemandVocabEnabled) {
            
            //TODO: REMOVE THIS TEMP HARDCODED FIX
            if([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && [parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO] && [englishSentenceText isEqualToString:@"award"]){
                englishSentenceText = @"prize";
            }
            else if([parentManipulaitonCtr.bookTitle isEqualToString:@"A Celebration to Remember"] && [englishSentenceText isEqualToString:@"pen"]){
                englishSentenceText = @"corral";
                
            }else if([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && [parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO] && [englishSentenceText isEqualToString:@"pen"]){
                englishSentenceText = @"corral";
            }
            
            [self tapGestureOnStoryWord:englishSentenceText:sentenceIDNum:spanishExt:sentenceText];
        }
    }
    
    //Disable user interactions in IM mode
    if ((parentManipulaitonCtr.conditionSetup.condition == EMBRACE && (parentManipulaitonCtr.conditionSetup.currentMode == IM_MODE || parentManipulaitonCtr.conditionSetup.currentMode == ITSIM_MODE)) && parentManipulaitonCtr.allowInteractions) {
        parentManipulaitonCtr.allowInteractions = false;
    }
}

/*
 *  Handles tap gesture on parentManipulaitonCtr.menu items for PM and IM parentManipulaitonCtr.menus
 */
- (void)tapGestureOnMenu:(CGPoint)location {
    parentManipulaitonCtr.allowSnapback = false;
    
    int menuItem = [parentManipulaitonCtr.menu pointInMenuItem:location];
    
    //If we've selected a menuItem.
    if (menuItem != -1) {
        //Get the information from the particular parentManipulaitonCtr.menu item that was pressed.
        MenuItemDataSource *dataForItem = [parentManipulaitonCtr.menuDataSource dataObjectAtIndex:menuItem];
        PossibleInteraction *interaction = [dataForItem interaction];
        
        //Used to store parentManipulaitonCtr.menu item data as strings for logging
        NSMutableArray *menuItemData = [[NSMutableArray alloc] init];
        
        //Go through each connection in the interaction and extract data for logging
        for (Connection *connection in [interaction connections]) {
            NSMutableDictionary *connectionData = [[NSMutableDictionary alloc] init];
            
            NSArray *objects = [connection objects];
            NSString *hotspot = [(Hotspot *)[[connection hotspots] objectAtIndex:0] action];
            NSString *interactionType = [connection returnInteractionTypeAsString];
            
            [connectionData setObject:objects forKey:OBJECTS];
            [connectionData setObject:hotspot forKey:HOTSPOT];
            [connectionData setObject:interactionType forKey:INTERACTIONTYPE];
            
            [menuItemData addObject:connectionData];
        }
        
        [[ServerCommunicationController sharedInstance] logSelectMenuItem:menuItemData atIndex:menuItem context:parentManipulaitonCtr.manipulationContext];
        
        [parentManipulaitonCtr checkSolutionForInteraction:interaction]; //check if selected interact ion is correct
        
        if ((parentManipulaitonCtr.conditionSetup.condition == EMBRACE && (parentManipulaitonCtr.conditionSetup.currentMode == IM_MODE || parentManipulaitonCtr.conditionSetup.currentMode == ITSIM_MODE)) && (parentManipulaitonCtr.allowInteractions)) {
            parentManipulaitonCtr.allowInteractions = FALSE;
        }
        
        //parentManipulaitonCtr.allowSnapback = true;
    }
    //No menuItem was selected
    else {
       [[ServerCommunicationController sharedInstance] logSelectMenuItem:nil atIndex:-1 context:parentManipulaitonCtr.manipulationContext];
    }
    
    //No longer moving object
    parentManipulaitonCtr.movingObject = FALSE;
    parentManipulaitonCtr.movingObjectId = nil;
    parentManipulaitonCtr.allowSnapback = TRUE;
}

/*
 *  Handles tap gesture on vocab words on intro page to play vocab audio and increment step
 */
- (void)tapGestureOnVocabWord:(NSString *)englishSentenceText :(NSString *)sentenceText :(NSInteger)sentenceIDNum {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
    
    if ([currSolSteps count] > 0) {
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:TAPWORD]) {
            if ([[englishSentenceText lowercaseString] containsString: [[currSolStep object1Id] lowercaseString]] &&
                (parentManipulaitonCtr.sentenceContext.currentSentence == sentenceIDNum) && !parentManipulaitonCtr.stepContext.stepsComplete) {
                [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :parentManipulaitonCtr.manipulationContext];
                
                if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                    [[ITSController sharedInstance] userDidVocabPreviewWord:sentenceText context:parentManipulaitonCtr.manipulationContext];
                }
                
                [parentManipulaitonCtr.ssc incrementCurrentStep];
                
                //TODO: REMOVE THIS TEMP HARDCODED FIX
                if([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && [parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO] && [englishSentenceText isEqualToString:@"award"]){
                    [parentManipulaitonCtr playIntroVocabWord:@"prize" :currSolStep];
                }
                else if([parentManipulaitonCtr.bookTitle isEqualToString:@"A Celebration to Remember"] && [englishSentenceText isEqualToString:@"pen"]){
                    [parentManipulaitonCtr playIntroVocabWord:@"corral" :currSolStep];
                    
                }else if([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && [parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO] && [englishSentenceText isEqualToString:@"pen"]){
                    [parentManipulaitonCtr playIntroVocabWord:@"corral" :currSolStep];
                }else{
                    [parentManipulaitonCtr playIntroVocabWord:englishSentenceText :currSolStep];
                }
            }
            else {
                //pressed wrong word
            }
        }
        else {
            //incorrect solution step created for vocabulary page
        }
    }
    else {
        //no vocab steps
    }
}

/*
 *  Handles tap gesture on vocab words in story to play audio
 */
- (void)tapGestureOnStoryWord:(NSString *)englishSentenceText :(NSInteger)sentenceIDNum :(NSString *)spanishExt :(NSString *)sentenceText {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
    
    if (![parentManipulaitonCtr.playaudioClass isAudioLeftInSequence]) {
        BOOL playedAudio = false;
        
        if (currSolSteps != nil && [currSolSteps count] > 0) {
            //Get current step to be completed
            ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
            
            if ([[currSolStep stepType] isEqualToString:TAPWORD]) {
                if (([[currSolStep object1Id] containsString: englishSentenceText] && (parentManipulaitonCtr.sentenceContext.currentSentence == sentenceIDNum)) ||
                    ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"] && parentManipulaitonCtr.conditionSetup.condition == CONTROL && [[currSolStep object1Id] containsString: englishSentenceText] && parentManipulaitonCtr.sentenceContext.currentSentence == 2 && [parentManipulaitonCtr.pageContext.currentPageId containsString:@"-PM-2"]) ||
                    ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"] && parentManipulaitonCtr.conditionSetup.condition == EMBRACE && [[currSolStep object1Id] containsString: englishSentenceText] && (parentManipulaitonCtr.sentenceContext.currentSentence == sentenceIDNum) && parentManipulaitonCtr.sentenceContext.currentSentence != 2 && [parentManipulaitonCtr.pageContext.currentPageId containsString:@"-PM-2"])) {
                    playedAudio = true;
                    [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :parentManipulaitonCtr.manipulationContext];
                    
                    if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                        [[ITSController sharedInstance] userDidPlayWord:sentenceText context:parentManipulaitonCtr.manipulationContext];
                    }
                    
                    [parentManipulaitonCtr.playaudioClass stopPlayAudioFile];
                    
                    
                    [parentManipulaitonCtr playAudioForVocabWord:englishSentenceText :spanishExt];
                    
                    [parentManipulaitonCtr.ssc incrementCurrentStep];
                }
            }
        }
        
        if (!playedAudio && [englishSentenceText length] > 0)// && [[Translation translationWords] objectForKey:englishSentenceText])
        {
            [[ServerCommunicationController sharedInstance] logTapWord:englishSentenceText :parentManipulaitonCtr.manipulationContext];
            
            if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                [[ITSController sharedInstance] userDidPlayWord:englishSentenceText context:parentManipulaitonCtr.manipulationContext];
            }
            
            [parentManipulaitonCtr.playaudioClass stopPlayAudioFile];
            [parentManipulaitonCtr playAudioForVocabWord:englishSentenceText :spanishExt];
        }
    }
}

/*
 *  Handles tap gesture on object
 */
- (void)tapGestureOnObject:(CGPoint)location {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
    
    if ([currSolSteps count] > 0) {
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:TAPTOANIMATE] ||
            [[currSolStep stepType] isEqualToString:SHAKEORTAP] ||
            [[currSolStep stepType] isEqualToString:CHECKANDSWAP]) {
            //Get the object at this point
            NSString *imageAtPoint = [parentManipulaitonCtr getObjectAtPoint:location ofType:nil];
            
            [[ServerCommunicationController sharedInstance] logTapObject:imageAtPoint :parentManipulaitonCtr.manipulationContext];
            
            //If the correct object was tapped, increment the step
            if ([parentManipulaitonCtr.ssc checkSolutionForSubject:imageAtPoint]) {
                [[ServerCommunicationController sharedInstance] logVerification:true forAction:TAP_OBJECT context:parentManipulaitonCtr.manipulationContext];
                
                if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"] &&
                    currSolStep.locationId != nil) {
                    [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:imageAtPoint] destinationIDs:@[currSolStep.locationId] isVerified:true actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                }
                
                if ([[currSolStep stepType] isEqualToString:CHECKANDSWAP]) {
                    [parentManipulaitonCtr swapObjectImage];
                }
                
                [parentManipulaitonCtr.ssc incrementCurrentStep];
            }
        }
    }
}



/*
 * Long press gesture. Either tap or long press can be used for definitions.
 */
//TODO: remove comments
- (IBAction)longPressGesturePerformed:(UILongPressGestureRecognizer *)recognizer {
    //This is the location of the point in the parent UIView, not in the UIWebView.
    //These two coordinate systems may be different.
    /*CGPoint location = [recognizer locationInView:parentManipulaitonCtr.view];
     
     NSString *requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
     
     NSString *imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];*/
    
    //NSLog(@"imageAtPoint: %@", imageAtPoint);
}


/*
 * Pinch gesture. Used to ungroup two images from each other.
 */
- (IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:parentManipulaitonCtr.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan && parentManipulaitonCtr.allowInteractions && parentManipulaitonCtr.pinchToUngroup) {
        parentManipulaitonCtr.pinching = TRUE;
        
        NSString *imageAtPoint = [parentManipulaitonCtr getObjectAtPoint:location ofType:MANIPULATIONOBJECT];
        
        //if it's an image that can be moved, then start moving it.
        if (imageAtPoint != nil && !parentManipulaitonCtr.stepContext.stepsComplete) {
            parentManipulaitonCtr.separatingObjectId = imageAtPoint;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        //Get pairs of other objects grouped with this object.
        NSArray *itemPairArray = [parentManipulaitonCtr getObjectsGroupedWithObject:parentManipulaitonCtr.separatingObjectId];
        
        if (itemPairArray != nil) {
            NSMutableArray *possibleInteractions = [[NSMutableArray alloc] init];
            
            for (NSString *pairStr in itemPairArray) {
                //Create an array that will hold all the items in this group
                NSMutableArray *groupedItemsArray = [[NSMutableArray alloc] init];
                
                //Separate the objects in this pair and add them to our array of all items in this group.
                [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
                
                //Only allow the correct subject and object to ungroup if necessary
                BOOL allowSubjectToUngroup = false;
                BOOL allowObjectToUngroup = false;
                
                for (NSString *obj in groupedItemsArray) {
                    if (parentManipulaitonCtr.useSubject == ONLY_CORRECT) {
                        if ([parentManipulaitonCtr.ssc checkSolutionForSubject:obj]) {
                            allowSubjectToUngroup = true;
                        }
                    }
                    else if (parentManipulaitonCtr.useSubject == ALL_ENTITIES) {
                        allowSubjectToUngroup = true;
                    }
                    
                    if (parentManipulaitonCtr.useObject == ONLY_CORRECT) {
                        if ([parentManipulaitonCtr.ssc checkSolutionForObject:obj]) {
                            allowObjectToUngroup = true;
                        }
                    }
                    else if (parentManipulaitonCtr.useObject == ALL_ENTITIES) {
                        allowObjectToUngroup = true;
                    }
                }
                
                //Objects are allowed to ungroup
                if (allowSubjectToUngroup && allowObjectToUngroup) {
                    PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:UNGROUP];
                    [interaction addConnection:UNGROUP :groupedItemsArray :nil];
                    
                    //Only one possible ungrouping found
                    if ([itemPairArray count] == 1) {
                        [parentManipulaitonCtr checkSolutionForInteraction:interaction]; //check if interaction is correct before ungrouping
                    }
                    //Multiple possible ungroupings found
                    else {
                        [possibleInteractions addObject:interaction];
                    }
                }
            }
            
            //Show the parentManipulaitonCtr.menu if multiple possible ungroupings are found
            if ([itemPairArray count] > 1) {
                //Populate the data source and expand the parentManipulaitonCtr.menu.
                [parentManipulaitonCtr populateMenuDataSource:possibleInteractions:parentManipulaitonCtr.allRelationships];
                
                if (!parentManipulaitonCtr.menuExpanded)
                    [parentManipulaitonCtr expandMenu];
            }
        }
        else
            NSLog(@"no items grouped");
        
        parentManipulaitonCtr.pinching = FALSE;
    }
}

/*
 * Handles beginning of a pan gesture
 */
- (void)panGestureBegan:(CGPoint)location {
    //Starts true because the object starts within the area
    parentManipulaitonCtr.wasPathFollowed = true;
    parentManipulaitonCtr.panning = TRUE;
    
    //Get the object at that point if it's a manipulation object.
    NSString *imageAtPoint = [parentManipulaitonCtr getObjectAtPoint:location ofType:MANIPULATIONOBJECT];
    
    //If it's an image that can be moved, then start moving it.
    if (imageAtPoint != nil && !parentManipulaitonCtr.stepContext.stepsComplete) {
        parentManipulaitonCtr.movingObject = TRUE;
        parentManipulaitonCtr.movingObjectId = imageAtPoint;
        
        NSString *imageMarginLeft = [parentManipulaitonCtr.manipulationView imageMarginLeft:parentManipulaitonCtr.movingObjectId];
        NSString *imageMarginTop = [parentManipulaitonCtr.manipulationView imageMarginTop:parentManipulaitonCtr.movingObjectId];
        
        if (![imageMarginLeft isEqualToString:EMPTYSTRING] && ![imageMarginTop isEqualToString:EMPTYSTRING]) {
            //Calulate offset between top-left corner of image and the point clicked for centered images
            parentManipulaitonCtr.delta = [parentManipulaitonCtr calculateDeltaForMovingObjectAtPointWithCenter:parentManipulaitonCtr.movingObjectId :location];
        }
        else {
            //Calculate offset between top-left corner of image and the point clicked.
            parentManipulaitonCtr.delta = [parentManipulaitonCtr calculateDeltaForMovingObjectAtPoint:location];
        }
        
        //Record the starting location of the object when it is selected
        parentManipulaitonCtr.startLocation = CGPointMake(location.x - parentManipulaitonCtr.delta.x, location.y - parentManipulaitonCtr.delta.y);
        
        if ([parentManipulaitonCtr.animatingObjects objectForKey:imageAtPoint] && [[parentManipulaitonCtr.animatingObjects objectForKey:imageAtPoint] containsString: ANIMATE]) {
            
            NSArray *animation = [[parentManipulaitonCtr.animatingObjects objectForKey:imageAtPoint] componentsSeparatedByString: @","];
            NSString *animationType = animation[1];
            NSString *animationAreaId = animation[2];
            
            [parentManipulaitonCtr.manipulationView animateObject:imageAtPoint from:parentManipulaitonCtr.startLocation to:CGPointZero action:@"pauseAnimation" areaId:EMPTYSTRING];
            
            [parentManipulaitonCtr.animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", PAUSE, animationType, animationAreaId]  forKey:imageAtPoint];
        }
    }
}

/*
 * Handles the end of a pan gesture
 */
- (void)panGestureEnded:(CGPoint)location {
    parentManipulaitonCtr.panning = FALSE;
    BOOL useProximity = NO;
    
    //If moving object, move object to final position.
    if (parentManipulaitonCtr.movingObject) {
        [parentManipulaitonCtr moveObject:parentManipulaitonCtr.movingObjectId :location :parentManipulaitonCtr.delta :true];
        NSArray *overlappingWith = [parentManipulaitonCtr getObjectsOverlappingWithObject:parentManipulaitonCtr.movingObjectId];
        
        if (parentManipulaitonCtr.stepContext.numSteps > 0) {
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [parentManipulaitonCtr.ssc returnCurrentSolutionSteps];
            
            //Get current step to be completed
            ActionStep *currSolStep = [currSolSteps objectAtIndex:parentManipulaitonCtr.stepContext.currentStep - 1];
            
            //If correct step is of type check
            if ([[currSolStep stepType] isEqualToString:CHECK] ||
                [[currSolStep stepType] isEqualToString:CHECKLEFT] ||
                [[currSolStep stepType] isEqualToString:CHECKRIGHT] ||
                [[currSolStep stepType] isEqualToString:CHECKUP] ||
                [[currSolStep stepType] isEqualToString:CHECKDOWN]) {
                //Check if object is in the correct location or area
                if ((([[currSolStep stepType] isEqualToString:CHECKLEFT] && parentManipulaitonCtr.startLocation.x > parentManipulaitonCtr.endLocation.x ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKRIGHT] && parentManipulaitonCtr.startLocation.x < parentManipulaitonCtr.endLocation.x ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKUP] && parentManipulaitonCtr.startLocation.y > parentManipulaitonCtr.endLocation.y ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKDOWN] && parentManipulaitonCtr.startLocation.y < parentManipulaitonCtr.endLocation.y )) ||
                    ([parentManipulaitonCtr.hotSpotHandler isHotspotInsideLocation:false] || [parentManipulaitonCtr.hotSpotHandler isHotspotInsideArea])) {
                    
                    if ([parentManipulaitonCtr.ssc checkSolutionForSubject:parentManipulaitonCtr.movingObjectId]) {
                        NSString *destination;
                        
                        if ([currSolStep locationId] != nil) {
                            destination = [currSolStep locationId];
                        }
                        else if ([currSolStep areaId] != nil) {
                            destination = [currSolStep areaId];
                        }
                        else {
                            destination = NULL_TXT;
                        }
                        
                        [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:destination ofType:LOCATION startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                        
                        [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:parentManipulaitonCtr.manipulationContext];
                        
                        if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                            [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:@[destination] isVerified:true actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                        }
                        
                        [parentManipulaitonCtr.animatingObjects setObject:STOP forKey:parentManipulaitonCtr.movingObjectId];
                        [parentManipulaitonCtr.ssc incrementCurrentStep];
                    }
                    //Reset object location
                    else {
                        [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                        
                        if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                            [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                        }
                        
                        [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                    }
                }
                else {
                    [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                    
                    // Find the location if overlapping is nil;
                    if (overlappingWith == nil) {
                        NSString *areaId = [parentManipulaitonCtr.model getObjectIdAtLocation:parentManipulaitonCtr.endLocation];
                        
                        if (areaId)
                            overlappingWith = @[areaId];
                        
                    }
                    
                    if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                        [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                    }
                    
                    [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                }
            }
            else if ([[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
                [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                
                if ([parentManipulaitonCtr.ssc checkSolutionForSubject:parentManipulaitonCtr.movingObjectId] && ([parentManipulaitonCtr.hotSpotHandler areHotspotsInsideArea] || [parentManipulaitonCtr.hotSpotHandler isHotspotInsideLocation:false])) {
                    [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:parentManipulaitonCtr.manipulationContext];
                    
                    [parentManipulaitonCtr.animatingObjects setObject:STOP forKey:parentManipulaitonCtr.movingObjectId];
                    
                    if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                        [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:@[currSolStep.locationId] isVerified:true actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                    }
                    
                    [parentManipulaitonCtr resetObjectLocation];
                    [parentManipulaitonCtr.ssc incrementCurrentStep];
                }
                else {
                    if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                        
                        [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:@[currSolStep.locationId] isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                    }
                    
                    [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                }
            }
            else if ([[currSolStep stepType] isEqualToString:CHECKPATH]) {
                [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                
                if (parentManipulaitonCtr.wasPathFollowed) {
                    [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:parentManipulaitonCtr.manipulationContext];
                    
                    [parentManipulaitonCtr.animatingObjects setObject:STOP forKey:parentManipulaitonCtr.movingObjectId];
                    [parentManipulaitonCtr.ssc incrementCurrentStep];
                }
                else {
                    [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                }
            }
            else {
                //Check if the object is overlapping anything
                NSArray *overlappingWith = [parentManipulaitonCtr getObjectsOverlappingWithObject:parentManipulaitonCtr.movingObjectId];
                
                //Get possible interactions only if the object is overlapping something
                if (overlappingWith != nil) {
                    [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:[overlappingWith componentsJoinedByString:@", "] ofType:OBJECT startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                    
                    //Resets allRelationship arrray
                    if ([parentManipulaitonCtr.allRelationships count]) {
                        [parentManipulaitonCtr.allRelationships removeAllObjects];
                    }
                    
                    //If the object was dropped, check if it's overlapping with any other objects that it could interact with.
                    NSMutableArray *possibleInteractions = [parentManipulaitonCtr getPossibleInteractions:useProximity];
                    
                    //No possible interactions were found
                    if ([possibleInteractions count] == 0) {
                        if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                            [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                        }
                        
                        [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                    }
                    //If only 1 possible interaction was found, go ahead and perform that interaction if it's correct.
                    else if ([possibleInteractions count] == 1) {
                        PossibleInteraction *interaction = [possibleInteractions objectAtIndex:0];
                        
                        //Checks solution and accomplishes action trace
                        [parentManipulaitonCtr checkSolutionForInteraction:interaction];
                    }
                    //If more than 1 was found, prompt the user to disambiguate.
                    else if ([possibleInteractions count] > 1) {
                        PossibleInteraction* correctInteraction = [parentManipulaitonCtr.pic getCorrectInteraction];
                        BOOL correctInteractionExists = false;
                        
                        //Look for the correct interaction
                        for (int i = 0; i < [possibleInteractions count]; i++) {
                            if ([[possibleInteractions objectAtIndex:i] isEqual:correctInteraction]) {
                                correctInteractionExists = true;
                            }
                        }
                        
                        //Only populate Menu if user is moving the correct object to the correct objects
                        if (correctInteractionExists) {
                            //TODO: add a parameter check
                            if (!parentManipulaitonCtr.menuExpanded && [PM_CUSTOM isEqualToString:[currSolStep menuType]]) {
                                //Reset allRelationships arrray
                                if ([parentManipulaitonCtr.allRelationships count]) {
                                    [parentManipulaitonCtr.allRelationships removeAllObjects];
                                }
                                
                                PossibleInteraction *interaction;
                                NSMutableArray *interactions = [[NSMutableArray alloc]init ];
                                
                                if (currSolSteps.count != 0 && (currSolSteps.count + 1 - parentManipulaitonCtr.stepContext.currentStep) >= minMenuItems) {
                                    for (int i = (int)(parentManipulaitonCtr.stepContext.currentStep - 1); i < (parentManipulaitonCtr.stepContext.currentStep - 1 + minMenuItems); i++) {
                                        ActionStep *currSolStep = currSolSteps[i];
                                        interaction = [parentManipulaitonCtr convertActionStepToPossibleInteraction:currSolStep];
                                        [interactions addObject:interaction];
                                        Relationship *relationshipBetweenObjects = [[Relationship alloc] initWithValues:[currSolStep object1Id] : [currSolStep action] : [currSolStep stepType] : [currSolStep object2Id]];
                                        [parentManipulaitonCtr.allRelationships addObject:relationshipBetweenObjects];
                                    }
                                    
                                    interactions = [parentManipulaitonCtr shuffleMenuOptions: interactions];
                                    
                                    //Populate the parentManipulaitonCtr.menu data source and expand the parentManipulaitonCtr.menu.
                                    [parentManipulaitonCtr populateMenuDataSource:interactions :parentManipulaitonCtr.allRelationships];
                                    [parentManipulaitonCtr expandMenu];
                                }
                                else {
                                    //TODO: log error
                                }
                            }
                            else if (!parentManipulaitonCtr.menuExpanded) {
                                //First rank the interactions based on location to story.
                                [parentManipulaitonCtr.pic rankPossibleInteractions:possibleInteractions];
                                
                                //Populate the parentManipulaitonCtr.menu data source and expand the parentManipulaitonCtr.menu.
                                [parentManipulaitonCtr populateMenuDataSource:possibleInteractions :parentManipulaitonCtr.allRelationships];
                                [parentManipulaitonCtr expandMenu];
                            }
                            else {
                                //TODO: add log statement
                            }
                        }
                        //Otherwise reset object location and play error noise
                        else {
                            if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                                [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                            }
                            
                            [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                        }
                    }
                }
                //Not overlapping any object
                else {
                    [[ServerCommunicationController sharedInstance] logMoveObject:parentManipulaitonCtr.movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:parentManipulaitonCtr.startLocation endPos:parentManipulaitonCtr.endLocation performedBy:USER context:parentManipulaitonCtr.manipulationContext];
                    
                    // Find the location if overlapping is nil;
                    if (overlappingWith == nil) {
                        //TODO: Find the object precent in destination location.
                        NSString *areaId = [parentManipulaitonCtr.model getObjectIdAtLocation:parentManipulaitonCtr.endLocation];
                        
                        if (areaId)
                            overlappingWith = @[areaId];
                        
                    }
                    
                    if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
                        [[ITSController sharedInstance] movedObjectIDs:[parentManipulaitonCtr.manipulationView getSetOfObjectsGroupedWithObject:parentManipulaitonCtr.movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:parentManipulaitonCtr.manipulationContext forSentence:parentManipulaitonCtr.sentenceContext.currentSentenceText withWordMapping:parentManipulaitonCtr.model.wordMapping];
                    }
                    
                    [parentManipulaitonCtr handleErrorForAction:MOVE_OBJECT];
                }
            }
        }
        
        if (!parentManipulaitonCtr.menuExpanded) {
            //No longer moving object
            parentManipulaitonCtr.movingObject = FALSE;
            parentManipulaitonCtr.movingObjectId = nil;
        }
        
        [parentManipulaitonCtr.manipulationView clearAllHighLighting];
    }
}

/*
 * Handles a pan gesture in progress
 */
- (void)panGestureInProgress:(UIPanGestureRecognizer *)recognizer :(CGPoint)location {
    [parentManipulaitonCtr moveObject:parentManipulaitonCtr.movingObjectId :location :parentManipulaitonCtr.delta :true];
    
    //If we're overlapping with another object, then we need to figure out which hotspots are currently active and highlight those hotspots.
    //When moving the object, we may have the JS return a list of all the objects that are currently grouped together so that we can process all of them.
    NSArray *overlappingWith = [parentManipulaitonCtr getObjectsOverlappingWithObject:parentManipulaitonCtr.movingObjectId];
    
    if (overlappingWith != nil) {
        for (NSString *objId in overlappingWith) {
            //We have the list of objects it's overlapping with, we now have to figure out which hotspots to draw.
            NSMutableArray *hotspots = [parentManipulaitonCtr.model getHotspotsForObject:objId OverlappingWithObject:parentManipulaitonCtr.movingObjectId];
            
            //Since hotspots are filtered based on relevant relationships between objects, only highlight objects that have at least one hotspot returned by the model.
            if ([hotspots count] > 0) {
                [parentManipulaitonCtr.manipulationView highLightObject:objId];
            }
        }
    }
}

/*
 * Pan gesture. Used to move objects from one location to another.
 */
- (IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    //get current coordinate point of gesture
    CGPoint location = [recognizer locationInView:parentManipulaitonCtr.view];
    
    //TODO: pinchig functionality currently not utilized
    if (!parentManipulaitonCtr.pinching && parentManipulaitonCtr.allowInteractions) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [self panGestureBegan: location];
        }
        //Pangesture has ended: user has removed finger from
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            [self panGestureEnded: location];
        }
        //If we're in the middle of moving the object, just call the JS to move it.
        else if (parentManipulaitonCtr.movingObject)  {
            [self panGestureInProgress:recognizer:location];
        }
    }
}

@end
