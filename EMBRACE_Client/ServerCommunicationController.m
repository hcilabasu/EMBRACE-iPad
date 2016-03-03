//
//  ServerCommunicationController.m
//  EMBRACE
//
//  Created by Rishabh Chaudhry on 12/17/13.
//  Copyright (c)2013 Andreea Danielescu. All rights reserved.
//

#import "ServerCommunicationController.h"
#import "GDataXMLNode.h"

@interface ServerCommunicationController () {
    NSInteger userActionID; //current user action number
    
    DDXMLDocument *xmlDocTemp;
    DDXMLElement *study;
    
    NSString *studyFileName; //name of current log file
    
    NSString *studyCondition;
    NSString *studySchoolCode;
    NSString *studyParticipantCode;
    NSString *studyDay;
    NSString *studyExperimenterName;
}

@end

@implementation ServerCommunicationController

+ (id)sharedManager {
    static ServerCommunicationController *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        
    });
    
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]){
        xmlDocTemp = [[DDXMLDocument alloc] initWithXMLString:@"<study/>" options:0 error:nil];
        study = [xmlDocTemp rootElement];
        userActionID = 0;
    }
    
    return self;
}

- (void)dealloc {
    //Should never be called, but just here for clarity really.
}

# pragma mark - General stuff

/*
 * Writes log information to file
 */
- (BOOL)writeLogFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", studyFileName]];
    NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodePrettyPrint];
    
    if (![stringxml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        NSLog(@"Failed to write log file");
        NSLog(@"%@", stringxml);
        
        return NO;
    }
    
    NSLog(@"Successfully wrote log file");
    
    return YES;
}

/*
 * Returns a base node for a logged action.
 * Sets action type (computer or user) and current user action ID.
 * Selection, Action, and Input are to be filled in by calling functions.
 */
- (DDXMLElement *)getLogAction:(LogAction)actionType {
    DDXMLElement *nodeLogAction;
    
    //Set action type
    if (actionType == COMPUTER_ACTION) {
        nodeLogAction = [DDXMLElement elementWithName:@"Computer_Action"];
    }
    else if (actionType == USER_ACTION) {
        nodeLogAction = [DDXMLElement elementWithName:@"User_Action"];
    }
    
    //Set user action ID
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User_Action_ID" stringValue:[NSString stringWithFormat:@"%ld",(long)userActionID]];
    
    //Create blank nodes for selection, action, and input
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection"];
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action"];
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //Add nodes to action
    [nodeLogAction addChild:nodeUserActionID];
    [nodeLogAction addChild:nodeSelection];
    [nodeLogAction addChild:nodeAction];
    [nodeLogAction addChild:nodeInput];
    
    return nodeLogAction;
}

# pragma mark - Logging for context

/*
 * Sets context variables for condition, school code, participant code, study day, and experimenter name.
 * Also sets the name of the current log file.
 */
- (void)setContext:(Student *)student {
    if (student != nil) {
        NSString* fileName; //combines school code, participant code, and study day
        
        //Check if timestamp needs to be appended to file name
        if ([student currentTimestamp] == nil) {
            fileName = [NSString stringWithFormat:@"%@ %@ %@", [student schoolCode], [student participantCode], [student studyDay]];
        }
        else {
            fileName = [NSString stringWithFormat:@"%@ %@ %@ %@", [student schoolCode], [student participantCode], [student studyDay], [student currentTimestamp]];
        }
        
        studyFileName = fileName;
        
        //Set variables for study context
        studyCondition = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]; //comes from app name
        studySchoolCode = [student schoolCode];
        studyParticipantCode = [student participantCode];
        studyDay = [student studyDay];
        studyExperimenterName = [student experimenterName];
    }
}

/*
 * Returns a timestamp for the context of an action
 */
- (DDXMLElement *)getTimestamp {
    //Generate a timestamp
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy'T'hh:mm.ss.SSS"];
    NSString *timestamp = [dateFormatter stringFromDate:currentTime];
    
    //Create node to store timestamp
    DDXMLElement *nodeTimestamp = [DDXMLElement elementWithName:@"Timestamp" stringValue:timestamp];
    
    return nodeTimestamp;
}

/*
 * Returns context for the study
 *
 * <Context>
 *  <School>...</School>
 *  <Condition>...</Condition>
 *  <Day>...</Day>
 *  <Participant_ID>...</Participant_ID>
 *  <Experimenter>...</Experimenter>
 * </Context>
 */
- (DDXMLElement *)getStudyContext {
    //Create node to store context information
    DDXMLElement *nodeContext = [DDXMLElement elementWithName:@"Context"];
    
    //Create nodes for study information
    DDXMLElement *nodeSchoolCode = [DDXMLElement elementWithName:@"School_Code" stringValue:studySchoolCode];
    DDXMLElement *nodeCondition = [DDXMLElement elementWithName:@"Condition" stringValue:studyCondition];
    DDXMLElement *nodeStudyDay = [DDXMLElement elementWithName:@"Study_Day" stringValue:studyDay];
    DDXMLElement *nodeParticipantCode = [DDXMLElement elementWithName:@"Participant_Code" stringValue:studyParticipantCode];
    DDXMLElement *nodeExperimenterName = [DDXMLElement elementWithName:@"Experimenter_Name" stringValue:studyExperimenterName];
    
    //Add nodes to context
    [nodeContext addChild:nodeSchoolCode];
    [nodeContext addChild:nodeCondition];
    [nodeContext addChild:nodeStudyDay];
    [nodeContext addChild:nodeParticipantCode];
    [nodeContext addChild:nodeExperimenterName];
    
    return nodeContext;
}

/*
 * Returns context for an action
 *
 * <Context>
 *  ...
 *  <Story>...</Story>
 *  <Chapter_Number>...</Chapter_Number>
 *  <Chapter_Name>...</Chapter_Name>
 *  <Page_Number>...</Page_Number>
 *  <Page_Name>...</Page_Name>
 *  <Page_Language_Type>...</Page_Language_Type>
 *  <Page_Mode>...</Page_Mode>
 *  <Sentence_Number>...</Sentence_Number>
 *  <Sentence_Text>...</Sentence_Text>
 *  <Step_Number>...</Step_Number>
 *  <Idea_Number>...</Idea_Number>
 *  <Timestamp>...</Timestamp>
 * </Context>
 */
- (DDXMLElement *)getContext:(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with node for study context
    DDXMLElement *nodeContext = [self getStudyContext];
    
    //Create node for story information
    DDXMLElement *nodeStory = [DDXMLElement elementWithName:@"Story" stringValue:storyName];
    
    //Chapter and page information
    NSString *chapterNumber = @"NULL";
    NSString *pageNumber = @"NULL";
    NSString *pageName = @"NULL";
    NSString *pageMode = @"NULL";
    NSString *pageLanguageType = @"NULL";
    
    //Parse the page file path to set chapter and page information
    //Page file path format: story#- (story name)- (im/pm/intro)- (#/#s/E/S).xhtml
    if (![pageFilePath isEqualToString:@"NULL"] && ![pageFilePath isEqualToString:@"Page Finished"]) {
        NSString* pageFileName = [NSString stringWithFormat:@"%@", [pageFilePath lastPathComponent]];
        
        //Set page language type, number, and name
        if ([pageFileName rangeOfString:@"S.xhtml"].location != NSNotFound) {
            pageLanguageType = @"S";
            
            NSRange range = [pageFileName rangeOfString:@"S.xhtml"];
            range.length = 1;
            range.location = range.location - 1;
            
            pageNumber = [pageFileName substringWithRange:range];
            
            pageName = [pageFileName substringToIndex:range.location];
            pageName = [pageName substringFromIndex:5];
            pageName = [pageName stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        }
        else {
            pageLanguageType = @"E";
            
            NSRange range = [pageFileName rangeOfString:@".xhtml"];
            range.length = 1;
            range.location = range.location - 1;
            
            pageNumber = [pageFileName substringWithRange:range];
            
            if ([pageNumber isEqualToString:@"E"] || [pageNumber isEqualToString:@"S"]) {
                pageNumber = @"NULL";
            }
            
            pageName = [pageFileName substringToIndex:range.location];
            pageName = [pageName substringFromIndex:5];
            pageName = [pageName stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        }
        
        //Set page mode
        if ([pageFileName rangeOfString:@"IM"].location != NSNotFound) {
            pageMode = @"IM";
        }
        else if ([pageFileName rangeOfString:@"PM"].location != NSNotFound) {
            pageMode = @"PM";
        }
        else if ([pageFileName rangeOfString:@"Intro"].location != NSNotFound) {
            pageMode = @"INTRO";
            pageNumber = @"0";
        }
        
        //Set chapter number
        chapterNumber = [pageFileName substringToIndex:6];
        chapterNumber = [chapterNumber substringFromIndex:5];
    }
    
    //Create nodes for chapter information
    NSString* chapterName = [NSString stringWithFormat:@"%@",[chapterFilePath lastPathComponent]];
    DDXMLElement *nodeChapterNumber = [DDXMLElement elementWithName:@"Chapter_Number" stringValue:chapterNumber];
    DDXMLElement *nodeChapterName = [DDXMLElement elementWithName:@"Chapter_Name" stringValue:chapterName];
    
    //Create nodes for page information
    DDXMLElement *nodePageNumber = [DDXMLElement elementWithName:@"Page_Number" stringValue:pageNumber];
    DDXMLElement *nodePageName = [DDXMLElement elementWithName:@"Page_Name" stringValue:pageName];
    DDXMLElement *nodePageLanguageType = [DDXMLElement elementWithName:@"Page_Language_Type" stringValue:pageLanguageType];
    DDXMLElement *nodePageMode = [DDXMLElement elementWithName:@"Page_Mode" stringValue:pageMode];
    
    //Create nodes for sentence information
    DDXMLElement *nodeSentenceNumber = [DDXMLElement elementWithName:@"Sentence_Number" stringValue:[NSString stringWithFormat:@"%d", sentenceNumber]];
    DDXMLElement *nodeSentenceText = [DDXMLElement elementWithName:@"Sentence_Text" stringValue:sentenceText];
    
    //Create nodes for step number and idea number
    DDXMLElement *nodeStepNumber = [DDXMLElement elementWithName:@"Step_Number" stringValue:[NSString stringWithFormat:@"%d", stepNumber]];
    DDXMLElement *nodeIdeaNumber = [DDXMLElement elementWithName:@"Idea_Number" stringValue:[NSString stringWithFormat:@"%d", ideaNumber]];
    
    //Create node for timestamp
    DDXMLElement *nodeTimestamp = [self getTimestamp];
    
    //Add nodes to context
    [nodeContext addChild:nodeStory];
    [nodeContext addChild:nodeChapterNumber];
    [nodeContext addChild:nodeChapterName];
    [nodeContext addChild:nodePageNumber];
    [nodeContext addChild:nodePageName];
    [nodeContext addChild:nodePageLanguageType];
    [nodeContext addChild:nodePageMode];
    [nodeContext addChild:nodeSentenceNumber];
    [nodeContext addChild:nodeSentenceText];
    [nodeContext addChild:nodeStepNumber];
    [nodeContext addChild:nodeIdeaNumber];
    [nodeContext addChild:nodeTimestamp];
    
    return nodeContext;
}

/*
 * Returns context for an action during an assessment activity
 *
 * <Context>
 *  ...
 *  <Story>...</Story>
 *  <Chapter_Name>...</Chapter_Name>
 *  <Assessment_Step_Number>...</Assessment_Step_Number>
 *  <Timestamp>...</Timestamp>
 * </Context>
 */
- (DDXMLElement *)getAssessmentContext:(NSString *)storyName :(NSString *)chapterName :(NSString *)assessmentStepNumber {
    //Start with node for study context
    DDXMLElement *nodeContext = [self getStudyContext];
    
    //Create nodes for assessment information
    DDXMLElement *nodeStory = [DDXMLElement elementWithName:@"Story" stringValue:storyName];
    DDXMLElement *nodeChapterName = [DDXMLElement elementWithName:@"Chapter_Name" stringValue:chapterName];
    DDXMLElement *nodeAssessmentStepNumber = [DDXMLElement elementWithName:@"Assessment_Step_Number" stringValue:assessmentStepNumber];
    DDXMLElement *nodeTimestamp = [self getTimestamp];
    
    //Add nodes to context
    [nodeContext addChild:nodeStory];
    [nodeContext addChild:nodeChapterName];
    [nodeContext addChild:nodeAssessmentStepNumber];
    [nodeContext addChild:nodeTimestamp];
    
    return nodeContext;
}

# pragma mark - Logging for actions

# pragma mark Computer Actions

/*
 * Logging for when computer moves an object
 */
- (void)logComputerMoveObject:(NSString *)movingObjectID :(NSString *)waypointID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Move Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for moving object, waypoint ID, start position, and end position
    DDXMLElement *nodeMovingObject = [DDXMLElement elementWithName:@"Moving_Object" stringValue:movingObjectID];
    DDXMLElement *nodeWaypointID = [DDXMLElement elementWithName:@"Waypoint_ID" stringValue:waypointID];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start_Position" stringValue:[NSString stringWithFormat:@"%f, %f", startPosX, startPosY]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End_Position" stringValue:[NSString stringWithFormat:@"%f, %f", endPosX, endPosY]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeMovingObject];
    [nodeInput addChild:nodeWaypointID];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}


/*
 * Logging for when computer resets an object (i.e., snaps object back to original position after an error)
 */
- (void)logComputerResetObject:(NSString *)objectID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Reset Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for object, start position, and end position
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:objectID];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start_Position" stringValue:[NSString stringWithFormat:@"%f, %f", startPosX, startPosY]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End_Position" stringValue:[NSString stringWithFormat:@"%f, %f", endPosX, endPosY]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer makes an object appear or disappear
 */
- (void)logComputerDisappearObject:(NSString *)interactionType :(NSString *)objectID :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action ("Appear Object" or "Disappear Object")
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:interactionType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for object
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:objectID];
    
    //Add above node to input
    [nodeInput addChild:nodeObject];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when an object image is swapped for an alternative image
 */
- (void)logComputerSwapImage:(NSString *)objectID :(NSString *)swapImageID :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Swap Image"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for object and swap image ID
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:objectID];
    DDXMLElement *nodeSwapImageID = [DDXMLElement elementWithName:@"Swap_Image_ID" stringValue:swapImageID];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeSwapImageID];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer groups, ungroups, or ungroup and stay objects together
 */
- (void)logComputerGroupObjects:(NSString *)interactionType :(NSString *)object1ID :(NSString *)object2ID :(NSString *)groupingLocation :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action ("Group Objects", "Ungroup Objects", or "Ungroup and Stay Objects")
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:interactionType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for object 1, object2, and grouping location
    DDXMLElement *nodeObject1 = [DDXMLElement elementWithName:@"Object_1" stringValue:object1ID];
    DDXMLElement *nodeObject2 = [DDXMLElement elementWithName:@"Object_2" stringValue:object2ID];
    DDXMLElement *nodeGroupingLocation = [DDXMLElement elementWithName:@"Grouping_Location" stringValue:groupingLocation];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject1];
    [nodeInput addChild:nodeObject2];
    [nodeInput addChild:nodeGroupingLocation];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer verifies whether a user action was correct or incorrect
 */
- (void)logComputerVerification:(NSString *)actionType :(BOOL)verification :(NSString *)objectSelected :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:objectSelected];
    
    //Set action ("Move to Hotspot", "Move to Object", "Display Menu", or "Perform Interaction")
    //TODO: Rename action types to be more useful for data analysis
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:actionType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for verification
    DDXMLElement *nodeVerficiation;
    
    //Set verification
    if (verification) {
         nodeVerficiation = [DDXMLElement elementWithName:@"Verification" stringValue:@"Correct"];
    }
    else {
        nodeVerficiation = [DDXMLElement elementWithName:@"Verification" stringValue:@"Incorrect"];
    }
    
    //Add above node to input
    [nodeInput addChild:nodeVerficiation];
    
    //Add context node to computer action
     DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer plays audio
 */
- (void)logComputerPlayAudio:(NSString *)computerAction :(NSString *)languageType :(NSString *)audioFileName :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Audio"];
    
    //Set action ("Play Error Noise", "Play Word", or "Play Try Again")
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:computerAction];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for audio file name and audio language
    DDXMLElement *nodeAudioFileName = [DDXMLElement elementWithName:@"Audio_File_Name" stringValue:audioFileName];
    DDXMLElement *nodeAudioLanguage = [DDXMLElement elementWithName:@"Audio_Language" stringValue:languageType];
    
    //Add above nodes to input
    [nodeInput addChild:nodeAudioFileName];
    [nodeInput addChild:nodeAudioLanguage];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer displays a menu
 */
- (void)logComputerDisplayMenuItems:(NSArray *)menuInteractions :(NSArray *)menuImages :(NSArray*)menuRelationships :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Display Menu"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for menu item 1, menu item 2, and menu item 3
    DDXMLElement *nodeMenuItem1;
    DDXMLElement *nodeMenuItem2;
    DDXMLElement *nodeMenuItem3;
    
    if ([menuInteractions count] == 2) {
        NSString *menuItem;
        
        for (int i = 0; i < [menuImages count]; i++) {
            if ([[menuImages objectAtIndex:i] isEqual:@"1"]) {
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:1]];
                
                for (int j = 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem1 = [DDXMLElement elementWithName:@"Menu_Item_1" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:0], [menuRelationships objectAtIndex:0]]];
                
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:i + 1]];
                
                for (int j = i + 2; j < [menuImages count]; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem2 = [DDXMLElement elementWithName:@"Menu_Item_2" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:1], [menuRelationships objectAtIndex:1]]];
            }
        }
        
        //Add above nodes to input
        [nodeInput addChild:nodeMenuItem1];
        [nodeInput addChild:nodeMenuItem2];
    }
    else {
        NSString *menuItem;
        int markMidmenu = 0;
        
        for (int i = 0; i < [menuImages count]; i++) {
            if ([[menuImages objectAtIndex:i] isEqual:@"1"]) {
                markMidmenu = i;
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:1]];
                
                for (int j = 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem1 = [DDXMLElement elementWithName:@"Menu_Item_1" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:0], [menuRelationships objectAtIndex:0]]];
            }
            
            if ([[menuImages objectAtIndex:i] isEqual:@"2"]) {
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:markMidmenu + 1]];
                
                for (int j = markMidmenu + 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem2 = [DDXMLElement elementWithName:@"Menu_Item_2" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:1], [menuRelationships objectAtIndex:1]]];
                
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:i + 1]];
                
                for (int j = i + 2; j < [menuImages count]; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j] ];
                }
                
                nodeMenuItem3 = [DDXMLElement elementWithName:@"Menu_Item_3" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:2], [menuRelationships objectAtIndex:2]]];
            }
        }
        
        //Add above nodes to input
        [nodeInput addChild:nodeMenuItem1];
        [nodeInput addChild:nodeMenuItem2];
        [nodeInput addChild:nodeMenuItem3];
    }
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

#pragma mark User Actions

/*
 * Logging for when user moves an object
 */
- (void)logUserMoveObject:(NSString *)moveType :(NSString *)movingObjectID :(NSString *)collisionObjectOrLocationID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action ("Move to Hotspot" or "Move to Object")
    //TODO: Rename move types to be more useful for data analysis
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:moveType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for moving object, collision object, start position, and end position
    DDXMLElement *nodeMovingObject = [DDXMLElement elementWithName:@"Moving_Object" stringValue:movingObjectID];
    //TODO: Maybe this shouldn't be called "Collision_Object" when it may be a location ID...
    DDXMLElement *nodeCollisionObject = [DDXMLElement elementWithName:@"Collision_Object" stringValue:collisionObjectOrLocationID];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start_Position" stringValue:[NSString stringWithFormat:@"%f, %f", startPosX, startPosY]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End_Position" stringValue:[NSString stringWithFormat:@"%f, %f", endPosX, endPosY]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeMovingObject];
    [nodeInput addChild:nodeCollisionObject];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeUserAction addChild:nodeContext];
}

/*
 * Logging for when user selects an item from a menu
 */
- (void)logUserSelectMenuItem:(int)selectedMenuItemID :(NSArray *)menuInteractions :(NSArray *)menuImages :(NSArray *)menuRelationships :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Menu Item"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Select Menu Item"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for menu item 1, menu item 2, and menu item 3
    DDXMLElement *nodeMenuItem1;
    DDXMLElement *nodeMenuItem2;
    DDXMLElement *nodeMenuItem3;
    
    //Checks the number of menu items displayed, then extracts the menu item data and parses data into a string for each menu item for logging
    if ([menuInteractions count] == 2) {
        NSString *menuItem;
        
        //Iterates through all menu images
        for (int i = 0; i < [menuImages count]; i++) {
            //Once the break between both menu items is reached, create strings for each
            if ([[menuImages objectAtIndex:i] isEqual:@"1"]) {
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:1]];
                
                for (int j = 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem1 = [DDXMLElement elementWithName:@"Menu_Item_1" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:0], [menuRelationships objectAtIndex:0]]];
                
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:i + 1]];
                
                for (int j = i + 2; j < [menuImages count]; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem2 = [DDXMLElement elementWithName:@"Menu_Item_2" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:1], [menuRelationships objectAtIndex:1]]];
            }
        }
        
        //Add above nodes to input
        if (selectedMenuItemID == 0) {
            [nodeInput addChild:nodeMenuItem1];
        }
        else if (selectedMenuItemID == 1) {
            [nodeInput addChild:nodeMenuItem2];
        }
    }
    else {
        NSString *menuItem;
        int markMidmenu = 0;
        
        for (int i = 0; i < [menuImages count]; i++) {
            if ([[menuImages objectAtIndex:i] isEqual:@"1"]) {
                markMidmenu = i;
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:1]];
                
                for (int j = 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
                
                nodeMenuItem1 = [DDXMLElement elementWithName:@"Menu_Item_1" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:0], [menuRelationships objectAtIndex:0]]];
            }
            
            if ([[menuImages objectAtIndex:i] isEqual:@"2"]) {
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:markMidmenu + 1]];
                
                for (int j = markMidmenu + 2; j < i; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j]];
                }
            
                nodeMenuItem2 = [DDXMLElement elementWithName:@"Menu_Item_2" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:1], [menuRelationships objectAtIndex:1]]];
                
                menuItem = [NSString stringWithFormat:@"%@", [menuImages objectAtIndex:i + 1]];
                
                for (int j = i + 2; j < [menuImages count]; j++) {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [menuImages objectAtIndex:j] ];
                }
                
                nodeMenuItem3 = [DDXMLElement elementWithName:@"Menu_Item_3" stringValue:[NSString stringWithFormat:@"%@, %@, %@", menuItem, [menuInteractions objectAtIndex:2], [menuRelationships objectAtIndex:2]]];
            }
        }
        
        //Add above nodes to input
        if (selectedMenuItemID == 0) {
            [nodeInput addChild:nodeMenuItem1];
        }
        else if (selectedMenuItemID == 1) {
            [nodeInput addChild:nodeMenuItem2];
        }
        else if (selectedMenuItemID == 2) {
            [nodeInput addChild:nodeMenuItem3];
        }
    }
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeUserAction addChild:nodeContext];
}

/*
 * Logging for when user taps on an underlined vocabulary word
 */
- (void)logUserTapWord:(NSString *)selectedWord :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Word"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for word tapped
    DDXMLElement *nodeWordTapped = [DDXMLElement elementWithName:@"Word_Tapped" stringValue:selectedWord];
    
    //Add above node to input
    [nodeInput addChild:nodeWordTapped];
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeUserAction addChild:nodeContext];
}

/*
 * Logging for when user performs an emergency swipe
 */
- (void)logUserEmergencyNext:(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"NULL"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Two Finger Swipe"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for action type
    DDXMLElement *nodeActionType = [DDXMLElement elementWithName:@"Action_Type" stringValue:@"Emergency Swipe"];
    
    //Add above node to input
    [nodeInput addChild:nodeActionType];
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeUserAction addChild:nodeContext];
}

#pragma mark - Logging for navigation

#pragma mark Computer Navigation

/*
 * Logging for moving to the next step in a sentence
 */
- (void)logNextStepNavigation:(NSInteger)nextStepNumber :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"NULL"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Next Step"];

    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for next step number, and button type
    DDXMLElement *nodeNextStepNumber = [DDXMLElement elementWithName:@"Next_Step_Number" stringValue:[NSString stringWithFormat:@"%d", nextStepNumber]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeNextStepNumber];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for moving to the next sentence on a page
 */
- (void)logNextSentenceNavigation:(NSInteger)nextSentenceNumber :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];

    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Next Sentence"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for next sentence number and button type
    DDXMLElement *nodeNextSentenceNumber = [DDXMLElement elementWithName:@"Next_Sentence_Number" stringValue:[NSString stringWithFormat:@"%d", nextSentenceNumber]];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeNextSentenceNumber];
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for moving to the next page in a chapter
 */
- (void)logNextPageNavigation:(NSString *)nextPage :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Next Page"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for next page and button type
    DDXMLElement *nodeNextPage = [DDXMLElement elementWithName:@"Next_Page" stringValue:[nextPage lastPathComponent]];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeNextPage];
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
    
    //Make sure log file is written out at end of page
    [[ServerCommunicationController sharedManager] writeLogFile];
}

/*
 * Logging for moving to the next chapter in a story
 */
- (void)logNextChapterNavigation:(NSString *)computerAction :(NSString *)nextChapter :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action ("Load First Page" or "Load Next Page | Chapter Finished")
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:computerAction];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for next chapter and button type
    DDXMLElement *nodeNextChapter = [DDXMLElement elementWithName:@"Next_Chapter" stringValue:[nextChapter lastPathComponent]];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeNextChapter];
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeComputerAction addChild:nodeContext];
    
    //Make sure log file is written out at end of chapter
    [[ServerCommunicationController sharedManager] writeLogFile];
}

#pragma mark User Navigation

/*
 * Logging for when user presses the Next button
 */
- (void)logUserPressNext:(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for button type
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getContext:storyName :chapterFilePath :pageFilePath :sentenceNumber :sentenceText :stepNumber :ideaNumber];
    [nodeUserAction addChild:nodeContext];
}

#pragma mark - Logging for assessment activities

#pragma mark Computer Actions

/*
 * Logging for when computer loads the next step in an assessment
 */
- (void)logComputerLoadNextAssessmentStep:(NSString *)computerAction :(NSString *)currAssessmentStep :(NSString *)nextAssessmentStep :(NSString *)storyName :(NSString *)chapterName {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:computerAction];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for next assessment step and button type
    DDXMLElement *nodeNextAssessmentStep = [DDXMLElement elementWithName:@"Next_Assessment" stringValue:nextAssessmentStep];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeNextAssessmentStep];
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getAssessmentContext:storyName :chapterName :currAssessmentStep];
    [nodeComputerAction addChild:nodeContext];
    
    //Make sure log file is written at end of assessment step
    [[ServerCommunicationController sharedManager] writeLogFile];
}

/*
 * Logging for when computer verifies whether an answer to an assessment question is correct or incorrect
 */
- (void)logComputerAssessmentAnswerVerification:(BOOL)verification :(NSString *)answerSelected :(NSString *)storyName :(NSString *)chapterName :(NSString *)currAssessmentStep {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];

    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:answerSelected];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Select Answer Option"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for verification
    DDXMLElement *nodeVerficiation;
    
    //Set verification
    if (verification) {
        nodeVerficiation = [DDXMLElement elementWithName:@"Verification" stringValue:@"Correct"];
    }
    else {
        nodeVerficiation = [DDXMLElement elementWithName:@"Verification" stringValue:@"Incorrect"];
    }
    
    //Add above node to input
    [nodeInput addChild:nodeVerficiation];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getAssessmentContext:storyName :chapterName :currAssessmentStep];
    [nodeComputerAction addChild:nodeContext];
}

/*
 * Logging for when computer displays an assessment question
 */
- (void)logComputerDisplayAssessment:(NSString *)questionText :(NSArray*)answerOptions :(NSString *)computerAction :(NSString *)storyName :(NSString *)chapterName :(NSString *)currAssessmentStep {
    //Start with base node for computer action
    DDXMLElement *nodeComputerAction = [self getLogAction:COMPUTER_ACTION];
    [study addChild:nodeComputerAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeComputerAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action ("Start Assessment" or "Display Assessment")
    DDXMLElement *nodeAction = [[nodeComputerAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:computerAction];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeComputerAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for question text, answer options, and button type
    DDXMLElement *nodeQuestionText = [DDXMLElement elementWithName:@"Question_Text" stringValue:questionText];
    DDXMLElement *nodeAnswerOptions = [DDXMLElement elementWithName:@"Answer_Options" stringValue:[NSString stringWithFormat:@"%@, %@, %@, %@", answerOptions[0],answerOptions[1], answerOptions[2], answerOptions[3]]];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeQuestionText];
    [nodeInput addChild:nodeAnswerOptions];
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to computer action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getAssessmentContext:storyName :chapterName :currAssessmentStep];
    [nodeComputerAction addChild:nodeContext];
}


#pragma mark User Actions

/*
 * Logging for when user taps the Next button in an assessment
 */
- (void)logUserAssessmentTapNext:(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for button type
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getAssessmentContext:storyName :chapterName :currentAssessmentStep];
    [nodeUserAction addChild:nodeContext];
}

/*
 * Logging for when user taps an answer option in an assessment
 */
- (void)logUserAssessmentTapAnswerOption:(NSString *)questionText :(NSArray*)answerOptions :(NSString *)selectedAnswer :(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeUserAction = [self getLogAction:USER_ACTION];
    [study addChild:nodeUserAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeUserAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Answer Option"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeUserAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeUserAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for question text, answer options, selected answer, and button type
    DDXMLElement *nodeQuestionText = [DDXMLElement elementWithName:@"Question_Text" stringValue:questionText];
    DDXMLElement *nodeAnswerOptions = [DDXMLElement elementWithName:@"Answer_Options" stringValue:[NSString stringWithFormat:@"%@, %@, %@, %@", answerOptions[0], answerOptions[1], answerOptions[2], answerOptions[3]]];
    DDXMLElement *nodeSelectedAnswer = [DDXMLElement elementWithName:@"Selected_Answer" stringValue:[NSString stringWithFormat:@"%@", selectedAnswer]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeQuestionText];
    [nodeInput addChild:nodeAnswerOptions];
    [nodeInput addChild:nodeSelectedAnswer];

    //Add context node to user action
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] getAssessmentContext:storyName :chapterName :currentAssessmentStep];
    [nodeUserAction addChild:nodeContext];
}

#pragma mark - Saving/loading progress files

/*
 * Loads the progress information from file for the given student
 */
- (Progress *)loadProgress:(Student *)student {
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    
    //Get progress file name and path
    NSString *progressFileName = [NSString stringWithFormat:@"%@_%@_%@_progress.xml", [student schoolCode],[student participantCode],[student studyDay]];
    NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:progressFileName];
    
    //Try to load progress data
    NSData *progressData = [[NSMutableData alloc] initWithContentsOfFile:progressFilePath];
    
    //Progress file for given student exists
    if (progressData != nil){
        NSError *error;
        GDataXMLDocument *progressXMLDocument = [[GDataXMLDocument alloc] initWithData:progressData error:&error];
        
        Progress *progress = [[Progress alloc] init];
        
        GDataXMLElement *progressElement = (GDataXMLElement *)[[progressXMLDocument nodesForXPath:@"//progress" error:nil] objectAtIndex:0];
        
        NSArray *bookElements = [progressElement elementsForName:@"book"];
        
        //Read the completed, in progress, and incomplete chapters for each book
        for (GDataXMLElement *bookElement in bookElements){
            NSString *bookTitle = [[bookElement attributeForName:@"title"] stringValue];
            
            //Completed chapters
            NSMutableArray *completedChapterTitles = [[NSMutableArray alloc] init];
            GDataXMLElement *completedElement = (GDataXMLElement*)[[bookElement elementsForName:@"completed"] objectAtIndex:0];
            NSArray *completedChapterElements = [completedElement elementsForName:@"chapter"];
            
            for (GDataXMLElement *completedChapterElement in completedChapterElements){
                NSString *chapterTitle = [[completedChapterElement attributeForName:@"title"] stringValue];
                
                [completedChapterTitles addObject:chapterTitle];
            }
            
            [progress loadChapters:completedChapterTitles fromBook:bookTitle withStatus:COMPLETED];
            
            //In progress chapters
            NSMutableArray *inProgressChapterTitles = [[NSMutableArray alloc] init];
            GDataXMLElement *inProgressElement = (GDataXMLElement *)[[bookElement elementsForName:@"in_progress"] objectAtIndex:0];
            NSArray *inProgressChapterElements = [inProgressElement elementsForName:@"chapter"];
            
            for (GDataXMLElement *inProgressChapterElement in inProgressChapterElements){
                NSString *chapterTitle = [[inProgressChapterElement attributeForName:@"title"] stringValue];
                
                [inProgressChapterTitles addObject:chapterTitle];
            }
            
            [progress loadChapters:inProgressChapterTitles fromBook:bookTitle withStatus:IN_PROGRESS];
            
            //Incomplete chapters
            NSMutableArray *incompleteChapterTitles = [[NSMutableArray alloc] init];
            GDataXMLElement *incompleteElement = (GDataXMLElement*)[[bookElement elementsForName:@"incomplete"] objectAtIndex:0];
            NSArray *incompleteChapterElements = [incompleteElement elementsForName:@"chapter"];
            
            for (GDataXMLElement *incompleteChapterElement in incompleteChapterElements){
                NSString *chapterTitle = [[incompleteChapterElement attributeForName:@"title"] stringValue];
                
                [incompleteChapterTitles addObject:chapterTitle];
            }
            
            [progress loadChapters:incompleteChapterTitles fromBook:bookTitle withStatus:INCOMPLETE];
        }
        
        //Read current sequence and id number
        GDataXMLElement *sequenceElement = (GDataXMLElement*)[[progressElement elementsForName:@"sequence"] objectAtIndex:0];
        NSString *sequenceId = [[sequenceElement attributeForName:@"sequenceId"] stringValue];
        NSInteger currentSequence = [[[sequenceElement attributeForName:@"currentSequence"] stringValue] integerValue];
        
        progress.sequenceId = sequenceId;
        progress.currentSequence = currentSequence;
        
        return progress;
    }
    //No progress file for given student exists
    else {
        return nil;
    }
}

/*
 * Saves the progress information to file for the given student
 */
- (void)saveProgress:(Student *)student :(Progress *)progress {
    DDXMLDocument *progressXMLDocument = [[DDXMLDocument alloc] initWithXMLString:@"<progress/>" options:0 error:nil];
    DDXMLElement *progressXMLElement = [progressXMLDocument rootElement];
    
    //List the completed, in progress, and incomplete chapters for each book
    for (NSString *bookTitle in [progress chaptersCompleted]){
        DDXMLElement *bookXMLElement = [DDXMLElement elementWithName:@"book"];
        [bookXMLElement addAttributeWithName:@"title" stringValue:bookTitle];
        
        //Completed chapters
        DDXMLElement *completedXMLElement = [DDXMLElement elementWithName:@"completed"];
        NSMutableArray *completedChapters = [[progress chaptersCompleted] objectForKey:bookTitle];
        
        for (NSString *chapterTitle in completedChapters){
            DDXMLElement *chapterXMLElement = [DDXMLElement elementWithName:@"chapter"];
            [chapterXMLElement addAttributeWithName:@"title" stringValue:chapterTitle];
            
            [completedXMLElement addChild:chapterXMLElement];
        }
        
        //In progress chapters
        DDXMLElement *inProgressXMLElement = [DDXMLElement elementWithName:@"in_progress"];
        NSMutableArray *inProgressChapters = [[progress chaptersInProgress] objectForKey:bookTitle];
        
        for (NSString *chapterTitle in inProgressChapters){
            DDXMLElement *chapterXMLElement = [DDXMLElement elementWithName:@"chapter"];
            [chapterXMLElement addAttributeWithName:@"title" stringValue:chapterTitle];
            
            [inProgressXMLElement addChild:chapterXMLElement];
        }
        
        //Incomplete chapters
        DDXMLElement *incompleteXMLElement = [DDXMLElement elementWithName:@"incomplete"];
        NSMutableArray *incompleteChapters = [[progress chaptersIncomplete] objectForKey:bookTitle];
        
        for (NSString *chapterTitle in incompleteChapters){
            DDXMLElement *chapterXMLElement = [DDXMLElement elementWithName:@"chapter"];
            [chapterXMLElement addAttributeWithName:@"title" stringValue:chapterTitle];
            
            [incompleteXMLElement addChild:chapterXMLElement];
        }
        
        [bookXMLElement addChild:completedXMLElement];
        [bookXMLElement addChild:inProgressXMLElement];
        [bookXMLElement addChild:incompleteXMLElement];
        
        [progressXMLElement addChild:bookXMLElement];
    }
    
    //Current sequence and id number
    DDXMLElement *sequenceXMLElement = [DDXMLElement elementWithName:@"sequence"];
    [sequenceXMLElement addAttributeWithName:@"sequenceId" stringValue:[progress sequenceId]];
    [sequenceXMLElement addAttributeWithName:@"currentSequence" stringValue:@([progress currentSequence]).stringValue];
    [progressXMLElement addChild:sequenceXMLElement];
    
    //Contents of progress file as a string
    NSString *progressXMLString = [progressXMLDocument XMLStringWithOptions:DDXMLNodePrettyPrint];
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    
    //Get progress file name and path
    NSString *progressFileName = [NSString stringWithFormat:@"%@_%@_%@_progress.xml", [student schoolCode],[student participantCode],[student studyDay]];
    NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:progressFileName];
    
    //Write progress to file
    if (![progressXMLString writeToFile:progressFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil]){
        NSLog(@"Failed to saved progress:\n\n%@", progressXMLString);
    }
    else {
        NSLog(@"Successfully saved progress.");
    }
}

#pragma mark - Syncing log/progress files with Dropbox

/*
 * Uploads log files and progress files to Dropbox for the specified student
 */
- (void)uploadFilesForStudent:(Student *)student {
    //Dropbox access token
    NSString *accessToken = @"I8aODJoC2RYAAAAAAAAAFhNr-UY0AM4r_e_KEsIzwqqyxCkn1VqWpLktQPSvyFoh";
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Authorization": [NSString stringWithFormat:@"Bearer %@", accessToken],
                                                   @"Content-Type": @"application/zip"
                                                   };
    
    //Get Documents directory on iPad
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //Store names of files to upload in array
    NSString *logFileName = [NSString stringWithFormat:@"%@.txt", studyFileName];
    NSString *progressFileName = [NSString stringWithFormat:@"%@_%@_%@_progress.xml", [student schoolCode],[student participantCode],[student studyDay]];
    NSArray *filesToUpload = [[NSArray alloc] initWithObjects:logFileName, progressFileName, nil];
    
    //Upload each file to Dropbox
    for (NSString *fileToUpload in filesToUpload) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileToUpload]; //Path of file on iPad
        
        NSString *content = [[NSString alloc] initWithContentsOfFile:filePath usedEncoding:nil error:nil];
        
        NSString *dbDirName = @"";
        NSString *pathExtension = [fileToUpload pathExtension];
        
        //Determine name of folder to put file in based on its extension
        if ([pathExtension isEqualToString:@"txt"]) {
            dbDirName = @"LogFiles";
        }
        else if ([pathExtension isEqualToString:@"xml"]) {
            dbDirName = @"ProgressFiles";
        }
        else {
            dbDirName = @"UnknownFiles";
        }
        
        NSString *dbFileName = [NSString stringWithFormat:@"%@/%@", dbDirName, fileToUpload]; //Name of file to use on Dropbox
        NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *localPath = [localDir stringByAppendingPathComponent:dbFileName];
        
        [content writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api-content.dropbox.com/1/files_put/auto/%@?overwrite=true", [dbFileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]]; //Files with same name will be overwritten
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
        [request setHTTPMethod:@"PUT"];
        [request setHTTPBody:data];
        [request setTimeoutInterval:1000];
        
        NSURLSessionDataTask *doDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSLog(@"Successfully uploaded student files to Dropbox.");
            }
            else {
                NSLog(@"Failed to upload student files to Dropbox. Error: %@", error);
            }
        }];
        
        [doDataTask resume];
    }
}

/*
 * Downloads progress file from Dropbox for specified student
 */
- (void)downloadProgressForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler {
    //Dropbox access token
    NSString *accessToken = @"I8aODJoC2RYAAAAAAAAAFhNr-UY0AM4r_e_KEsIzwqqyxCkn1VqWpLktQPSvyFoh";
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Authorization": [NSString stringWithFormat:@"Bearer %@", accessToken],
                                                   @"Content-Type": @"application/zip"
                                                   };
    
    NSString *progressFileName = [NSString stringWithFormat:@"%@_%@_%@_progress.xml", [student schoolCode],[student participantCode],[student studyDay]];
    NSString *dbFileName = [NSString stringWithFormat:@"ProgressFiles/%@", progressFileName]; //Name of progress file on Dropbox
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api-content.dropbox.com/1/files/auto/%@", [dbFileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]]; //File with same name will be overwritten
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:1000];
    
    NSURLSessionDataTask *doDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        long responseCode = (long)[httpResponse statusCode];
        
        if (!error && responseCode != 404) {
            NSLog(@"Successfully downloaded progress file for student from Dropbox.");
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:progressFileName]; //Path of file on iPad
            
            [data writeToFile:filePath atomically:YES];
            
            completionHandler(YES);
        }
        else {
            NSLog(@"Failed to download progress file for student from Dropbox.");
            
            completionHandler(NO);
        }
    }];
    
    [doDataTask resume];
}

@end