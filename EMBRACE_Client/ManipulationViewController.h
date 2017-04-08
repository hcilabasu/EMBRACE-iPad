//
//  ManipulationViewController.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/12/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EbookImporter.h"
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

@class PageController;
@class SentenceController;
@class SolutionStepController;
@class PossibleInteractionController;

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

@property (nonatomic, weak) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, weak) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, weak) IBOutlet UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, strong) id dataObject;
@property (nonatomic, weak) EBookImporter *bookImporter;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, weak) Book *book;
@property (nonatomic, strong) AVSpeechSynthesizer *syn;
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

@end
