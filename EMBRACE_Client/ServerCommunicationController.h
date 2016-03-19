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
#import "ConditionSetup.h"
#import "Student.h"
#import "Progress.h"
#import "StudyContext.h"
#import "ManipulationContext.h"
#import "AssessmentContext.h"

@interface ServerCommunicationController : UIViewController

@property (nonatomic, strong) StudyContext *studyContext;

# pragma mark - Shared Instance

+ (ServerCommunicationController *)sharedInstance;
+ (void)resetSharedInstance;

# pragma mark - Logging

- (BOOL)writeLogFile;

# pragma mark - Logging (Context)

- (void)setupStudyContext:(Student *)student;

# pragma mark - Logging (Library)

- (void)logPressLogin;
- (void)logPressLogout;
- (void)logPressBooks;
- (void)logUnlockBook:(NSString *)bookTitle withStatus:(NSString *)bookStatus;
- (void)logUnlockChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle withStatus:(NSString *)chapterStatus;
- (void)logLoadBook:(NSString *)bookTitle;
- (void)logLoadChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle;

# pragma mark - Logging (Manipulation)

- (void)logMoveObject:(NSString *)object toDestination:(NSString *)destination ofType:(NSString *)destinationType startPos:(CGPoint)start endPos:(CGPoint)end performedBy:(Actor)actor context:(ManipulationContext *)context;
- (void)logGroupOrUngroupObjects:(NSString *)object1 object2:(NSString *)object2 ofType:(NSString *)interactionType hotspot:(NSString *)hotspot :(ManipulationContext *)context;
- (void)logDisplayMenuItems:(NSArray *)menuItemsData context:(ManipulationContext *)context;
- (void)logSelectMenuItem:(NSArray *)menuItemData atIndex:(int)index context:(ManipulationContext *)context;
- (void)logVerification:(BOOL)verification forAction:(NSString *)action context:(ManipulationContext *)context;
- (void)logResetObject:(NSString *)object startPos:(CGPoint)start endPos:(CGPoint)end context:(ManipulationContext *)context;
- (void)logAppearOrDisappearObject:(NSString *)object ofType:(NSString *)objectType context:(ManipulationContext *)context;
- (void)logSwapImageForObject:(NSString *)object altImage:(NSString *)image context:(ManipulationContext *)context;
- (void)logAnimateObject:(NSString *)object forAction:(NSString *)animateAction context:(ManipulationContext *)context;
- (void)logTapObject:(NSString *)object :(ManipulationContext *)context;
- (void)logTapWord:(NSString *)word :(ManipulationContext *)context;
- (void)logPlayManipulationAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(ManipulationContext *)context;

# pragma mark Navigation

- (void)logPressNextInManipulationActivity:(ManipulationContext *)context;
- (void)logEmergencySwipe:(ManipulationContext *)context;
- (void)logLoadStep:(NSInteger)stepNumber ofType:(NSString *)stepType context:(ManipulationContext *)context;
- (void)logLoadSentence:(NSInteger)sentenceNumber withText:(NSString *)sentenceText manipulationSentence:(BOOL)manipulationSentence context:(ManipulationContext *)context;
- (void)logLoadPage:(NSString *)pageLanguage mode:(NSString *)pageMode number:(NSInteger)pageNumber context:(ManipulationContext *)context;
- (void)logPressLibrary:(ManipulationContext *)context;
- (void)logCompleteManipulation:(ManipulationContext *)context;

# pragma mark - Logging (Assessment)

- (void)logDisplayAssessmentQuestion:(NSString *)questionText withOptions:(NSArray *)answerOptions context:(AssessmentContext *)context;
- (void)logSelectAssessmentAnswer:(NSString *)selectedAnswer context:(AssessmentContext *)context;
- (void)logVerification:(BOOL)verification forAssessmentAnswer:(NSString *)answer context:(AssessmentContext *)context;
- (void)logPlayAssessmentAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(AssessmentContext *)context;
- (void)logAssessmentEmergencySwipe:(AssessmentContext *)context;

# pragma mark Navigation

- (void)logTapAssessmentAudioButton:(NSString *)buttonName buttonType:(NSString *)type context:(AssessmentContext *)context;
- (void)logPressNextInAssessmentActivity:(AssessmentContext *)context;
- (void)logLoadAssessmentStep:(NSInteger)assessmentStepNumber context:(AssessmentContext *)context;
- (void)logCompleteAssessment:(AssessmentContext *)context;

#pragma mark - Saving/loading progress files

- (Progress *)loadProgress:(Student *)student;
- (void)saveProgress:(Student *)student :(Progress *)progress;

#pragma mark - Syncing log/progress files with Dropbox

- (void)uploadFilesForStudent:(Student *)student;
- (void)downloadProgressForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler;

@end
