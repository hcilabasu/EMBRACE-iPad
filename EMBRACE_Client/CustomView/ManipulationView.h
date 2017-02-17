//
//  PMView.h
//  EMBRACE
//
//  Created by Jithin on 7/6/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activity.h"
#import "ConditionSetup.h"

@class InteractionModel, Book, MenuItemImage, Hotspot, Waypoint;

@protocol ManipulationViewDelegate;

@interface ManipulationView : UIView

@property (nonatomic, weak) id <ManipulationViewDelegate> delegate;
@property (nonatomic, strong) UIWebView *bookView;

//- (void)addGesture:(UIGestureRecognizer *)recogniser;

- (instancetype)initWithFrameAndView:(CGRect)frame : (UIWebView *) bv;

- (void)loadJsFiles;

- (void)loadPageFor:(Book *)book andCurrentPage:(NSString *)page;

- (NSInteger)totalSentences;

- (NSInteger)getIdForSentence:(NSInteger)sentenceNumber;

- (NSString *)getCurrentSentenceAt:(NSInteger)sentenceNumber;

- (NSString *)getVocabAtId:(NSInteger)idNum;

- (void)removePMInstructions:(NSInteger)totalSentences;

- (BOOL)isActionSentence:(NSInteger)sentenceNumber;

- (BOOL)isObjectCenter:(NSString *)objectId;

- (NSString *)getElementAtLocation:(CGPoint)location;

- (NSString *)getClassForElemAtLocation:(CGPoint)location;

- (NSString *)getTextAtLocation:(CGPoint)location;

- (NSString *)getSpanishExtention:(CGPoint)location;

- (UIImage *)getBackgroundImage;

- (void)hideCanvas;

- (void)showCanvas;

- (NSString *)findContainedObject:(NSArray *)objects;

- (BOOL)isObjectGrouped:(NSString *)objectId atHotSpot:(CGPoint)location;

- (NSString *)groupedObject:(NSString *)objectId atHotSpot:(CGPoint)location;

- (void)removeObject:(NSString *)objectId;

- (CGSize)sizeOfObject:(NSString *)objectId;

- (NSArray *)getObjectsGroupedWithObject:(NSString *)object;

- (NSArray *)getObjectsOverlappingWithObject:(NSString *)object movingObject:(NSString *)movingObjectId;

- (NSString *)getSentenceClass:(NSInteger)sentenceNumber;

#pragma mark - 

- (CGPoint)getObjectPosition:(NSString *)object;

- (CGPoint)deltaForMovingObjectAtPoint:(CGPoint)location;

- (CGPoint)deltaForMovingObjectAtPointWithCenter:(NSString *)object :(CGPoint)location;

- (CGPoint)getHotspotLocation:(Hotspot *)hotspot;

- (CGPoint)getHotspotLocationOnImage:(Hotspot *)hotspot;

- (CGPoint)getWaypointLocation:(Waypoint *)waypoint;

#pragma mark - 

- (void)drawArea:(NSString *)areaName
         chapter:(NSString *)chapter
          pageId:(NSString *)pageId
       withModel:(InteractionModel *)model;

- (void)highlightSentenceToBlack:(NSInteger)sentenceNumber;

- (void)highLightObject:(NSString *)objectId;

- (void)setupCurrentSentenceColor:(NSInteger)currentSentence
                        condition:(Condition)condition
                          andMode:(Mode)mode;

- (void)clearAllHighLighting;

- (void)buildPath:(NSString *)areaId
           pageId:(NSString *)pageId
        withModel:(InteractionModel *)model;

- (NSString *)imageMarginLeft:(NSString *)imageId;

- (NSString *)imageMarginTop:(NSString *)imageId;

- (MenuItemImage *)createMenuItemForImage:(NSString *)objId
                                     flip:(NSString *)flip;

- (void)drawHotspots:(NSMutableArray *)hotspots color:(NSString *)color;

- (void)colorSentencesUponNext:(NSInteger)currentSentence
                     condition:(Condition)condition
                       andMode:(Mode)mode;

- (void)highLightArea:(NSString *)objectId;

- (void)highlightObjectOnWordTap:(NSString *)objectId;

#pragma mark - Animations

- (void)animateObject:(NSString *)objectId
                 from:(CGPoint)fromPos
                   to:(CGPoint)toPos
               action:(NSString *)action
               areaId:(NSString *)areaId;

- (void)simulateUngrouping:(NSString *)obj1
                   object2:(NSString *)obj2
                    images:(NSMutableDictionary *)images
                       gap:(float)gap;

- (void)swapImages:(NSString *)imageId
      alternateSrc:(NSString *)altSrc
             width:(NSString *)width
            height:(NSString *)height
          location:(CGPoint)location
            zIndex:(NSString *)zIndex;

- (void)loadImage:(NSString *)object1Id
     alternateSrc:(NSString *)altSrc
            width:(NSString *)width
           height:(NSString *)height
         location:(CGPoint)location
        className:(NSString *)className
           zIndex:(NSString *)zPosition;

- (CGPoint)moveObject:(NSString *)object
             location:(CGPoint)location
               offset:(CGPoint)offset
shouldUpdateConnection:(BOOL)updateCon
            withModel:(InteractionModel *)model
         movingObject:(NSString *)movingObjectId
        startLocation:(CGPoint)startLocation
            shouldPan:(BOOL)isPanning;

- (void)updateConnection:(NSString *)object
                  deltaX:(float)deltaX
                  deltaY:(float)deltaY;

- (void)groupObjects:(NSString *)object1
      object1HotSpot:(CGPoint)object1Hotspot
             object2:(NSString *)object2
      object2Hotspot:(CGPoint)object2Hotspot;

- (void)ungroupObjects:(NSString *)object1
               object2:(NSString *)object2;

- (void)ungroupObjectsAndStay:(NSString *)object1
                      object2:(NSString *)object2;

- (CGPoint)consumeAndReplenishSupply:(NSString *)disappearingObject
                  shouldReplenish:(BOOL)replenishSupply
                            model:(InteractionModel *)model
                     movingObject:(NSString *)movingObjectId
                    startLocation:(CGPoint)startLocation
                        shouldPan:(BOOL)isPanning;

- (void)removeAllAudibleTags;


@end

@protocol ManipulationViewDelegate <NSObject>

- (void)manipulationViewDidLoad:(ManipulationView *)view;

@end
