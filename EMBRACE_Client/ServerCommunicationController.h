//
//  ServerCommunicationController.h
//  EMBRACE
//
//  Created by Rishabh on 12/13/13.
//  Copyright (c)2013 Andreea Danielescu. All rights reserved.
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

@interface ServerCommunicationController : UIViewController

@property (nonatomic, strong) Student *student;
@property (nonatomic, strong) IBOutlet UIWebView *bookView;
@property (nonatomic, retain) NSNumber *movenum;
@property (nonatomic, retain) DDXMLElement *study;
@property (nonatomic, retain) DDXMLDocument *xmlDoc;
@property (nonatomic) NSInteger UserActionIDTag;
@property (nonatomic, strong) NSString *studyDayString;
@property (nonatomic, strong) NSString *userNameString;
@property (nonatomic, strong) NSString *studyConditionString;
@property (nonatomic, strong) NSString *studyExperimenterString;
@property (nonatomic, strong) NSString *studyParticipantString;
@property (nonatomic, strong) NSString *studySchoolString;
@property (nonatomic, strong) NSString *studyFileName;

+ (id)sharedManager;

/*
 * NOTE: These functions do not appear to be in use.
- (void)logUserName:(Student *)userdetails;
- (void)logMovements:(NSString *)objid :(float)posx :(float)posy;
- (void)resetMoveNumber;
 */

- (void)logContext:(Student *)userdetails;

/* 
 * Logging for computer actions
 */

- (void)logComputerMoveObject:(NSString *)movingObjectID :(NSString *)collisionObjectOrLocationID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)computerAction :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerResetObject:(NSString *)movingObjectID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)computerAction :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerSwapImages:(NSString *)objectID :(NSString *)swapImageID  :(NSString *)computerAction :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerDisappearObject:(NSString *)computerAction :(NSString *)objectID :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerGroupingObjects:(NSString *)computerActionValue :(NSString *)movingObjectID :(NSString *)collisionObjectID :(NSString *)groupAtLocation :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerVerification:(NSString *)action :(BOOL)verficationValue :(NSString *)objectSelected :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerPlayAudio:(NSString *)computerAction :(NSString *)LanguageType :(NSString *)audioFileName :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerDisplayMenuItems:(NSArray *)displayedMenuInteractions :(NSArray *)displayedMenuImages :(NSArray *)displayedMenuRelationships :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

/*
 * Logging for user actions
 */

- (void)logUserMoveObject:(NSString *)movingObjID :(NSString *)toLocationOrObject :(float)startposx :(float)startposy :(float)endposx :(float)endposy :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logMenuSelection:(int)selectedMenuItemID :(NSArray *)displayedMenuInteractions :(NSArray *)displayedMenuImages  :(NSArray *)menuRelationships :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logUserPressWord:(NSString *)selectedWordID :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logUserEmergencyNext:(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

/*
 * Logging for user navigation
 */
- (void)logUserNextButtonPressed:(NSString *)buttonPressedValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logStoryButtonPressed:(NSString *)buttonPressedValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

/*
 * Logging for computer navigation
 */
- (void)logNextStepNavigation:(NSString *)buttonPressedValue :(NSString *)curStepValue :(NSString *)nextStepValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextSentenceNavigation:(NSString *)buttonPressedValue :(NSString *)curSentenceValue :(NSString *)nextSentenceValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextPageNavigation:(NSString *)buttonPressedValue :(NSString *)curPageValue :(NSString *)nextPageValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextChapterNavigation:(NSString *)buttonPressedValue :(NSString *)curChapterValue :(NSString *)nextChapterValue :(NSString *)computerActionValue :(NSString *)storyName :(NSString *)chapterFilePath :(NSString*)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

/*
 * Logging for assessment activities
 */
- (void)logComputerAssessmentLoadNextActivityStep:(NSString *)buttonPressedValue :(NSString *)computerActionValue :(NSString *)currAssesmentActivityStepValue :(NSString *)nextAssessmentActivityStepValue :(NSString *)storyValue :(NSString *)chapterValue :(NSString *)currentAssessmentStep;
- (void)logUserAssessmentPressedNext:(NSString *)buttonPressedVaue :(NSString *)computerActionValue :(NSString *)storyValue :(NSString *)chapterValue :(NSString *)currentAssessmentStep;
- (void)logUserAssessmentPressedAnswerOption:(NSString *)questionText :(NSInteger)answerOptionSelected :(NSArray *)answerOptions :(NSString *)buttonPressedVaue :(NSString *)computerActionValue :(NSString *)storyValue :(NSString *)chapterValue :(NSString *)currentAssesssmentStep :(NSString *)answerText;
- (void)logComputerAssessmentAnswerVerification:(BOOL)verificationValue :(NSString *)questionText :(NSInteger)answerOptionSelected :(NSArray *)answerOptions :(NSString *)buttonPressedVaue :(NSString *)computerActionValue :(NSString *)storyValue :(NSString *)chapterValue :(NSString *)currentAssessmentStep :(NSString *)answerText;
- (void)logComputerAssessmentDisplayStep:(NSString *)questionText :(NSArray *)answerOptions :(NSString *)buttonPressedVaue :(NSString *)computerActionValue :(NSString *)storyValue :(NSString *)chapterValue :(NSString *)currentAssesmentStep;

/*
 * Write XML file locally
 */
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type;

- (Progress *)loadProgress:(Student *)student;
- (void)saveProgress:(Student *)student :(Progress *)progress;

@end