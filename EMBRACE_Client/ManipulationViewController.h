//
//  ManipulationViewController.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/12/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EBookImporter.h"
#import "Book.h"
#import "AVFoundation/AVSpeechSynthesis.h"
#import "AssessmentActivityViewController.h"
#import "ManipulationContext.h"
#import "ManipulationView.h"
#import "PageContext.h"
#import "SentenceContext.h"
#import "StepContext.h"
#import "PossibleInteraction.h"
#import "ServerCommunicationController.h"
#import "ConditionSetup.h"
#import "ManipulationView.h"
#import "ResourceStrings.h"
#import "ManipulationContext.h"
#import "ForwardProgress.h"
#import "PageContext.h"
#import "SentenceContext.h"
#import "StepContext.h"
#import "ContextualMenuDataSource.h"
#import "ITSController.h"
#import "PieContextualMenu.h"
#import "HotSpotHandler.h"
@class PageController;
@class SentenceController;
@class SolutionStepController;
@class PossibleInteractionController;
@class HotSpotHandler;
typedef enum InteractionRestriction {
    ALL_ENTITIES, //Any object can be used
    ONLY_CORRECT, //Only the correct object can be used
    NO_ENTITIES //No object can be used
} InteractionRestriction;

//This enum will be used in the future to define if a condition has or not image manipulation
typedef enum InteractionMode {
    NO_INTERACTION,
    INTERACTION
} InteractionMode;

@interface ManipulationViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, PieContextualMenuDelegate> {
    
    
}


@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *tapRecognizer;


@property (nonatomic, weak) EBookImporter *bookImporter;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, weak) Book *book;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) PlayAudioFile *playaudioClass;
@property (nonatomic, weak) UIViewController *libraryViewController;
@property (nonatomic) BOOL allowInteractions; //TRUE if objects can be manipulated; FALSE otherwise
@property (nonatomic, strong) IBOutlet ManipulationView *manipulationView;
@property (nonatomic, strong) InteractionModel *model;
@property (nonatomic, strong) ConditionSetup *conditionSetup;
@property (nonatomic, strong) ManipulationContext *manipulationContext;
@property (nonatomic, strong) ForwardProgress *forwardProgress;
@property (nonatomic, strong) PageContext *pageContext;
@property (nonatomic, strong) SentenceContext *sentenceContext;
@property (nonatomic, strong) StepContext *stepContext;
@property (nonatomic, strong) NSMutableDictionary *animatingObjects;
@property (nonatomic) BOOL isLoadPageInProgress; //True if the system is currently trying to load the next page
@property (nonatomic, strong) PageController *pc;
@property (nonatomic, strong) SentenceController *sc;
@property (nonatomic, strong) SolutionStepController *ssc;
@property (nonatomic, strong) PossibleInteractionController *pic;
@property (nonatomic, strong) HotSpotHandler *hotSpotHandler;
@property (nonatomic) NSUInteger currentComplexity; //Complexity level of current sentence
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property(nonatomic) CGPoint startLocation; //initial location of an object before it is moved
@property (nonatomic, strong) NSMutableDictionary *pageStatistics;
@property (nonatomic, strong) Relationship *lastRelationship; //Stores the most recent relationship between objects used
@property (nonatomic, strong) NSMutableArray *allRelationships; //Stores an array of all relationships which is populated in getPossibleInteractions
@property (nonatomic, strong) NSMutableDictionary *currentGroupings;
@property (nonatomic, strong) ContextualMenuDataSource *menuDataSource;
@property (nonatomic, assign) EMComplexity currentComplexityLevel;
@property (nonatomic) BOOL isUserMovingBack;
@property (nonatomic, strong) UIImageView* toDoIcon;
@property (nonatomic, strong) UIImage* IMIcon;
@property (nonatomic, strong) UIImage* PMIcon;
@property (nonatomic, strong) UIImage* RDIcon;
@property (nonatomic, strong) UILabel* iconLabel;
@property (nonatomic, strong) UIButton* skipButton;
@property (nonatomic, weak) IBOutlet UIWebView *bookView;
@property UIAlertView* skipAlert;
@property BOOL isSkipOn;
@property BOOL isAudioPlaying;
@property  (nonatomic, strong) UIView* overlayView;
@property BOOL isUserInteractiondisabled;
@property BOOL shouldPlayInstructionAudio;
@property BOOL isSentenceDelayON;
@property NSString *movingObjectId; //Object currently being moved
@property NSString *collisionObjectId; //Object the moving object was moved to
@property NSString *separatingObjectId; //Object identified when pinch gesture performed
@property BOOL movingObject; //True if an object is currently being moved
@property BOOL panning;
@property BOOL pinching;
@property BOOL pinchToUngroup; //True if pinch gesture is used to ungroup

@property   PieContextualMenu *menu;
@property BOOL allowSnapback;//True if objects should snap back to original location upon error

@property InteractionRestriction useSubject; //Determines which objects the user can manipulate as the subject
@property InteractionRestriction useObject; //Determines which objects the user can interact with as the object
@property BOOL menuExpanded;
@property BOOL wasPathFollowed;
@property CGPoint endLocation; // ending location of an object after it is moved
@property CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.

- (void)loadFirstPage;
- (void)setManipulationContext;
- (UIImage *)getBackgroundImage;
- (void)performAutomaticSteps;
- (BOOL)isSubject:(NSString *)subject ContainedInGroupWithObject:(NSString *)object;
- (CGPoint) getHotspotLocationOnImage:(Hotspot*) hotspot;
-(CGPoint) getWaypointLocation:(Waypoint*) waypoint;
- (void)moveObject:(NSString *)object :(CGPoint)location :(CGPoint)offset :(BOOL)updateCon;
- (void)ungroupObjectsAndStay:(NSString *)object1 :(NSString *)object2;
- (void)ungroupObjects:(NSString *)object1 :(NSString *)object2;
- (void)groupObjects:(NSString *)object1 :(CGPoint)object1Hotspot :(NSString *)object2 :(CGPoint)object2Hotspot;
- (void)consumeAndReplenishSupply:(NSString *)disappearingObject;
- (MenuItemImage *)createMenuItemForImage:(NSString *)objId :(NSString *)FLIP;
- (void)simulateUngrouping:(NSString *)obj1 :(NSString *)obj2 :(NSMutableDictionary *)images :(float)GAP;
- (Hotspot *)findConnectedHotspot:(NSMutableArray *)movingObjectHotspots :(NSString *)objConnectedTo;
- (void)simulateGroupingMultipleObjects:(NSMutableArray *)objs :(NSMutableArray *)hotspots :(NSMutableDictionary *)images;
- (CGRect)getBoundingBoxOfImages:(NSMutableArray *)images;
- (PossibleInteraction *)convertActionStepToPossibleInteraction:(ActionStep *)step;
-(void)enableUserInteraction;
-(void)disableUserInteraction;
-(void)updateIcon;
-(void)hideIndicationIcon;
-(void)SkipIntro;
- (int)currentSentenceAudioIndex;
- (void)checkSolutionForInteraction:(PossibleInteraction *)interaction;
- (void) playIntroVocabWord: (NSString *) englishSentenceText : (ActionStep *) currSolStep;
- (void)playAudioForVocabWord:(NSString *)englishSentenceText :(NSString *)spanishExt;
- (NSString *)getObjectAtPoint:(CGPoint) location ofType:(NSString *)class;
- (void)swapObjectImage;
- (NSArray *)getObjectsGroupedWithObject:(NSString *)object;
- (void)populateMenuDataSource:(NSMutableArray *)possibleInteractions :(NSMutableArray *)relationships;
- (CGPoint)calculateDeltaForMovingObjectAtPointWithCenter:(NSString *)object :(CGPoint)location;
- (CGPoint)calculateDeltaForMovingObjectAtPoint:(CGPoint)location;
- (NSArray *)getObjectsOverlappingWithObject:(NSString *)object;
- (void)handleErrorForAction:(NSString *)action;
- (void)resetObjectLocation;
- (NSMutableArray *)getPossibleInteractions:(BOOL)useProximity;
- (NSMutableArray *)shuffleMenuOptions: (NSMutableArray *) interactions;
@end
