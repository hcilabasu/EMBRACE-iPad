//
//  ServerCommunicationController.h
//  EMBRACE
//
//  Created by Rishabh on 12/13/13.
//  Copyright (c)2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "DDXMLNode.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"
#import "Student.h"
#import "Progress.h"

typedef enum LogAction {
    COMPUTER_ACTION,
    USER_ACTION
} LogAction;

@interface ServerCommunicationController : UIViewController

+ (id)sharedManager;

# pragma mark - General stuff

- (BOOL)writeLogFile;

# pragma mark - Logging for context

- (void)setContext:(Student *)student;

# pragma mark - Logging for actions

# pragma mark Computer Actions

- (void)logComputerMoveObject:(NSString *)movingObjectID :(NSString *)waypointID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerResetObject:(NSString *)objectID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerDisappearObject:(NSString *)interactionType :(NSString *)objectID :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerSwapImage:(NSString *)objectID :(NSString *)swapImageID :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerGroupObjects:(NSString *)interactionType :(NSString *)object1ID :(NSString *)object2ID :(NSString *)groupingLocation :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerVerification:(NSString *)actionType :(BOOL)verification :(NSString *)objectSelected :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerPlayAudio:(NSString *)computerAction :(NSString *)languageType :(NSString *)audioFileName :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logComputerDisplayMenuItems:(NSArray *)menuInteractions :(NSArray *)menuImages :(NSArray*)menuRelationships :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

#pragma mark User Actions

- (void)logUserMoveObject:(NSString *)moveType :(NSString *)movingObjectID :(NSString *)collisionObjectOrLocationID :(float)startPosX :(float)startPosY :(float)endPosX :(float)endPosY :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logUserSelectMenuItem:(int)selectedMenuItemID :(NSArray *)menuInteractions :(NSArray *)menuImages :(NSArray *)menuRelationships :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logUserTapWord:(NSString *)selectedWord :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logUserEmergencyNext:(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

#pragma mark - Logging for navigation

#pragma mark Computer Navigation

// TODO: It might make more sense to rename these functions to a general "logStepNavigation" rather than specifically "logNextStepNavigation"
- (void)logNextStepNavigation:(NSInteger)nextStepNumber :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextSentenceNavigation:(NSInteger)nextSentenceNumber :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextPageNavigation:(NSString *)nextPage :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;
- (void)logNextChapterNavigation:(NSString *)computerAction :(NSString *)nextChapter :(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

#pragma mark User Navigation

- (void)logUserTapNext:(NSString *)storyName :(NSString *)chapterFilePath :(NSString *)pageFilePath :(NSInteger)sentenceNumber :(NSString *)sentenceText :(NSInteger)stepNumber :(NSInteger)ideaNumber;

#pragma mark - Logging for assessment activities

#pragma mark Computer Actions

- (void)logComputerLoadNextAssessmentStep:(NSString *)computerAction :(NSString *)currAssessmentStep :(NSString *)nextAssessmentStep :(NSString *)storyName :(NSString *)chapterName;
- (void)logComputerAssessmentAnswerVerification:(BOOL)verification :(NSString *)answerSelected :(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep;
- (void)logComputerDisplayAssessment:(NSString *)questionText :(NSArray*)answerOptions :(NSString *)computerAction :(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep;

#pragma mark User Actions

- (void)logUserAssessmentTapNext:(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep;
- (void)logUserAssessmentTapAnswerOption:(NSString *)questionText :(NSArray*)answerOptions :(NSString *)selectedAnswer :(NSString *)storyName :(NSString *)chapterName :(NSString *)currentAssessmentStep;

#pragma mark - Saving/loading progress files

- (Progress *)loadProgress:(Student *)student;
- (void)saveProgress:(Student *)student :(Progress *)progress;

#pragma mark - Syncing log/progress files with Dropbox

- (void)uploadFilesForStudent:(Student *)student;
- (void)downloadProgressForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler;

@end
