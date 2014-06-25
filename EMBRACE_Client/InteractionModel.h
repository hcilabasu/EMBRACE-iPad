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
#import "Location.h"
#import "Waypoint.h"
#import "Relationship.h"

@interface InteractionModel : NSObject {
    NSMutableSet* relationships;
    NSMutableSet* constraints;
    //NSMutableSet* hotspots;
    NSMutableDictionary* hotspots;
    NSMutableSet* locations;
    NSMutableSet* waypoints;
    NSMutableSet* sentenceMetadata;
    
    BOOL useRelationships;
    BOOL useConstraints;
}

@property (nonatomic, strong) NSMutableSet* relationships;
@property (nonatomic, strong) NSMutableSet* constraints;
@property (nonatomic, strong) NSMutableDictionary* hotspots;
@property (nonatomic, strong) NSMutableSet* locations;
@property (nonatomic, strong) NSMutableSet* waypoints;
@property (nonatomic, strong) NSMutableSet* sentenceMetadata;

- (void) addHotspot:(NSString*)objId :(NSString*)act :(NSString*)objRole :(CGPoint)loc; //add hotspot to object with objectId at location loc.
- (void) addRelationship:(NSString*) obj1Id :(NSString*) can :(NSString*)type :(NSString*) obj2Id; //add relationship "can" between obj1 and obj2 of the specified type.
//- (void) addConstraint:(NSString*) action1 :(NSString*) action2 :(NSString*) ruleType; //add constraint with ruleType between action1 and action2.

-(void) addMovementConstraint:(NSString*) objectId :(NSString*) action :(NSString*) originX :(NSString*) originY :(NSString*) height :(NSString*)width;
-(void) addOrderConstraint:(NSString*)action1 :(NSString*) action2 :(NSString*) ruleType;

-(void) addLocation:(NSString*)locationId :(NSString*)originX :(NSString*)originY :(NSString*)height :(NSString*)width;

-(void) addWaypoint:(NSString*)wayptId :(CGPoint)loc;

- (NSMutableArray*) getAllHotspots; //Return all hotspots for all objects.
- (NSMutableArray*) getHotspotsForObjectId:(NSString* )objId; //Return all hotspots for object with objId.
//-(NSMutableArray*) getHotspotsForObjectOverlappingWithObject:(NSString*) obj1 :(NSString*) obj2;
-(NSMutableArray*) getHotspotsForObject:(NSString*) obj1 OverlappingWithObject:(NSString*) obj2;
-(Hotspot*) getHotspotforObjectWithActionAndRole:(NSString*)obj :(NSString*)action :(NSString*)role; //Returns the hotspot for the specified object relevant to the specified action and role. The assumption is that the combination of those three is unique.

- (NSMutableArray*) getRelationshipsForObjects:(NSString*)obj1Id :(NSString*)obj2Id; //Returns all relationships between two objects.
- (Relationship*) getRelationshipForObjectsForAction:(NSString*)obj1Id :(NSString*)obj2Id :(NSString*)action; //Returns the relationship between two objects taking into account the action that we're interested in.
-(NSMutableArray*) getRelationshipForObjectForAction:(NSString*) obj1Id :(NSString*)action; //Returns a list of the relationships between the specified object and all other objects with the given action.

- (NSMutableArray*) getMovementConstraintsForObjectId:(NSString*)objId;

-(Location*) getLocationWithId:(NSString*)locId;

-(Waypoint*) getWaypointWithId:(NSString*)wayptId;

@end
