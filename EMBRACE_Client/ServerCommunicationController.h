//
//  ServerCommunicationController.h
//  EMBRACE
//
//  Created by Rishabh on 12/13/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EbookImporter.h"
#import "Book.h"
#import "Student.h"
#import "LibraryViewController.h"
#import "DDXML.h"
#import "DDXMLNode.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"

@interface ServerCommunicationController : UIViewController{
    Student *student;
    NSNumber *movenum;
    DDXMLElement *study;
    DDXMLDocument *xmlDoc;
}
@property (nonatomic, strong) Student* student;
@property (nonatomic, strong) IBOutlet UIWebView *bookView;
@property (nonatomic, retain) NSNumber* movenum;
@property (nonatomic, retain) DDXMLElement *study;
@property (nonatomic, retain) DDXMLDocument *xmlDoc;
@property (nonatomic) NSInteger UserActionIDTag;
@property (nonatomic, strong) NSString *userNameString;
@property(nonatomic, strong) NSString *studyConditionString;
@property (nonatomic, strong) NSString *studyExperimenterString;

+ (id)sharedManager;
- (void) logUserName : (Student *) userdetails;
- (void) logMovements : (NSString *)objid :(float) posx :(float) posy;
- (void) resetMovenum;

//logging study context
//add logging should be included for each log action, maybe use this funciton to set global properties and just draw from those for each function????
-(void) logContext : (Student *) userdetails : (NSString *) studyCondition : (NSString *) studyExperimenter;

//Logging Computer Actions
//logging object manipulation

//computer action -> recording why an action occured
//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerMoveObject : (NSString *) movingObjectID : (NSString *) collisionObjectID : (float) startPosX : (float) startPosY : (float) endPosX : (float) endPosY : (NSString *) hotspot : (NSString *) computerAction : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerResetObject : (NSString *) movingObjectID : (float) startPosX : (float) startPosY : (float) endPosX : (float) endPosY : (NSString *) storyValue : (NSString *) computerAction :(NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//
-(void) logComputerSwapImages : (NSString *) objectID : (NSString *) swapImageID  : (NSString *) computerAction : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue :(NSString *) sentenceValue : (NSString *) stepValue;

//which object(s),context, userActionIDTag, why?
-(void) logComputerDisappearObject : (NSString *) objectID : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//which object(s), start, end location, which hotspots,context, userActionIDTag, why?
-(void) logComputerGroupingObjects : (NSString *) movingObjectID : (NSString *) collisionObjectID :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//logging none object manipulation actions

//logging object verificiation: correct | incorrect
-(void) logComputerVerification: (BOOL) verficationValue : (NSString *) objectSelected : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//logging audio: incorrect | introduction
-(void) logComputerPlayAudio: (NSString *) movingObjectID : (NSString *) audioValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//logging displayMenuItems
-(void) logComputerDisplayMenuItems : (NSString *) selectedMenuItemID : (NSArray *) displayedMenuInteractions :(NSArray *)displayedMenuImages : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;


//Logging User Actions
//logging move object
- (void) logUserMoveObject : (NSString *)movingObjID : (float) startposx :(float) startposy :(float) endposx :(float) endposy : (NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;
//maybe add drilled down moveObject
//moveobject no collision
//move object hotspot collision
//move object object collision
//computer action handles correctness

//may no long be relevant because it is a computer action that occurs,
//logging groupings
-(void) logGrouping: (NSString *)movingObjID : (NSString *) collisionObjID : (NSArray *) groupedObjects : (NSString *) computerActionValue : (NSString *) storyValue : (NSString *) pageValue : (NSString *) chapterValue : (NSString *) sentenceValue : (NSString *) stepValue;

//logging menu selection
- (void) logMenuSelection : (NSString *) selectedMenuItemID : (NSArray *) displayedMenuInteractions :(NSArray *)displayedMenuImages :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) pageValue : (NSString *) chapterValue : (NSString *) sentenceValue : (NSString *) stepValue;

//logging ??

//logging navigation
//add logging should be called in NextButtonPressed
-(void) logUserNextButtonPressed: (NSString *) buttonPressedValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//add logging should be called in load first page
-(void) logStoryButtonPressed: (NSString *) buttonPressedValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//log computerNavigation
//add logging should be called in nextButtonPressed, loadNextPage
- (void) logNextStepNavigation : (NSString *) buttonPressedValue :(NSString *)curStepValue :(NSString *)nextStepValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;
- (void) logNextSentenceNavigation : (NSString *) buttonPressedValue :(NSString *) curSentenceValue :(NSString *)nextSentenceValue :(NSString *) computerActionValue : (NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;
- (void) logNextPageNavigation : (NSString *) buttonPressedValue :(NSString *) curPageValue : (NSString *) nextPageValue :(NSString *) computerActionValue :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;
- (void) logNextChapterNavigation : (NSString *) buttonPressedValue :(NSString *) curChapterValue :(NSString *) nextChapterValue :(NSString *) computerActionValue :(NSString *) storyValue : (NSString *) chapterValue : (NSString *) pageValue : (NSString *) sentenceValue : (NSString *) stepValue;

//add logging emergency next
//should be the same as logging navigation but some place should specify if it was user next, or experimenter emergency next

//place holder for logging gesture 
- (void) logGesture: (NSString * )gestureTypeValue :(NSString *)computerActionValue;

//write xml file locally
- (BOOL) writeToFile: (NSString *)fileName ofType:(NSString *)type;

/***************************************************************************/
/*                          out dated functions                            */
/***************************************************************************/

//for temp reference remove later
- (void) logNavigation : (Student *) userDetails : (NSString *) buttonPressedValue :(NSString *) currentSentenceValue :(NSString *)curViewValue :(NSString *)nextViewValue :(NSString *) computerActionValue;
@end





