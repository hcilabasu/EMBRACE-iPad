//
//  InteractionModel.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotspot.h"
#import "Constraint.h"
#import "MovementConstraint.h"
#import "OrderConstraint.h"
#import "ComboConstraint.h"
#import "Location.h"
#import "Waypoint.h"
#import "AlternateImage.h"
#import "Relationship.h"
#import "Introduction.h"
#import "IntroductionStep.h"
#import "VocabularyStep.h"
#import "AssessmentActivity.h"
#import "Area.h"

@interface InteractionModel : NSObject {
    NSMutableSet* relationships;
    NSMutableSet* constraints;
    NSMutableDictionary* hotspots;
    NSMutableSet* locations;
    NSMutableSet* waypoints;
    NSMutableSet* alternateImages;
    NSMutableSet* sentenceMetadata;
    NSMutableDictionary* introductions;
    NSMutableDictionary* vocabularies;
    NSMutableDictionary *assessmentActivities;
    
    BOOL useRelationships;
    BOOL useConstraints;
    
    NSMutableSet* areas;
}

@property (nonatomic, strong) NSMutableDictionary *assessmentActivities;
@property (nonatomic, strong) NSMutableSet* relationships;
@property (nonatomic, strong) NSMutableSet* constraints;
@property (nonatomic, strong) NSMutableDictionary* hotspots;
@property (nonatomic, strong) NSMutableSet* locations;
@property (nonatomic, strong) NSMutableSet* waypoints;
@property (nonatomic, strong) NSMutableSet* alternateImages;
@property (nonatomic, strong) NSMutableSet* sentenceMetadata;
@property (nonatomic, strong) NSMutableDictionary* introductions;
@property (nonatomic, strong) NSMutableDictionary* vocabularies;
@property (nonatomic, strong) NSMutableSet* areas;

- (NSMutableDictionary*) getAssessmentActivity;
- (void) addAssessmentActivity:(NSString*) storyTitle :(NSMutableArray*) questions;

- (void) addHotspot:(NSString*)objId :(NSString*)act :(NSString*)objRole :(CGPoint)loc; //add hotspot to object with objectId at location loc.

- (void) addRelationship:(NSString*) obj1Id :(NSString*) can :(NSString*)type :(NSString*) obj2Id; //add relationship "can" between obj1 and obj2 of the specified type.

- (void) addMovementConstraint:(NSString*) objectId :(NSString*) action :(NSString*) originX :(NSString*) originY :(NSString*) height :(NSString*)width;
- (void) addOrderConstraint:(NSString*)action1 :(NSString*) action2 :(NSString*) ruleType;
- (void) addComboConstraint:(NSString*)objectId :(NSMutableArray*)comboActs;

- (void) addLocation:(NSString*)locationId :(NSString*)originX :(NSString*)originY :(NSString*)height :(NSString*)width;

- (void) addWaypoint:(NSString*)wayptId :(CGPoint)loc;

- (void) addAlternateImage:(NSString*)objId :(NSString*)act :(NSString*)origSrc :(NSString*)altSrc :(NSString*)wdth :(NSString*)height : (CGPoint)loc : (NSString*)cls :(NSString*)zpos;

- (NSMutableArray*) getAllHotspots; //Return all hotspots for all objects.
- (NSMutableArray*) getHotspotsForObjectId:(NSString* )objId; //Return all hotspots for object with objId.
- (NSMutableArray*) getHotspotsForObject:(NSString*) obj1 OverlappingWithObject:(NSString*) obj2;
- (Hotspot*) getHotspotforObjectWithActionAndRole:(NSString*)obj :(NSString*)action :(NSString*)role; //Returns the hotspot for the specified object relevant to the specified action and role. The assumption is that the combination of those three is unique.

- (NSMutableArray*) getRelationshipsForObjects:(NSString*)obj1Id :(NSString*)obj2Id; //Returns all relationships between two objects.
- (Relationship*) getRelationshipForObjectsForAction:(NSString*)obj1Id :(NSString*)obj2Id :(NSString*)action; //Returns the relationship between two objects taking into account the action that we're interested in.
- (NSMutableArray*) getRelationshipForObjectForAction:(NSString*) obj1Id :(NSString*)action; //Returns a list of the relationships between the specified object and all other objects with the given action.

- (NSMutableArray*) getMovementConstraintsForObjectId:(NSString*)objId;
- (NSMutableArray*) getComboConstraintsForObjectId:(NSString*)objId;

- (Location*) getLocationWithId:(NSString*)locId;

- (Waypoint*) getWaypointWithId:(NSString*)wayptId;

- (AlternateImage*) getAlternateImageWithAction:(NSString*)action;
- (AlternateImage*) getAlternateImageWithActionAndObjectID:(NSString *)action : (NSString *) objectId;

- (void) addIntroduction:(NSString*) storyTitle :(NSMutableArray*) introductionSteps;

- (NSMutableDictionary*) getIntroductions;

- (void) addVocabulary:(NSString*) storyTitle :(NSMutableArray*) words;

- (NSMutableDictionary*) getVocabularies;

- (void) addArea:(NSString*)areaId :(UIBezierPath *)path :(NSMutableDictionary*)points :(NSString*)pageId ;
- (Area*) getAreaWithId:(NSString*)aId;
- (Area*) getAreaWithPageId:(NSString*)pId;
- (Area*) getArea: (NSString*)aId : (NSString*)pId;

- (NSString *)getObjectIdAtLocation:(CGPoint)loc;

@end
