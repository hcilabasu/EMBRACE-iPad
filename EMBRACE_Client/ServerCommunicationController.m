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
}

@end

@implementation ServerCommunicationController

@synthesize studyContext;

# pragma mark - Shared Instance

static ServerCommunicationController *sharedInstance = nil;

+ (ServerCommunicationController *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[ServerCommunicationController alloc] init];
    }
    
    return sharedInstance;
}

+ (void)resetSharedInstance {
    sharedInstance = nil;
}

- (id)init {
    if (self = [super init]){
        xmlDocTemp = [[DDXMLDocument alloc] initWithXMLString:@"<Study/>" options:0 error:nil];
        study = [xmlDocTemp rootElement];
        userActionID = 0;
    }
    
    return self;
}

- (void)dealloc {
    //Should never be called, but just here for clarity really.
}

# pragma mark - Logging

/*
 * Writes log data to file
 */
- (BOOL)writeLogFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", studyFileName]];
    NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodePrettyPrint];
    
//    NSLog(@"\n\n%@\n\n", stringxml);
    
    if (![stringxml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        NSLog(@"Failed to write log file");
        NSLog(@"%@", stringxml);
        
        return NO;
    }
    
    NSLog(@"Successfully wrote log file");
    
    return YES;
}

/*
 * Returns a base node for a logged action performed by the specified actor (system or user).
 * Sets actor type and current user action ID.
 * Selection, Action, Input, and Context are to be filled in by calling functions.
 */
- (DDXMLElement *)getBaseActionForActor:(Actor)actor {
    DDXMLElement *nodeBaseAction;
    
    //Set actor type
    if (actor == SYSTEM) {
        nodeBaseAction = [DDXMLElement elementWithName:@"System_Action"];
    }
    else if (actor == USER) {
        nodeBaseAction = [DDXMLElement elementWithName:@"User_Action"];
    }
    
    //Set user action ID
    DDXMLElement *nodeBaseActionID = [DDXMLElement elementWithName:@"User_Action_ID" stringValue:[NSString stringWithFormat:@"%ld",(long)userActionID]];
    
    //Create blank nodes for selection, action, input, and context
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection"];
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action"];
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeContext = [DDXMLElement elementWithName:@"Context"];
    
    //Add nodes to base action
    [nodeBaseAction addChild:nodeBaseActionID];
    [nodeBaseAction addChild:nodeSelection];
    [nodeBaseAction addChild:nodeAction];
    [nodeBaseAction addChild:nodeInput];
    [nodeBaseAction addChild:nodeContext];
    
    return nodeBaseAction;
}

# pragma mark - Logging (Context)

/*
 * Returns a timestamp for context
 *
 * <Timestamp>
 *  <Date>...</Date>
 *  <Time>...</Time>
 * </Timestamp>
 */
- (DDXMLElement *)getTimestamp:(NSDictionary *)timestamp {
    //Create node for timestamp
    DDXMLElement *nodeTimestamp = [DDXMLElement elementWithName:@"Timestamp"];
    
    //Create nodes for timestamp information
    DDXMLElement *nodeDate = [DDXMLElement elementWithName:@"Date" stringValue:[timestamp objectForKey:@"date"]];
    DDXMLElement *nodeTime = [DDXMLElement elementWithName:@"Time" stringValue:[timestamp objectForKey:@"time"]];
    
    //Add above nodes to timestamp
    [nodeTimestamp addChild:nodeDate];
    [nodeTimestamp addChild:nodeTime];
    
    return nodeTimestamp;
}

/*
 * Sets up study context--condition, school code, participant code, study day, and experimenter name.
 * Also sets the name of the current log file.
 */
- (void)setupStudyContext:(Student *)student {
    if (student != nil) {
        studyContext = [[StudyContext alloc] init];
        
        studyContext.condition = @"NULL";
        studyContext.schoolCode = [student schoolCode];
        studyContext.participantCode = [student participantCode];
        studyContext.studyDay = [student studyDay];
        studyContext.experimenterName = [student experimenterName];
        studyContext.language = [[ConditionSetup sharedInstance] returnLanguageEnumtoString:[[ConditionSetup sharedInstance] language]];
        
        NSString* fileName; //combines school code, participant code, and study day
        
        //Check if timestamp needs to be appended to file name
        //if ([student currentTimestamp] == nil) {
         //   fileName = [NSString stringWithFormat:@"%@ %@ %@", [student schoolCode], [student participantCode], [student studyDay]];
        //}
        //else {
            fileName = [NSString stringWithFormat:@"%@ %@ %@ %@", [student schoolCode], [student participantCode], [student studyDay], [student currentTimestamp]];
        //}
        
        studyFileName = fileName;
    }
}

/*
 * Returns context for the study.
 *
 * <Study_Context>
 *  <School>...</School>
 *  <Condition>...</Condition>
 *  <Day>...</Day>
 *  <Participant_ID>...</Participant_ID>
 *  <Experimenter>...</Experimenter>
 *  [OPTIONAL] <Timestamp>...</Timestamp>
 * </Study_Context>
 */
- (DDXMLElement *)getStudyContext:(StudyContext *)context {
    //Create node to store study context information
    DDXMLElement *nodeStudyContext = [DDXMLElement elementWithName:@"Study_Context"];
    
    //Create nodes for study information
    DDXMLElement *nodeSchoolCode = [DDXMLElement elementWithName:@"School_Code" stringValue:[context schoolCode]];
    DDXMLElement *nodeCondition = [DDXMLElement elementWithName:@"Condition" stringValue:[context condition]];
    DDXMLElement *nodeStudyDay = [DDXMLElement elementWithName:@"Study_Day" stringValue:[context studyDay]];
    DDXMLElement *nodeParticipantCode = [DDXMLElement elementWithName:@"Participant_Code" stringValue:[context participantCode]];
    DDXMLElement *nodeExperimenterName = [DDXMLElement elementWithName:@"Experimenter_Name" stringValue:[context experimenterName]];
    DDXMLElement *nodeLanguage = [DDXMLElement elementWithName:@"Language" stringValue:[context language]];
    DDXMLElement *nodeTimestamp = [self getTimestamp:[context generateTimestamp]];
    
    //Add nodes to study context
    [nodeStudyContext addChild:nodeSchoolCode];
    [nodeStudyContext addChild:nodeCondition];
    [nodeStudyContext addChild:nodeStudyDay];
    [nodeStudyContext addChild:nodeParticipantCode];
    [nodeStudyContext addChild:nodeExperimenterName];
    [nodeStudyContext addChild:nodeLanguage];
    [nodeStudyContext addChild:nodeTimestamp];
    
    return nodeStudyContext;
}

/*
 * Returns context for a manipulation activity
 *
 * <Manipulation_Context>
 *  <Book_Title>...</Book_Title>
 *  <Chapter_Number>...</Chapter_Number>
 *  <Chapter_Title>...</Chapter_Title>
 *  <Page_Language>...</Page_Language>
 *  <Page_Mode>...</Page_Mode>
 *  <Page_Number>...</Page_Number>
 *  <Sentence_Number>...</Sentence_Number>
 *  <Sentence_Text>...</Sentence_Text>
 *  <Manipulation_Sentence>...</Manipulation_Sentence>
 *  <Step_Number>...</Step_Number>
 *  <Idea_Number>...</Idea_Number>
 *  <Timestamp>...</Timestamp>
 * </Manipulation_Context>
 */
- (DDXMLElement *)getManipulationContext:(ManipulationContext *)context {
    //Create node to store manipulation context
    DDXMLElement *nodeManipulationContext = [DDXMLElement elementWithName:@"Manipulation_Context"];
    
    //Create node for book title
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:[context bookTitle]];
    
    //Create nodes for chapter information
    DDXMLElement *nodeChapterNumber = [DDXMLElement elementWithName:@"Chapter_Number" stringValue:[NSString stringWithFormat:@"%ld", (long)[context chapterNumber]]];
    DDXMLElement *nodeChapterTitle = [DDXMLElement elementWithName:@"Chapter_Title" stringValue:[context chapterTitle]];
    
    //Create nodes for page information
    DDXMLElement *nodePageLanguage = [DDXMLElement elementWithName:@"Page_Language" stringValue:[context pageLanguage]];
    DDXMLElement *nodePageMode = [DDXMLElement elementWithName:@"Page_Mode" stringValue:[context pageMode]];
    DDXMLElement *nodePageNumber = [DDXMLElement elementWithName:@"Page_Number" stringValue:[NSString stringWithFormat:@"%ld", (long)[context pageNumber]]];
    
    //Create nodes for sentence information
    DDXMLElement *nodeSentenceNumber = [DDXMLElement elementWithName:@"Sentence_Number" stringValue:[NSString stringWithFormat:@"%ld", (long)[context sentenceNumber]]];
    NSString *sentenceText = [[context sentenceText] isEqualToString:@""] || [context sentenceText] == nil ? @"NULL" : [context sentenceText];
    DDXMLElement *nodeSentenceText = [DDXMLElement elementWithName:@"Sentence_Text" stringValue:sentenceText];
    DDXMLElement *nodeManipulationSentence = [DDXMLElement elementWithName:@"Manipulation_Sentence" stringValue:[context manipulationSentence] ? @"Yes" : @"No"];
    
    //Create nodes for step number and idea number
    DDXMLElement *nodeStepNumber = [DDXMLElement elementWithName:@"Step_Number" stringValue:[NSString stringWithFormat:@"%ld", (long)[context stepNumber]]];
    DDXMLElement *nodeIdeaNumber = [DDXMLElement elementWithName:@"Idea_Number" stringValue:[NSString stringWithFormat:@"%ld", (long)[context ideaNumber]]];
    
    //Add nodes to manipulation context
    [nodeManipulationContext addChild:nodeBookTitle];
    [nodeManipulationContext addChild:nodeChapterNumber];
    [nodeManipulationContext addChild:nodeChapterTitle];
    [nodeManipulationContext addChild:nodePageLanguage];
    [nodeManipulationContext addChild:nodePageMode];
    [nodeManipulationContext addChild:nodePageNumber];
    [nodeManipulationContext addChild:nodeSentenceNumber];
    [nodeManipulationContext addChild:nodeSentenceText];
    [nodeManipulationContext addChild:nodeManipulationSentence];
    [nodeManipulationContext addChild:nodeStepNumber];
    [nodeManipulationContext addChild:nodeIdeaNumber];
    
    return nodeManipulationContext;
}

/*
 * Returns context for an assessment activity
 *
 * <Assessment_Context>
 *  <Book_Title>...</Book_Title>
 *  <Chapter_Title>...</Chapter_Title>
 *  <Assessment_Step_Number>...</Assessment_Step_Number>
 *  <Timestamp>...</Timestamp>
 * </Assessment_Context>
 */
- (DDXMLElement *)getAssessmentContext:(AssessmentContext *)context {
    //Create node to store assessment context
    DDXMLElement *nodeAssessmentContext = [DDXMLElement elementWithName:@"Assessment_Context"];
    
    //Create nodes for assessment information
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:[context bookTitle]];
    DDXMLElement *nodeChapterTitle = [DDXMLElement elementWithName:@"Chapter_Title" stringValue:[context chapterTitle]];
    DDXMLElement *nodeAssessmentStepNumber = [DDXMLElement elementWithName:@"Assessment_Step_Number" stringValue:[NSString stringWithFormat:@"%d", [context assessmentStepNumber]]];
    
    //Add nodes to assessment context
    [nodeAssessmentContext addChild:nodeBookTitle];
    [nodeAssessmentContext addChild:nodeChapterTitle];
    [nodeAssessmentContext addChild:nodeAssessmentStepNumber];
    
    return nodeAssessmentContext;
}

# pragma mark - Logging (Library)

/*
 * Logging for when Login is pressed
 */
- (void)logPressLogin {
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Start Session"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Login"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for when Logout is pressed
 */
- (void)logPressLogout {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"End Session"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Logout"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for when Books button is pressed in library view
 */
- (void)logPressBooks {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Show Books"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Books"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for when a book is unlocked in the library view
 */
- (void)logUnlockBook:(NSString *)bookTitle withStatus:(NSString *)bookStatus {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Unlock Library Item"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Book"];
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:bookTitle];
    DDXMLElement *nodeBookStatus = [DDXMLElement elementWithName:@"Book_Status" stringValue:bookStatus];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    [nodeInput addChild:nodeBookTitle];
    [nodeInput addChild:nodeBookStatus];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when a chapter is unlocked in the library view
 */
- (void)logUnlockChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle withStatus:(NSString *)chapterStatus {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Unlock Library Item"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Chapter"];
    DDXMLElement *nodeChapterTitle = [DDXMLElement elementWithName:@"Chapter_Title" stringValue:chapterTitle];
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:bookTitle];
    DDXMLElement *nodeChapterStatus = [DDXMLElement elementWithName:@"Chapter_Status" stringValue:chapterStatus];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    [nodeInput addChild:nodeChapterTitle];
    [nodeInput addChild:nodeBookTitle];
    [nodeInput addChild:nodeChapterStatus];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for loading a book in the library view
 */
- (void)logLoadBook:(NSString *)bookTitle {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Book"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Book"];
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:bookTitle];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    [nodeInput addChild:nodeBookTitle];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for loading a chapter
 */
- (void)logLoadChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Chapter"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Chapter"];
    DDXMLElement *nodeChapterTitle = [DDXMLElement elementWithName:@"Chapter_Title" stringValue:chapterTitle];
    DDXMLElement *nodeBookTitle = [DDXMLElement elementWithName:@"Book_Title" stringValue:bookTitle];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    [nodeInput addChild:nodeChapterTitle];
    [nodeInput addChild:nodeBookTitle];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create node for context information
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above node to context
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

# pragma mark - Logging (Manipulation)

/*
 * Logging for when an object is moved
 */
- (void)logMoveObject:(NSString *)object toDestination:(NSString *)destination ofType:(NSString *)destinationType startPos:(CGPoint)start endPos:(CGPoint)end performedBy:(Actor)actor context:(ManipulationContext *)context {
    //Start with base node for action
    DDXMLElement *nodeBaseAction;
    
    if (actor == SYSTEM) {
        nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    }
    else if (actor == USER) {
        userActionID++;
        nodeBaseAction = [self getBaseActionForActor:USER];
    }
    
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Move Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Creates nodes for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    DDXMLElement *nodeDestination = [DDXMLElement elementWithName:@"Destination" stringValue:destination];
    DDXMLElement *nodeDestinationType = [DDXMLElement elementWithName:@"Destination_Type" stringValue:destinationType];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start_Position" stringValue:[NSString stringWithFormat:@"%f, %f", start.x, start.y]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End_Position" stringValue:[NSString stringWithFormat:@"%f, %f", end.x, end.y]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeDestination];
    [nodeInput addChild:nodeDestinationType];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when objects are grouped, ungrouped, or ungroup-and-stayed
 */
- (void)logGroupOrUngroupObjects:(NSString *)object1 object2:(NSString *)object2 ofType:(NSString *)interactionType hotspot:(NSString *)hotspot :(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:interactionType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeObject1 = [DDXMLElement elementWithName:@"Object_1" stringValue:object1];
    DDXMLElement *nodeObject2 = [DDXMLElement elementWithName:@"Object_2" stringValue:object2];
    DDXMLElement *nodeHotspot = [DDXMLElement elementWithName:@"Hotspot" stringValue:hotspot];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject1];
    [nodeInput addChild:nodeObject2];
    [nodeInput addChild:nodeHotspot];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when a menu is displayed
 */
- (void)logDisplayMenuItems:(NSArray *)menuItemsData context:(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Menu"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Display Menu Items"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for menu items
    DDXMLElement *nodeMenuItems = [DDXMLElement elementWithName:@"Menu_Items"];
    
    for (int i = 0; i < [menuItemsData count]; i++) {
        NSArray *menuItemData = [menuItemsData objectAtIndex:i];
        
        //Create node for menu item
        DDXMLElement *nodeMenuItem = [DDXMLElement elementWithName:[NSString stringWithFormat:@"Menu_Item_%d", i]];
        
        for (int j = 0; j < [menuItemData count]; j++) {
            NSDictionary *connectionData = [menuItemData objectAtIndex:j];
            
            //Create node for interaction
            DDXMLElement *nodeInteraction = [DDXMLElement elementWithName:[NSString stringWithFormat:@"Interaction_%d", j]];
            
            //Create nodes for objects, hotspot, and interaction type in interaction
            DDXMLElement *nodeInteractionObject1 = [DDXMLElement elementWithName:@"Object_1" stringValue:[[connectionData objectForKey:@"objects"] objectAtIndex:0]];
            DDXMLElement *nodeInteractionObject2 = [DDXMLElement elementWithName:@"Object_2" stringValue:[[connectionData objectForKey:@"objects"] objectAtIndex:1]];
            DDXMLElement *nodeInteractionHotspot = [DDXMLElement elementWithName:@"Hotspot" stringValue:[connectionData objectForKey:@"hotspot"]];
            DDXMLElement *nodeInteractionType = [DDXMLElement elementWithName:@"Interaction_Type" stringValue:[connectionData objectForKey:@"interactionType"]];
            
            //Add above nodes to interaction
            [nodeInteraction addChild:nodeInteractionObject1];
            [nodeInteraction addChild:nodeInteractionObject2];
            [nodeInteraction addChild:nodeInteractionHotspot];
            [nodeInteraction addChild:nodeInteractionType];
            
            //Add interaction node to menu item
            [nodeMenuItem addChild:nodeInteraction];
        }
        
        //Add menu item node to menu items
        [nodeMenuItems addChild:nodeMenuItem];
    }
    
    //Add above node to input
    [nodeInput addChild:nodeMenuItems];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when a menu item is selected
 */
- (void)logSelectMenuItem:(NSArray *)menuItemData atIndex:(int)index context:(ManipulationContext *)context {
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Menu Item"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Select Menu Item"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for menu item
    DDXMLElement *nodeMenuItem;
    
    if (index > -1) {
        nodeMenuItem = [DDXMLElement elementWithName:[NSString stringWithFormat:@"Menu_Item_%d", index]];
        
        for (int i = 0; i < [menuItemData count]; i++) {
            NSDictionary *connectionData = [menuItemData objectAtIndex:i];
            
            //Create node for interaction
            DDXMLElement *nodeInteraction = [DDXMLElement elementWithName:[NSString stringWithFormat:@"Interaction_%d", i]];
            
            //Create nodes for objects, hotspot, and interaction type in interaction
            DDXMLElement *nodeInteractionObject1 = [DDXMLElement elementWithName:@"Object_1" stringValue:[[connectionData objectForKey:@"objects"] objectAtIndex:0]];
            DDXMLElement *nodeInteractionObject2 = [DDXMLElement elementWithName:@"Object_2" stringValue:[[connectionData objectForKey:@"objects"] objectAtIndex:1]];
            DDXMLElement *nodeInteractionHotspot = [DDXMLElement elementWithName:@"Hotspot" stringValue:[connectionData objectForKey:@"hotspot"]];
            DDXMLElement *nodeInteractionType = [DDXMLElement elementWithName:@"Interaction_Type" stringValue:[connectionData objectForKey:@"interactionType"]];
            
            //Add above nodes to interaction
            [nodeInteraction addChild:nodeInteractionObject1];
            [nodeInteraction addChild:nodeInteractionObject2];
            [nodeInteraction addChild:nodeInteractionHotspot];
            [nodeInteraction addChild:nodeInteractionType];
            
            //Add interaction node to menu item
            [nodeMenuItem addChild:nodeInteraction];
        }
    }
    else {
        nodeMenuItem = [DDXMLElement elementWithName:@"Menu_Item" stringValue:@"NULL"];
    }
    
    //Add above node to input
    [nodeInput addChild:nodeMenuItem];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when a user action is verified as either correct or incorrect
 */
- (void)logVerification:(BOOL)verification forAction:(NSString *)action context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:action];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Verify Action"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
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
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an object is reset (i.e., snaps object back to original position after an error)
 */
- (void)logResetObject:(NSString *)object startPos:(CGPoint)start endPos:(CGPoint)end context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Reset Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start_Position" stringValue:[NSString stringWithFormat:@"%f, %f", start.x, start.y]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End_Position" stringValue:[NSString stringWithFormat:@"%f, %f", end.x, end.y]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an object appears or disappears
 */
- (void)logAppearOrDisappearObject:(NSString *)object ofType:(NSString *)objectType context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:objectType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    
    //Add above node to input
    [nodeInput addChild:nodeObject];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an object image is swapped for an alternative image
 */
- (void)logSwapImageForObject:(NSString *)object altImage:(NSString *)image context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Swap Image"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    DDXMLElement *nodeAlternativeImage = [DDXMLElement elementWithName:@"Alternative_Image" stringValue:image];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeAlternativeImage];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an object is animated
 */
- (void)logAnimateObject:(NSString *)object forAction:(NSString *)animateAction context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Animate Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    DDXMLElement *nodeAnimateAction = [DDXMLElement elementWithName:@"Animate_Action" stringValue:animateAction];
    
    //Add above nodes to input
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeAnimateAction];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an object is tapped
 */
- (void)logTapObject:(NSString *)object :(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Image"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap Object"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for input information
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:object];
    
    //Add above node to input
    [nodeInput addChild:nodeObject];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an underlined vocabulary word is tapped
 */
- (void)logTapWord:(NSString *)word :(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Word"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap Word"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for input information
    DDXMLElement *nodeWord = [DDXMLElement elementWithName:@"Word" stringValue:word];
    
    //Add above node to input
    [nodeInput addChild:nodeWord];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when audio is played in a manipulation activity
 */
- (void)logPlayManipulationAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Audio"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:audioType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeAudioName = [DDXMLElement elementWithName:@"Audio_Name" stringValue:audioName];
    DDXMLElement *nodeAudioLanguage = [DDXMLElement elementWithName:@"Audio_Language" stringValue:language];
    
    //Add above nodes to input
    [nodeInput addChild:nodeAudioName];
    [nodeInput addChild:nodeAudioLanguage];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

# pragma mark Navigation

/*
 * Logging for when Next button is pressed in a manipulation activity
 */
- (void)logPressNextInManipulationActivity:(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Press Next"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for button type
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an emergency swipe is performed in a manipulation activity
 */
- (void)logEmergencySwipe:(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Gesture"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Skip Content"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for button type
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Gesture_Type" stringValue:@"Emergency Swipe"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for loading a step
 */
- (void)logLoadStep:(NSInteger)stepNumber ofType:(NSString *)stepType context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Step"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Step"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeStepNumber = [DDXMLElement elementWithName:@"Step_Number" stringValue:[NSString stringWithFormat:@"%d", stepNumber]];
    DDXMLElement *nodeStepType = [DDXMLElement elementWithName:@"Step_Type" stringValue:stepType];
    
    //Add above nodes to input
    [nodeInput addChild:nodeStepNumber];
    [nodeInput addChild:nodeStepType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for loading a sentence
 */
- (void)logLoadSentence:(NSInteger)sentenceNumber withText:(NSString *)sentenceText manipulationSentence:(BOOL)manipulationSentence context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Sentence"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Sentence"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeSentenceNumber = [DDXMLElement elementWithName:@"Sentence_Number" stringValue:[NSString stringWithFormat:@"%d", sentenceNumber]];
    sentenceText = [sentenceText isEqualToString:@""] || sentenceText == nil ? @"NULL" : sentenceText;
    DDXMLElement *nodeSentenceText = [DDXMLElement elementWithName:@"Sentence_Text" stringValue:sentenceText];
    DDXMLElement *nodeManipulationSentence = [DDXMLElement elementWithName:@"Manipulation_Sentence" stringValue:manipulationSentence ? @"Yes" : @"No"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeSentenceNumber];
    [nodeInput addChild:nodeSentenceText];
    [nodeInput addChild:nodeManipulationSentence];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for loading a page
 */
- (void)logLoadPage:(NSString *)pageLanguage mode:(NSString *)pageMode number:(NSInteger)pageNumber context:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Page"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Page"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodePageLanguage = [DDXMLElement elementWithName:@"Page_Language" stringValue:pageLanguage];
    DDXMLElement *nodePageMode = [DDXMLElement elementWithName:@"Page_Mode" stringValue:pageMode];
    DDXMLElement *nodePageNumber = [DDXMLElement elementWithName:@"Page_Number" stringValue:[NSString stringWithFormat:@"%d", pageNumber]];
    
    //Add above nodes to input
    [nodeInput addChild:nodePageLanguage];
    [nodeInput addChild:nodePageMode];
    [nodeInput addChild:nodePageNumber];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for when Library button is pressed to return to library view
 */
- (void)logPressLibrary:(ManipulationContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Return to Library"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Library"];
    
    //Add above nodes to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

/*
 * Logging for when a manipulation activity is completed
 */
- (void)logCompleteManipulation:(ManipulationContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Manipulation Activity"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Completed Manipulation Activity"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    [nodeInput setStringValue:@"NULL"];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeManipulationContext = [self getManipulationContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeManipulationContext];
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

# pragma mark - Logging (Assessment)

/*
 * Logging for when an assessment question is displayed
 */
- (void)logDisplayAssessmentQuestion:(NSString *)questionText withOptions:(NSArray *)answerOptions context:(AssessmentContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Assessment Question"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Display Assessment Question"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeQuestionText = [DDXMLElement elementWithName:@"Question_Text" stringValue:questionText];
    DDXMLElement *nodeAnswerOptions = [DDXMLElement elementWithName:@"Answer_Options" stringValue:[NSString stringWithFormat:@"%@, %@, %@, %@", answerOptions[0],answerOptions[1], answerOptions[2], answerOptions[3]]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeQuestionText];
    [nodeInput addChild:nodeAnswerOptions];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an assessment answer is selected
 */
- (void)logSelectAssessmentAnswer:(NSString *)selectedAnswer context:(AssessmentContext *)context {
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Assessment Answer"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Select Assessment Answer"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeSelectedAnswer = [DDXMLElement elementWithName:@"Selected_Answer" stringValue:selectedAnswer];
    
    //Add above nodes to input
    [nodeInput addChild:nodeSelectedAnswer];

    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for verifying when an assessment answer is verified as either correct or incorrect
 */
- (void)logVerification:(BOOL)verification forAssessmentAnswer:(NSString *)answer context:(AssessmentContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:answer];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Verify Assessment Answer"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
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
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when audio is played in an assessment activity
 */
- (void)logPlayAssessmentAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(AssessmentContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Audio"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:audioType];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeAudioName = [DDXMLElement elementWithName:@"Audio_Name" stringValue:audioName];
    DDXMLElement *nodeAudioLanguage = [DDXMLElement elementWithName:@"Audio_Language" stringValue:language];
    
    //Add above nodes to input
    [nodeInput addChild:nodeAudioName];
    [nodeInput addChild:nodeAudioLanguage];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when an emergency swipe is performed in an assessment activity
 */
- (void)logAssessmentEmergencySwipe:(AssessmentContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Gesture"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Skip Content"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for button type
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Gesture_Type" stringValue:@"Emergency Swipe"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

# pragma mark Navigation

/*
 * Logging for when the audio buttons for either questions or answers are tapped in an assessment activity
 */
- (void)logTapAssessmentAudioButton:(NSString *)buttonName buttonType:(NSString *)type context:(AssessmentContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Tap Assessment Audio"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for input information
    DDXMLElement *nodeButtonName = [DDXMLElement elementWithName:@"Button_Name" stringValue:buttonName];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:type];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonName];
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for when Next button is pressed in an assessment activity
 */
- (void)logPressNextInAssessmentActivity:(AssessmentContext *)context {
    userActionID++;
    
    //Start with base node for user action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:USER];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Button"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Press Next"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create node for input information
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button_Type" stringValue:@"Next"];
    
    //Add above node to input
    [nodeInput addChild:nodeButtonType];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
}

/*
 * Logging for loading an assessment step
 */
- (void)logLoadAssessmentStep:(NSInteger)assessmentStepNumber context:(AssessmentContext *)context {
    userActionID++;
    
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Assessment Step"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Load Assessment Step"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    
    //Create nodes for input information
    DDXMLElement *nodeAssessmentStepNumber = [DDXMLElement elementWithName:@"Assessment_Step_Number" stringValue:[NSString stringWithFormat:@"%d", assessmentStepNumber]];
    
    //Add above nodes to input
    [nodeInput addChild:nodeAssessmentStepNumber];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

- (void)logCompleteAssessment:(AssessmentContext *)context {
    //Start with base node for system action
    DDXMLElement *nodeBaseAction = [self getBaseActionForActor:SYSTEM];
    [study addChild:nodeBaseAction];
    
    //Set selection
    DDXMLElement *nodeSelection = [[nodeBaseAction elementsForName:@"Selection"] objectAtIndex:0];
    [nodeSelection setStringValue:@"Assessment Activity"];
    
    //Set action
    DDXMLElement *nodeAction = [[nodeBaseAction elementsForName:@"Action"] objectAtIndex:0];
    [nodeAction setStringValue:@"Completed Assessment Activity"];
    
    //Get input
    DDXMLElement *nodeInput = [[nodeBaseAction elementsForName:@"Input"] objectAtIndex:0];
    [nodeInput setStringValue:@"NULL"];
    
    //Get context
    DDXMLElement *nodeContext = [[nodeBaseAction elementsForName:@"Context"] objectAtIndex:0];
    
    //Create nodes for context information
    DDXMLElement *nodeAssessmentContext = [self getAssessmentContext:context];
    DDXMLElement *nodeStudyContext = [self getStudyContext:studyContext];
    
    //Add above nodes to context
    [nodeContext addChild:nodeAssessmentContext];
    [nodeContext addChild:nodeStudyContext];
    
    [self writeLogFile];
}

#pragma mark - Saving/loading progress files

/*
 * Loads the progress information from file for the given student
 */
- (Progress *)loadProgress:(Student *)student {
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    
    //Get progress file name and path
    NSString *progressFileName = [NSString stringWithFormat:@"%@_progress.xml", [student participantCode]];
    NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ProgressFiles/CurrentSession/%@", progressFileName]];
    
    //Try to load progress data
    NSData *progressData = [[NSMutableData alloc] initWithContentsOfFile:progressFilePath];
    
    //If the file doesn't exist in the CurrentSession Folder, check the Master Folder
    if (progressData == nil){
        progressFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ProgressFiles/Master/%@", progressFileName]];
        progressData = [[NSMutableData alloc] initWithContentsOfFile:progressFilePath];
        
        //Copy data from Master Folder to CurrentSession Folder
        if (progressData != nil) {
            [progressData writeToFile:progressFilePath atomically:YES];
        }
    }
    
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
    NSString *progressFileName = [NSString stringWithFormat:@"%@_progress.xml", [student participantCode]];
    NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ProgressFiles/CurrentSession/%@", progressFileName]];
    
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
- (void)uploadFilesForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler failure:(void (^)(BOOL failure))failureHandler{
    //Dropbox access token
    NSString *accessToken = @"48Rzy87TQDAAAAAAAAAA9AROwtWgoteHL8WIB8yzZRN8o0VO3twZCZmiltaQLEUQ";
    
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
    //NSString *progressFileName = [NSString stringWithFormat:@"%@_progress.xml", [student participantCode]];
    //NSArray *filesToUpload = [[NSArray alloc] initWithObjects:logFileName, progressFileName, nil];
    NSMutableArray *filesToUpload = [[NSMutableArray alloc]initWithObjects:logFileName, nil];
    
    //Check if CurrentSession Folder exists and has files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //TODO: changes file path to strip file name out of var filepath
    NSString *currentSessionFilePath = [documentsDirectory stringByAppendingPathComponent:@"ProgressFiles/CurrentSession"]; //Path of file on iPad
    NSLog(@"%@", currentSessionFilePath);
        NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:currentSessionFilePath error:nil];
        for (NSString *file in listOfFiles) {
            NSLog(@"%@", file);
            [filesToUpload addObject:file];
        }
    
    //Upload each file to Dropbox
    for (NSString *fileToUpload in filesToUpload) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileToUpload]; //Path of file on iPad
        
        NSString *content = [[NSString alloc] initWithContentsOfFile:filePath usedEncoding:nil error:nil];
        
        NSString *dbDirName = @"";
        NSString *locDirName = @"";
        NSString *pathExtension = [fileToUpload pathExtension];
        
        //Determine name of folder to put file in based on its extension
        if ([pathExtension isEqualToString:@"txt"]) {
            dbDirName = @"LogFiles";
        }
        else if ([pathExtension isEqualToString:@"xml"]) {
            dbDirName = @"ProgressFiles/CurrentSession";
            locDirName = @"ProgressFiles";
        }
        else {
            dbDirName = @"UnknownFiles";
        }
        
        NSString *dbFileName = [NSString stringWithFormat:@"%@/%@", dbDirName, fileToUpload]; //Name of file to use on Dropbox
        NSString *locFileNameDesination = [NSString stringWithFormat:@"%@/Backup/%@", locDirName, fileToUpload]; //Name of file path destination
        NSString *locFileNameOrigin = [NSString stringWithFormat:@"%@/CurrentSession/%@", locDirName, fileToUpload]; //Name of file path origin
        NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *localPathDestination = [localDir stringByAppendingPathComponent:locFileNameDesination];
        NSString *localPathOrigin = [localDir stringByAppendingPathComponent:locFileNameOrigin];
        
        //Path to each directory
        NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:@"ProgressFiles"];
        NSString *currentSessionProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"CurrentSession"];
        NSString *backupProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"Backup"];
        
        //Check if the directory paths actually exist, if they do not, then create the directories
        BOOL isDir;
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:progressFilePath isDirectory:&isDir])
            if(![fileManager createDirectoryAtPath:progressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                NSLog(@"Error: Create folder failed %@", progressFilePath);
        
        if(![fileManager fileExistsAtPath:currentSessionProgressFilePath isDirectory:&isDir])
            if(![fileManager createDirectoryAtPath:currentSessionProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                NSLog(@"Error: Create folder failed %@", currentSessionProgressFilePath);
        
        if(![fileManager fileExistsAtPath:backupProgressFilePath isDirectory:&isDir])
            if(![fileManager createDirectoryAtPath:backupProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                NSLog(@"Error: Create folder failed %@", backupProgressFilePath);
        
        assert(fileManager != nil);
        NSError* error = nil;
        //Move file from CurrentSession to Backup folder
        [fileManager moveItemAtPath:localPathOrigin toPath:localPathDestination error:&error];
        
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
                completionHandler(YES);
                failureHandler(NO);
            }
            else {
                NSLog(@"Failed to upload student files to Dropbox. Error: %@", error);
                completionHandler(NO);
                failureHandler(YES);
            }
        }];
        
        [doDataTask resume];
    }
}

/*
 * Downloads progress file from Dropbox for specified student
 */
- (void)downloadProgressForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler failure:(void (^)(BOOL failure))failureHandler {
    
    //Determine if any progress files exist for student in local CurrentSession Folder
    //NSString *progressFileName = [NSString stringWithFormat:@"%@_progress.xml", [student participantCode]];
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    //NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ProgressFiles/CurrentSession/%@", progressFileName]];
     
    //Attempt to get file from local CurrentSession Folder
    //NSString *content = [[NSString alloc] initWithContentsOfFile:filePath usedEncoding:nil error:nil];
    
    /*
    //Check if CurrentSession Folder exists and has files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //TODO: changes file path to strip file name out of var filepath
    if([fileManager fileExistsAtPath:filePath]){
        NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    }*/
    
    //New Code Starts Here
    
    //Dropbox access token
    NSString *accessToken = @"48Rzy87TQDAAAAAAAAAA9AROwtWgoteHL8WIB8yzZRN8o0VO3twZCZmiltaQLEUQ";
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Authorization": [NSString stringWithFormat:@"Bearer %@", accessToken],
                                                   @"Content-Type": @"application/json"
                                                   };
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    //Request a list of files from /Progress/Master directory in dropbox to download 1 at a time.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.dropboxapi.com/2/files/list_folder"]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:1000];
    
    // Convert your data and set your request's HTTPBody property
    NSString *stringData = @"{\"path\":\"/ProgressFiles/Master\",\"recursive\":\"false\",\"include_media_info\":\"false\",\"include_deleted\":\"false\",\"include_has_explicit_shared_members\":\"false\"}";
    
    NSDictionary *jsonDict = @{
                               @"path" : @"/ProgressFiles/Master",
                               /*@"recursive" : (BOOL)false,
                               @"include_media_info" : (BOOL)false,
                               @"include_deleted" : (BOOL)false,
                               @"include_has_explicit_shared_members" : (BOOL)false,*/
                              };
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                dataWithJSONObject:jsonDict
                options:0
                error:&jsonError];
    
    /*
    NSData *requestBodyData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    id jsonResponse = [NSJSONSerialization
                       JSONObjectWithData:requestBodyData
                       options:0
                       error:&jsonError];
     */
    request.HTTPBody = jsonData;
    
    // Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSMutableArray *masterProgressFiles = [[NSMutableArray alloc] init];
    
    NSURLSessionDataTask *doDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(error)
        {
            //NSLog(@"%@", error);
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        long responseCode = (long)[httpResponse statusCode];
        NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //NSLog(@"%@", myString);
        //NSLog(@"%@", response);
        //NSLog(@"%@", httpResponse);
        
        NSError *jsonError = nil;
        id jsonResponse = [NSJSONSerialization
                     JSONObjectWithData:data
                     options:0
                     error:&jsonError];
        
        if(jsonError) { /* JSON was malformed, act appropriately here */ }
            //NSLog(@"%@", jsonError);
        ;        // the originating poster wants to deal with dictionaries;
        // assuming you do too then something like this is the first
        // validation step:
        if([jsonResponse isKindOfClass:[NSDictionary class]])
        {
            /* proceed with results as you like; the assignment to
             an explicit NSDictionary * is artificial step to get
             compile-time checking from here on down (and better autocompletion
             when editing). You could have just made object an NSDictionary *
             in the first place but stylistically you might prefer to keep
             the question of type open until it's confirmed */
            
            NSDictionary *results = jsonResponse;
            NSDictionary *entries = [results objectForKey:@"entries"];
            for (NSDictionary *entry in entries) {
                [masterProgressFiles  addObject:[entry objectForKey:@"name"]];
            }
            
            for (NSString *file in masterProgressFiles) {
                
                NSURLSessionConfiguration *getFilesSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
                getFilesSessionConfiguration.HTTPAdditionalHeaders = @{
                                                                       @"Authorization": [NSString stringWithFormat:@"Bearer %@", accessToken],
                                                                       @"Dropbox-API-Arg" : [NSString stringWithFormat:@"{\"path\":\"/ProgressFiles/Master/%@\"}", file]
                                                                       };
                
                NSURLSession *downloadFilesSession = [NSURLSession sessionWithConfiguration:getFilesSessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://content.dropboxapi.com/2/files/download"]];
                [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
                [request setHTTPMethod:@"POST"];
                [request setTimeoutInterval:1000];
                
                NSURLSessionDataTask *doDataTask = [downloadFilesSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    long responseCode = (long)[httpResponse statusCode];
                    NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    //NSLog(@"%@", myString);
                    //NSLog(@"%@", response);
                    //NSLog(@"%@", httpResponse);
                    
                    if (!error && responseCode != 404) {
                        NSLog(@"Successfully downloaded progress file for student from Dropbox.");
                        
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = [paths objectAtIndex:0];
                        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ProgressFiles/Master/%@", file]]; //Path of file on iPad
                        NSString *progressFilePath = [documentsDirectory stringByAppendingPathComponent:@"ProgressFiles"];
                        NSString *masterProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"Master"];
                        
                        NSLog(@"%@", filePath);
                        
                        BOOL isDir;
                        NSFileManager *fileManager= [NSFileManager defaultManager];
                        if(![fileManager fileExistsAtPath:progressFilePath isDirectory:&isDir])
                            if(![fileManager createDirectoryAtPath:progressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                                NSLog(@"Error: Create folder failed %@", progressFilePath);
                        
                        if(![fileManager fileExistsAtPath:masterProgressFilePath isDirectory:&isDir])
                            if(![fileManager createDirectoryAtPath:masterProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                                NSLog(@"Error: Create folder failed %@", masterProgressFiles);
                        
                        if([data writeToFile:filePath atomically:YES])
                        {
                            NSLog(@"Successfully wrote progress file to ProgressFiles/Master Folder");
                        }
                        
                        completionHandler(YES);
                        failureHandler(NO);
                    }
                    else {
                        NSLog(@"Failed to download progress file for student from Dropbox.");
                        
                        completionHandler(NO);
                        failureHandler(YES);
                    }
                }];
                
                [doDataTask resume];
            }
        }
        else
        {
            /* there's no guarantee that the outermost object in a JSON
             packet will be a dictionary; if we get here then it wasn't,
             so 'object' shouldn't be treated as an NSDictionary; probably
             you need to report a suitable error condition */
        }
    
        }];
    
        [doDataTask resume];
}

@end