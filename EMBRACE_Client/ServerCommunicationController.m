//
//  ServerCommunicationController.m
//  EMBRACE
//
//  Created by Rishabh Chaudhry on 12/17/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ServerCommunicationController.h"
#import "LibraryViewController.h"
#import "BookCellView.h"
#import "BookHeaderView.h"
#import "Book.h"
#import "PMViewController.h"
#import "foundation/foundation.h"
#import "DDXML.h"
#import "DDXMLNode.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"

DDXMLDocument *xmlDocTemp;
DDXMLElement *nodeStudyContext;
DDXMLElement *nodeStudy;

@implementation ServerCommunicationController

@synthesize student;
@synthesize movenum;
@synthesize bookView;
@synthesize study;
@synthesize xmlDoc;
@synthesize UserActionIDTag;
@synthesize studyConditionString;
@synthesize studyExperimenterString;
@synthesize userNameString;

#pragma mark Singleton Methods

+ (id)sharedManager {
    static ServerCommunicationController *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        //someProperty = [[NSString alloc] initWithString:@"Default Property Value"];
        
        //initialize xml document
        //study = (DDXMLElement *)[DDXMLNode elementWithName:@"study"];
        //DDXMLDocument *xmlDoctemp = [[DDXMLDocument alloc] initWithXMLString:@"<study/>" options:0 error:nil];
        xmlDocTemp = [[DDXMLDocument alloc] initWithXMLString:@"<study/>" options:0 error:nil];
        study = [xmlDocTemp rootElement];
        NSLog(@"gets to init of logging");
        
        //xmlDoc = xmlDoctemp;
        
        //DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithXMLString:@"<study/>" options:0 error:nil];
        
        //[xmlDoc setVersion:@"1.0"];
        //[xmlDoc setCharacterEncoding:@"UTF-8"];
        
        UserActionIDTag = 0;
        
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}


- (void)logUserName : (Student *) userdetails;
{
    //[super logDetails];
    //NSLog(@"NameRbh2: %@", [student firstName]);
    //NSLog(@"NameRbh2: %@", num);
    if(userdetails != nil) {
        //Logging Information to the server
        //Author: Udai Arora
        //Create a date object
        NSDate *currentTime = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
        NSString *resultString = [dateFormatter stringFromDate: currentTime];
        
        //Setup POST method with proper encoding
        NSString *post = [NSString stringWithFormat:@"fname=%@&lname=%@&time=%@",[userdetails firstName],[userdetails lastName],resultString];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        
        //Add the necessary URL, Headers and POST Body toNSMutableURLRequest
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://129.219.28.98/embrace-login.php"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        
        //To send and recieve a response
        NSURLResponse *response;
        NSData *POSTReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        NSString *theReply = [[NSString alloc] initWithBytes:[POSTReply bytes] length:[POSTReply length] encoding: NSASCIIStringEncoding];
        NSLog(@"Reply: %@", theReply);
        
        
    }
    
    
}

- (void) resetMovenum{
    movenum=@0;
    
}

- (void) logMovements :(NSString *)objid :(float) posx :(float) posy
{
 
    NSLog(@"%d", movenum.integerValue);
    movenum = @(movenum.integerValue + 1);
    //Setup POST method with proper encoding
    NSString *post = [NSString stringWithFormat:@"movenum=%d&objectid=%@&posx=%f&posy=%f", movenum.integerValue, objid, posx, posy];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    //Add the necessary URL, Headers and POST Body toNSMutableURLRequest
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://129.219.28.98/embrace-log-objects.php"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //To send and recieve a response
    NSURLResponse *response;
    NSData *POSTReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    NSString *theReply = [[NSString alloc] initWithBytes:[POSTReply bytes] length:[POSTReply length] encoding: NSASCIIStringEncoding];
    NSLog(@"Reply: %@", theReply);
    
   }

//local XML logging starts here

//stores general context of participant, condition and expermenter as global elements
-(void) logContext : (Student *) userdetails : (NSString *) studyCondition : (NSString *) studyExperimenter
{
    if(userdetails != nil) {
        //
        NSString *userNameValue = [NSString stringWithFormat:@"%@ %@",[userdetails firstName],[userdetails lastName]];
        
        studyExperimenterString = studyExperimenter;
        studyConditionString = studyCondition;
        userNameString = userNameValue;
        
        /*
        //Create a date object
        NSDate *currentTime = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
        NSString *timeStamp = [dateFormatter stringFromDate: currentTime];
        
         //Setup POST method with proper encoding
         NSString *userNameValue = [NSString stringWithFormat:@"%@&%@",[userdetails firstName],[userdetails lastName]];
         
        nodeStudyContext = [DDXMLElement elementWithName:@"Study Context" stringValue:[NSString stringWithFormat:@"%@ : %@ : %@", userNameValue, studyCondition, studyExperimenter]];
        [study addChild:nodeContext];
        
        //adds study context
        DDXMLElement *nodeUserName = [DDXMLElement elementWithName:@"Username" stringValue:userNameValue];
        DDXMLElement *nodeTimeStamp = [DDXMLElement elementWithName:@"Time Stamp" stringValue:timeStamp];
        DDXMLElement *nodeStudyCondition = [DDXMLElement elementWithName:@"Condition" stringValue:studyCondition];
        DDXMLElement *nodeStudyExperimentor = [DDXMLElement elementWithName:@"Experimentor" stringValue:studyExperimentor];
        [nodeContext addChild:nodeUserName];
        [nodeContext addChild:nodeTimeStamp];
        [nodeContext addChild:nodeStudyCondition];
        [nodeContext addChild:nodeStudyExperimentor];
        */
    }

}


//Logging Computer Actions
//logging object manipulation

//computer action -> recording why an action occured
//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerMoveObject : (NSString *) movingObjectID : (NSString *) collisionObjectID : (float) startPosX : (float) startPosY : (float) endPosX : (float) endPosY : (NSString *) hotspot : (NSString *) computerAction : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: image
     Action: Move Object(s)
     Input: What objects, what locations
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjectID];
    
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //logging Input
    DDXMLElement *nodeMovingObject = [DDXMLElement elementWithName:@"Object 1" stringValue:movingObjectID];
    DDXMLElement *nodeCollisionObject = [DDXMLElement elementWithName:@"Object 2" stringValue:collisionObjectID];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start Position" stringValue:[NSString stringWithFormat:@"%f, %f", startPosX, startPosY]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End Position" stringValue:[NSString stringWithFormat:@"%f, %f", endPosX, endPosY]];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeMovingObject];
    [nodeInput addChild:nodeCollisionObject];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Reset Object"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];

}

//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerResetObject : (NSString *) movingObjectID : (float) startPosX : (float) startPosY : (float) endPosX : (float) endPosY : (NSString *) computerAction :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: image
     Action: Reset Object(s)
     Input: What object(s), what locations
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjectID];
    
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //logging Input
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:movingObjectID];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start Position" stringValue:[NSString stringWithFormat:@"%f, %f", startPosX, startPosY]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End Position" stringValue:[NSString stringWithFormat:@"%f, %f", endPosX, endPosY]];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeObject];
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Reset Object"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//which object(s),context, userActionIDTag, why?
-(void) logComputerDisappearObject : (NSString *) objectID : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: image
     Action: Disappear Object(s)
     Input: What object(s)
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:objectID];
    
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //logging Input
    DDXMLElement *nodeObject = [DDXMLElement elementWithName:@"Object" stringValue:objectID];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeObject];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Disappear Object"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

-(void) logComputerSwapImages : (NSString *) objectID : (NSString *) swapImageID  : (NSString *) computerAction : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue :(NSString *) sentenceValue : (NSString *) stepValue
{

}
//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerGroupingObjects : (NSString *) movingObjectID : (NSString *) collisionObjectID :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: image     
     Action: Group Objects
     Input: What objects
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjectID];
    
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //logging Input
    DDXMLElement *nodeMovingObj = [DDXMLElement elementWithName:@"Object 1" stringValue:movingObjectID];
    
    DDXMLElement *nodeCollisionObj = [DDXMLElement elementWithName:@"Object 2" stringValue:collisionObjectID];
    
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeMovingObj];
    [nodeInput addChild:nodeCollisionObj];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Group Objects"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
   // bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//logging Computer navigation actions

- (void) logNextChapterNavigation : (NSString *) buttonPressedValue :(NSString *) curChapterValue :(NSString *) nextChapterValue :(NSString *) computerActionValue :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Next Chapter
     Input: from where to where
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //timestamp
   /* NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
    NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];*/
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeCurChapter = [DDXMLElement elementWithName:@"Current Chapter" stringValue:curChapterValue];
    DDXMLElement *nodeNextChapter = [DDXMLElement elementWithName:@"Next Chapter" stringValue:nextChapterValue];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeCurChapter];
    [nodeInput addChild:nodeNextChapter];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
    
}

- (void) logNextPageNavigation : (NSString *) buttonPressedValue :(NSString *) curPageValue : (NSString *) nextPageValue :(NSString *) computerActionValue :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Next Chapter
     Input: from where to where
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    //DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    //[nodeInput addChild:nodeButtonPressed];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeCurPage = [DDXMLElement elementWithName:@"Current Page" stringValue:curPageValue];
    DDXMLElement *nodeNextPage = [DDXMLElement elementWithName:@"Next Page" stringValue:nextPageValue];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeCurPage];
    [nodeInput addChild:nodeNextPage];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

- (void) logNextSentenceNavigation : (NSString *) buttonPressedValue :(NSString *) curSentenceValue :(NSString *)nextSentenceValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Next Chapter
     Input: from where to where
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for computer action
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    //DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    
    //[nodeInput addChild:nodeButtonPressed];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeCurSentence = [DDXMLElement elementWithName:@"Current Sentence" stringValue:curSentenceValue];
    DDXMLElement *nodeNextSentence = [DDXMLElement elementWithName:@"Next Sentence" stringValue:nextSentenceValue];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeCurSentence];
    [nodeInput addChild:nodeNextSentence];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];

    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

- (void) logNextStepNavigation : (NSString *) buttonPressedValue : (NSString *) curStepValue :(NSString *) nextStepValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Next Chapter
     Input: from where to where
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    //DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    
    //[nodeInput addChild:nodeButtonPressed];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeCurStep = [DDXMLElement elementWithName:@"Current Step" stringValue:curStepValue];
    DDXMLElement *nodeNextStep = [DDXMLElement elementWithName:@"Next Step" stringValue:nextStepValue];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeCurStep];
    [nodeInput addChild:nodeNextStep];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}


//logging none object manipulation actions

//logging object verificiation: correct | incorrect
-(void) logComputerVerification: (BOOL) verificationValue : (NSString *) objectSelected : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Action Verification
     Input: What outcome, what action
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:objectSelected];
    
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    
    //logging Input
    DDXMLElement *nodeVerficiation = [DDXMLElement elementWithName:@"Verification" stringValue:[NSString stringWithFormat:@"%hhd", verificationValue]];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeVerficiation];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Display Menu"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];

}

//logging audio: incorrect | introduction
-(void) logComputerPlayAudio: (NSString *) movingObjectID : (NSString *) audioValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Play Audio
     Input: What Audio
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    UserActionIDTag++;
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    NSString *objectSelected = movingObjectID;
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:objectSelected];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeAudioType = [DDXMLElement elementWithName:@"Audio Type" stringValue:audioValue];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeAudioType];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Reset Object"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//logging displayMenuItems
-(void) logComputerDisplayMenuItems :  (NSString *) selectedMenuItemID : (NSArray *) displayedMenuInteractions :(NSArray *)displayedMenuImages : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    /*
     Action Type:
     UserActionIDTag:
     Selection: ??
     Action: Display Menu Items
     Input: displayedMenuItems
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    UserActionIDTag++;
    
    //logging structure for user actions
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"Computer Action"];
    [study addChild:nodeComputerAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:@"Image"];
    
    //[nodeInput addChild:nodeButtonPressed];
    DDXMLElement *nodeMenuOptions;
    
    NSLog(@"after nodeselect");
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeDisplayedMenuItem1;
    DDXMLElement *nodeDisplayedMenuItem2;
    DDXMLElement *nodeDisplayedMenuItem3;
    
    NSLog(@"before if statement, Num Interactions: %d", [displayedMenuInteractions count]);
    if( [displayedMenuInteractions count] == 2 )
    {
        NSLog(@"Gets to correct first Statement");
        
        NSString *menuItem;
        
        NSLog(@"Total Images: %d", [displayedMenuImages count]);
        
        for( int i=0; i<[displayedMenuImages count];i++ )
        {
            NSLog(@"%@", [displayedMenuImages objectAtIndex:i]);
            if( [[displayedMenuImages objectAtIndex:i] isEqual:@"1"])
            {
                NSLog(@"gets to first function");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:1]];
                
                for (int j=2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem1 = [DDXMLElement elementWithName:@"Menu Item 1" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:0]]];
                
                NSLog(@"gets to second function");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:i+1]];
                for (int j=i+2; j<[displayedMenuImages count]; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                }
                
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem2 = [DDXMLElement elementWithName:@"Menu Item 2" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:1]]];
            }
            
        }
        
        //adding child nodes to Input parent
        [nodeInput addChild:nodeDisplayedMenuItem1];
        [nodeInput addChild:nodeDisplayedMenuItem2];
    }
    else
    {
        NSLog(@"Gets to correct first Statement");
        
        NSString *menuItem;
        
        NSLog(@"Total Images: %d", [displayedMenuImages count]);
        
        int markMidmenu =0;
        for( int i=0; i<[displayedMenuImages count];i++ )
        {
            NSLog(@"%@", [displayedMenuImages objectAtIndex:i]);
            if ([[displayedMenuImages objectAtIndex:i] isEqual:@"1"])
            {
                markMidmenu = i;
                NSLog(@"gets to first function for 3 images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:1]];
                NSLog(@"MenuItem String: %@", menuItem);
                
                for (int j=2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem1 = [DDXMLElement elementWithName:@"Menu Item 1" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:0]]];
            }
            
            if( [[displayedMenuImages objectAtIndex:i] isEqual:@"2"])
            {
                NSLog(@"gets to second function for 3 images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:markMidmenu+1]];
                NSLog(@"MenuItem String: %@", menuItem);
                
                for (int j=markMidmenu+2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem2 = [DDXMLElement elementWithName:@"Menu Item 2" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:1]]];
                
                NSLog(@"gets to third function for images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:i+1]];
                for (int j=i+2; j<[displayedMenuImages count]; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                }
                
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem3 = [DDXMLElement elementWithName:@"Menu Item 3" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:2]]];
            }
            
        }
        
        //adding child nodes to Input parent
        [nodeInput addChild:nodeDisplayedMenuItem1];
        [nodeInput addChild:nodeDisplayedMenuItem2];
        [nodeInput addChild:nodeDisplayedMenuItem3];
    }
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeMenuOptions];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:@"Display Menu"];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeComputerAction addChild:nodeUserActionID];
    [nodeComputerAction addChild:nodeSelection];
    [nodeComputerAction addChild:nodeAction];
    [nodeComputerAction addChild:nodeInput];
    [nodeComputerAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}


//logging User Actions

//logging UserNavigation
//add logging should be called in NextButtonPressed
-(void) logUserNextButtonPressed: (NSString *) buttonPressedValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    
    UserActionIDTag++;
    
    /*
     UserActionID : UserActionIDTag;
     Selection: Button
     Action: Call Computer Navigation
     Input: Button Type: Next Button
     Context: story, chapter, page, sentence, step, username, condition, experimenter
     */
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"User Action"];
    [study addChild:nodeUserAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    //DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    
    //[nodeInput addChild:nodeButtonPressed];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button Type" stringValue:@"Next Button"];
    /*
    DDXMLElement *nodeCurChapter = [DDXMLElement elementWithName:@"Current Chapter" stringValue:curChapterValue];
    DDXMLElement *nodeNextChapter = [DDXMLElement elementWithName:@"Next Chapter" stringValue:nextChapterValue];
    */
    
    //adding child nodes to Input parent
    //[nodeInput addChild:nodeCurChapter];
    //[nodeInput addChild:nodeNextChapter];
    [nodeInput addChild:nodeButtonType];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeUserAction addChild:nodeUserActionID];
    [nodeUserAction addChild:nodeSelection];
    [nodeUserAction addChild:nodeAction];
    [nodeUserAction addChild:nodeInput];
    [nodeUserAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//add logging should be called in load first page
-(void) logStoryButtonPressed: (NSString *) buttonPressedValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    //which story? chapter title, book title, page type, should default page 1 sentence 1
    /*
     UserActionIDTag++;
     Selection: Button
     Action: Call Computer Navigation
     Input: Button Type: Story Button
     Context: story, chapter, page: 1, sentence: 1, step: 1, username, condition, experimenter
     */
    
    UserActionIDTag++;
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"User Action"];
    [study addChild:nodeUserAction];
    
    //logging userAction relationship
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    
    //logging selection
    DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:buttonPressedValue];
    //DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    
    //[nodeInput addChild:nodeButtonPressed];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeButtonType = [DDXMLElement elementWithName:@"Button Type" stringValue:chapterValue];
    /*
     DDXMLElement *nodeCurChapter = [DDXMLElement elementWithName:@"Current Chapter" stringValue:curChapterValue];
     DDXMLElement *nodeNextChapter = [DDXMLElement elementWithName:@"Next Chapter" stringValue:nextChapterValue];
     */
    
    //adding child nodes to Input parent
    //[nodeInput addChild:nodeCurChapter];
    //[nodeInput addChild:nodeNextChapter];
    [nodeInput addChild:nodeButtonType];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeUserAction addChild:nodeUserActionID];
    [nodeUserAction addChild:nodeSelection];
    [nodeUserAction addChild:nodeAction];
    [nodeUserAction addChild:nodeInput];
    [nodeUserAction addChild:nodeContext];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//logging User object Manipulation
//logging move object
- (void) logUserMoveObject : (NSString *)movingObjID : (float) startposx :(float) startposy :(float) endposx :(float) endposy : (NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    UserActionIDTag++;
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    
    DDXMLElement *nodeUserActionID = [DDXMLElement elementWithName:@"User Action ID" stringValue:[NSString stringWithFormat:@"%d",UserActionIDTag]];
    [nodeUserAction addChild:nodeUserActionID];
    
    //logging selection
    
    //checks if selected object is grouped if not use movingObjId for selection else groupedObjects array
    DDXMLElement *nodeSelection;
    
    nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjID];
    
   /* if([groupedObjects count] == 1)
    {
    
        nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjID];
    }
    else
    {
        nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:[NSString stringWithFormat:@"%@, %@", groupedObjects[0],groupedObjects[1]]];
    }*/
    
    //[nodeUserAction addChild:nodeSelection];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeStartPosition = [DDXMLElement elementWithName:@"Start Position" stringValue:[NSString stringWithFormat:@"%f, %f", startposx, startposy]];
    DDXMLElement *nodeEndPosition = [DDXMLElement elementWithName:@"End Position" stringValue:[NSString stringWithFormat:@"%f, %f", endposx, endposy]];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeStartPosition];
    [nodeInput addChild:nodeEndPosition];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    //logging Context
    DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeUserAction addChild:nodeSelection];
    [nodeUserAction addChild:nodeAction];
    [nodeUserAction addChild:nodeInput];
    [nodeUserAction addChild:nodeContext];
    
    //add userAction to story parent
    [study addChild: nodeUserAction];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
    
}

//logging groupings
-(void) logGrouping: (NSString *)movingObjID : (NSString *) collisionObjID : (NSArray *) groupedObjects : (NSString *) computerActionValue : (NSString *) storyValue : (NSString *) pageValue : (NSString *) chapterValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    [study addChild:nodeUserAction];
    
    //logging selection
    DDXMLElement *nodeSelection;
    
    //checks if selected object is grouped if not use movingObjId for selection else groupedObjects array
    if([groupedObjects count] == 1)
    {
        
        nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:movingObjID];
    }
    else
    {
        nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:[NSString stringWithFormat:@"%@, %@", groupedObjects[0],groupedObjects[1]]];
    }
    
    //[nodeInput addChild:nodeSelection];
    
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeCollisionObj = [DDXMLElement elementWithName:@"Start Position" stringValue:collisionObjID];
    
    //adding child nodes to Input parent
    [nodeInput addChild:nodeCollisionObj];
    
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    //logging Context
        DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeUserAction addChild:nodeSelection];
    [nodeUserAction addChild:nodeAction];
    [nodeUserAction addChild:nodeInput];
    [nodeUserAction addChild:nodeContext];
    
    //add userAction to story parent
    [study addChild: nodeUserAction];

    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];
}

//logging menu
- (void) logMenuSelection : (NSString *) selectedMenuItemID : (NSArray *) displayedMenuInteractions :(NSArray *)displayedMenuImages :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) pageValue : (NSString *) chapterValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    
    //logging selection
    
    NSLog(@"before add nodeselect");
    //checks if selected object is grouped if not use movingObjId for selection else groupedObjects array
        DDXMLElement *nodeSelection = [DDXMLElement elementWithName:@"Selection" stringValue:selectedMenuItemID];
    
    NSLog(@"after nodeselect");
    //logging Input
    DDXMLElement *nodeInput = [DDXMLElement elementWithName:@"Input"];
    DDXMLElement *nodeDisplayedMenuItem1;
    DDXMLElement *nodeDisplayedMenuItem2;
    DDXMLElement *nodeDisplayedMenuItem3;
    
    NSLog(@"before if statement, Num Interactions: %d", [displayedMenuInteractions count]);
    if( [displayedMenuInteractions count] == 2 )
    {
        NSLog(@"Gets to correct first Statement");
        
        NSString *menuItem;
        
        NSLog(@"Total Images: %d", [displayedMenuImages count]);
        
        for( int i=0; i<[displayedMenuImages count];i++ )
        {
            NSLog(@"%@", [displayedMenuImages objectAtIndex:i]);
            if( [[displayedMenuImages objectAtIndex:i] isEqual:@"1"])
            {
                NSLog(@"gets to first function");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:1]];
                
                for (int j=2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem1 = [DDXMLElement elementWithName:@"Menu Item 1" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:0]]];
                
                NSLog(@"gets to second function");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:i+1]];
                for (int j=i+2; j<[displayedMenuImages count]; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                }
                
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem2 = [DDXMLElement elementWithName:@"Menu Item 2" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:1]]];
            }
            
        }
        
        //adding child nodes to Input parent
        [nodeInput addChild:nodeDisplayedMenuItem1];
        [nodeInput addChild:nodeDisplayedMenuItem2];
    }
    else
    {
        NSLog(@"Gets to correct first Statement");
        
        NSString *menuItem;
        
        NSLog(@"Total Images: %d", [displayedMenuImages count]);
        
        int markMidmenu =0;
        for( int i=0; i<[displayedMenuImages count];i++ )
        {
            NSLog(@"%@", [displayedMenuImages objectAtIndex:i]);
            if ([[displayedMenuImages objectAtIndex:i] isEqual:@"1"])
            {
                markMidmenu = i;
                NSLog(@"gets to first function for 3 images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:1]];
                NSLog(@"MenuItem String: %@", menuItem);
                
                for (int j=2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem1 = [DDXMLElement elementWithName:@"Menu Item 1" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:0]]];
            }
            
            if( [[displayedMenuImages objectAtIndex:i] isEqual:@"2"])
            {
                NSLog(@"gets to second function for 3 images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:markMidmenu+1]];
                NSLog(@"MenuItem String: %@", menuItem);
                
                for (int j=markMidmenu+2; j<i; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                    NSLog(@"MenuItem String: %@", menuItem);
                }
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem2 = [DDXMLElement elementWithName:@"Menu Item 2" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:1]]];
                
                NSLog(@"gets to third function for images");
                menuItem = [NSString stringWithFormat:@"%@", [displayedMenuImages objectAtIndex:i+1]];
                for (int j=i+2; j<[displayedMenuImages count]; j++)
                {
                    menuItem = [NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuImages objectAtIndex:j] ];
                }
                
                NSLog(@"MenuItem String: %@", menuItem);
                
                nodeDisplayedMenuItem3 = [DDXMLElement elementWithName:@"Menu Item 3" stringValue:[NSString stringWithFormat:@"%@, %@", menuItem, [displayedMenuInteractions objectAtIndex:2]]];
            }
            
        }
        
        //adding child nodes to Input parent
        [nodeInput addChild:nodeDisplayedMenuItem1];
        [nodeInput addChild:nodeDisplayedMenuItem2];
        [nodeInput addChild:nodeDisplayedMenuItem3];
    }
   
    //logging action
    DDXMLElement *nodeAction = [DDXMLElement elementWithName:@"Action" stringValue:computerActionValue];
    //DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    //[nodeAction addChild:nodeComputerAction];
    
    //logging Context
     DDXMLElement *nodeContext = [[ServerCommunicationController sharedManager] returnContext:storyValue :chapterValue :pageValue :sentenceValue :stepValue];
    
    //add SAIC to UserAction parent
    [nodeUserAction addChild:nodeSelection];
    [nodeUserAction addChild:nodeAction];
    [nodeUserAction addChild:nodeInput];
    [nodeUserAction addChild:nodeContext];
    
    //add userAction to story parent
    [study addChild: nodeUserAction];
    
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameString ofType:@"txt"];

}

-(DDXMLElement *) returnContext : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue
{
    
    //timestamp
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy'T'hh:mm.ss.SSS"];
    NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
    
    //logging Context
    DDXMLElement *nodeUsername = [DDXMLElement elementWithName:@"Username" stringValue:userNameString];
    DDXMLElement *nodeCondition = [DDXMLElement elementWithName:@"Condition" stringValue:studyConditionString];
    DDXMLElement *nodeExperimenter = [DDXMLElement elementWithName:@"Experimenter" stringValue:studyExperimenterString];
    DDXMLElement *nodeContext = [DDXMLElement elementWithName:@"Context"];
    DDXMLElement *nodeStory = [DDXMLElement elementWithName:@"Story" stringValue:storyValue];
    DDXMLElement *nodeChapter = [DDXMLElement elementWithName:@"Chapter" stringValue:chapterValue];
    DDXMLElement *nodePage = [DDXMLElement elementWithName:@"Page" stringValue:pageValue];
    DDXMLElement *nodeSentence = [DDXMLElement elementWithName:@"Sentence" stringValue:sentenceValue];
    DDXMLElement *nodeStep = [DDXMLElement elementWithName:@"Step" stringValue:stepValue];
    DDXMLElement *nodeTimestamp = [DDXMLElement elementWithName:@"Timestamp" stringValue:timeStampValue];
    
    [nodeContext addChild:nodeUsername];
    [nodeContext addChild:nodeCondition];
    [nodeContext addChild:nodeExperimenter];
    [nodeContext addChild:nodeStory];
    [nodeContext addChild:nodeChapter];
    [nodeContext addChild:nodePage];
    [nodeContext addChild:nodeSentence];
    [nodeContext addChild:nodeStep];
    [nodeContext addChild:nodeTimestamp];
    
    return nodeContext;
}

- (void) logNavigation : (Student *) userDetails : (NSString *) buttonPressedValue :(NSString *) currentSentenceValue :(NSString *)curViewValue :(NSString *)nextViewValue :(NSString *) computerActionValue
{
    
    //timestamp
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
    NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    [study addChild:nodeUserAction];
    
    //adding child nodes to nodeUserAction
    DDXMLElement *nodeNavigation = [DDXMLElement elementWithName:@"Navigation"];
    [nodeUserAction addChild:nodeNavigation];
    
    //logging structure for user navigation
    DDXMLElement *nodeTimeStamp = [DDXMLElement elementWithName:@"timeStamp" stringValue:timeStampValue];
    DDXMLElement *nodeCurrentView = [DDXMLElement elementWithName:@"CurrentView" stringValue:curViewValue];
    DDXMLElement *nodeNextView = [DDXMLElement elementWithName:@"NextView" stringValue:nextViewValue];
    DDXMLElement *nodeCurrentSentence = [DDXMLElement elementWithName:@"CurrentSentence" stringValue:currentSentenceValue];
    DDXMLElement *nodeButtonPressed = [DDXMLElement elementWithName:@"ButtonPressed" stringValue:buttonPressedValue];
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    
    //adding child nodes to Navigation parent
    [nodeNavigation addChild:nodeTimeStamp];
    [nodeNavigation addChild:nodeCurrentView];
    [nodeNavigation addChild:nodeNextView];
    [nodeNavigation addChild:nodeCurrentSentence];
    [nodeNavigation addChild:nodeButtonPressed];
    [nodeNavigation addChild:nodeComputerAction];
    
    /*
    //setting values of children nodes
    [nodeTimeStamp setStringValue:[timeStamp timeStampValue]];  
    [nodeCurrentView setStringValue:[CurrentView curViewValue]];
    [nodeNextView setStringValue:[NextView nextViewValue]];
    [nodeCurrentSentence setStringValue:[CurrentSentence currentSentenceValue]];
    [nodeButtonPressed setStringValue:[ButtonPressed buttonPressedValue]];
    [nodeComputerAction setStringValue:[ComputerAction computerActionValue]];
     
     */
    if([computerActionValue isEqualToString:@"nextChapter"] || [computerActionValue isEqualToString:@"nextPage"] || [computerActionValue isEqualToString:@"tutorial"])
    {
        
    //bool successfulWrite = [[ServerCommunicationController sharedManager] writeToFile:userNameValue ofType:@"txt"];
        
        //do something if error
    }
}

- (void) logGesture: (NSString * )gestureTypeValue :(NSString *)computerActionValue
{
    //timestamp
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
    NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    [study addChild:nodeUserAction];
    
    //adding child nodes to nodeUserAction
    DDXMLElement *nodeGesture = [DDXMLElement elementWithName:@"Gesture"];
    [nodeUserAction addChild:nodeGesture];
    
    //logging structure for user gestures
    DDXMLElement *nodeTimeStamp = [DDXMLElement elementWithName:@"timeStamp" stringValue:timeStampValue];
    DDXMLElement *nodeGestureType = [DDXMLElement elementWithName:@"GestureType" stringValue:gestureTypeValue];
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    
    //adding child nodes to nodeGesture
    [nodeGesture addChild:nodeTimeStamp];
    [nodeGesture addChild:nodeGestureType];
    [nodeGesture addChild:nodeComputerAction];
    
    /*
    //setting values of children nodes
    [nodeTimeStamp setStringValue:[timeStamp timeStampValue]];  
    [nodeGestureType setStringValue:[GestureType gestureTypeValue]];
    [nodeComputerAction setStringValue:[ComputerAction computerActionValue]];
     */
}

-(void) logGrouping: (NSString *)objidUser : (NSString *)objidCollision : (NSString *) selectedOptionValue : (NSString *) computerActionValue
{
    //timestamp
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy hh-mm"];
    NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
    
    //logging structure for user actions
    DDXMLElement *nodeUserAction = [DDXMLElement elementWithName:@"userAction"];
    [study addChild:nodeUserAction];
    
    //adding child nodes to nodeUserAction
    DDXMLElement *nodeGrouping = [DDXMLElement elementWithName:@"Grouping"];
    [nodeUserAction addChild:nodeGrouping];
    
    //logging structure for user navigation
    DDXMLElement *nodeTimeStamp = [DDXMLElement elementWithName:@"timeStamp" stringValue:timeStampValue];
    DDXMLElement *nodeObjUser = [DDXMLElement elementWithName:@"objUser" stringValue:objidUser];
    DDXMLElement *nodeObjCollision = [DDXMLElement elementWithName:@"objCollision" stringValue:objidCollision];
    DDXMLElement *nodeSelectedGrouping = [DDXMLElement elementWithName:@"selectedGrouping" stringValue:selectedOptionValue];
    DDXMLElement *nodeComputerAction = [DDXMLElement elementWithName:@"ComputerAction" stringValue:computerActionValue];
    
    //adding child nodes to Grouping parent
    [nodeGrouping addChild:nodeTimeStamp];
    [nodeGrouping addChild:nodeObjUser];
    [nodeGrouping addChild:nodeObjCollision];
    [nodeGrouping addChild:nodeSelectedGrouping];
    [nodeGrouping addChild:nodeComputerAction];
    
    /*
    //setting values of children nodes
    [nodeTimeStamp setStringValue:[timeStamp timeStampValue]];
    [nodeObjUser setStringValue:[objUser objidUser]];
    [nodeObjCollision setStringValue:[objCollision objidCollision]];
    [nodeSelectedGrouping setStringValue:[selectedGrouping selectedOptionValue]];
    [nodeComputerAction setStringValue:[ComputerAction computerActionValue]];
     */
}


- (BOOL) writeToFile:(NSString *)fileName ofType:(NSString *)type
{
    NSString *fullFileName = [NSString stringWithFormat:@"%@%@", fileName, type];
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fullFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
        [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
    
    //
    //NSData *xmlData = [xmlDocTemp XMLDataWithOptions:DDXMLNodePrettyPrint];
    NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodePrettyPrint];
    if (![stringxml writeToFile:fileAtPath atomically:YES]) {
        //NSBeep();
        NSLog(@"Could not write document out...");
        NSLog(@"%@", stringxml);
        return NO;
    }
    NSLog(@"%@", stringxml);
    NSLog(@"Successfully wrote to file");
    return YES;
}


@end