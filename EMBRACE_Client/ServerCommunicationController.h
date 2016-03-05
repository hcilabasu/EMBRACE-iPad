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
#import "ManipulationContext.h"
#import "AssessmentContext.h"

@interface ServerCommunicationController : UIViewController

//+ (id)sharedManager;
+ (ServerCommunicationController *)sharedInstance;
+ (void)resetSharedInstance;

# pragma mark - Logging

- (BOOL)writeLogFile;

# pragma mark - Logging (Context)

- (void)setStudyContext:(Student *)student;

# pragma mark - Logging (General)

- (void)logPressLoginOrLogout:(NSString *)buttonType atTime:(NSString *)timestamp;
- (void)logPressBooksAtTime:(NSString *)timestamp;
- (void)logPressLibraryAtTime:(NSString *)timestamp;
- (void)logUnlockBook:(NSString *)bookTitle atTime:(NSString *)timestamp;
- (void)logUnlockChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle atTime:(NSString *)timestamp;
- (void)logLoadBook:(NSString *)bookTitle atTime:(NSString *)timestamp;
- (void)logLoadChapter:(NSString *)chapterTitle inBook:(NSString *)bookTitle atTime:(NSString *)timestamp;

# pragma mark - Logging (Manipulation)

- (void)logMoveObject:(NSString *)object toDestination:(NSString *)destination ofType:(NSString *)destinationType startPos:(CGPoint)start endPos:(CGPoint)end performedBy:(Actor)actor context:(ManipulationContext *)context;
- (void)logComputerGroupOrUngroupObjects:(NSString *)object1 object2:(NSString *)object2 ofType:(NSString *)interactionType hotspot:(NSString *)hotspot :(ManipulationContext *)context;
- (void)logDisplayMenuWithInteractions:(NSArray *)interactions objects:(NSArray *)objects relationships:(NSArray*)relationships context:(ManipulationContext *)context;
- (void)logSelectMenuItemAtIndex:(int)index interactions:(NSArray *)interactions objects:(NSArray *)objects relationships:(NSArray *)relationships context:(ManipulationContext *)context;
- (void)logVerification:(BOOL)verification forAction:(NSString *)action context:(ManipulationContext *)context;
- (void)logResetObject:(NSString *)object startPos:(CGPoint)start endPos:(CGPoint)end context:(ManipulationContext *)context;
- (void)logAppearOrDisappearObject:(NSString *)object ofType:(NSString *)objectType context:(ManipulationContext *)context;
- (void)logSwapImageForObject:(NSString *)object altImage:(NSString *)image context:(ManipulationContext *)context;
- (void)logTapWord:(NSString *)word :(ManipulationContext *)context;
- (void)logPlayManipulationAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(ManipulationContext *)context;

# pragma mark Navigation

- (void)logPressNextInManipulationActivity:(ManipulationContext *)context;
- (void)logEmergencySwipe:(ManipulationContext *)context;
- (void)logLoadStep:(NSInteger)stepNumber ofType:(NSString *)stepType context:(ManipulationContext *)context;
- (void)logLoadSentence:(NSInteger)sentenceNumber withText:(NSString *)sentenceText context:(ManipulationContext *)context;
- (void)logLoadPage:(NSString *)page context:(ManipulationContext *)context;

# pragma mark - Logging (Assessment)

- (void)logDisplayAssessmentQuestion:(NSString *)questionText withOptions:(NSArray*)answerOptions context:(AssessmentContext *)context;
- (void)logSelectAssessmentAnswer:(NSString *)selectedAnswer context:(AssessmentContext *)context;
- (void)logVerification:(BOOL)verification forAssessmentAnswer:(NSString *)answer context:(AssessmentContext *)context;
- (void)logPlayAssessmentAudio:(NSString *)audioName inLanguage:(NSString *)language ofType:(NSString *)audioType :(AssessmentContext *)context;

# pragma mark Navigation

- (void)logTapAssessmentAudioButton:(NSString *)buttonName buttonType:(NSString *)type context:(AssessmentContext *)context;
- (void)logPressNextInAssessmentActivity:(AssessmentContext *)context;
- (void)logLoadAssessmentStep:(NSString *)assessmentStep ofType:(NSString *)assessemntStepType context:(AssessmentContext *)context;

#pragma mark - Saving/loading progress files

- (Progress *)loadProgress:(Student *)student;
- (void)saveProgress:(Student *)student :(Progress *)progress;

#pragma mark - Syncing log/progress files with Dropbox

- (void)uploadFilesForStudent:(Student *)student;
- (void)downloadProgressForStudent:(Student *)student completionHandler:(void (^)(BOOL success))completionHandler;

@end
