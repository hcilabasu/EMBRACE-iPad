//
//  InteractionModel.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "InteractionModel.h"

@implementation InteractionModel

@synthesize relationships;
@synthesize constraints;
@synthesize hotspots;
@synthesize sentenceMetadata;

- (id) init {
    if (self = [super init]) {
        relationships = [[NSMutableSet alloc] init];
        constraints = [[NSMutableSet alloc] init];
        hotspots = [[NSMutableDictionary alloc] init];
        sentenceMetadata = [[NSMutableSet alloc] init];
        useRelationships = TRUE;
        useConstraints = TRUE;
    }
    
    return self;
}

- (void) addRelationship:(NSString*) obj1Id :(NSString*) can :(NSString*)type :(NSString*) obj2Id {
    Relationship *relationship = [[Relationship alloc] initWithValues:obj1Id :can :type :obj2Id];
    [relationships addObject:relationship];
}

/* Return all relationships between two objects. 
 */
- (NSMutableArray*) getRelationshipsForObjects:(NSString*)obj1Id :(NSString*)obj2Id {
    NSMutableArray* relationshipsBetweenObjects = [[NSMutableArray alloc] init];
    
    for(Relationship *relation in relationships) {
        if(([[relation object1Id] isEqualToString:obj1Id] && [[relation object2Id] isEqualToString:obj2Id]) || ([[relation object1Id] isEqualToString:obj2Id] && [[relation object2Id] isEqualToString:obj1Id])) {
            [relationshipsBetweenObjects addObject:relation];
        }
    }
    
    return relationshipsBetweenObjects;
}

-(void) addMovementConstraint:(NSString*) objectId :(NSString*) action :(NSString*) originX :(NSString*) originY :(NSString*) width :(NSString*)height {
    
    Constraint *constraint = [[MovementConstraint alloc] initWithValues:objectId :action :originX :originY :width :height];
    [constraints addObject:constraint];
}

-(void) addOrderConstraint:(NSString*)action1 :(NSString*) action2 :(NSString*) ruleType {
    Constraint *constraint = [[OrderConstraint alloc] initWithValues:action1 :action2 :ruleType];
    [constraints addObject:constraint];    
}

- (NSMutableArray*) getMovementConstraintsForObjectId:(NSString*)objId {
    NSMutableArray* movementConstraintsForObject = [[NSMutableArray alloc] init];
    
    for(Constraint* constraint in constraints) {
        if([constraint class] == [MovementConstraint class]) {
            MovementConstraint *mConstraint = (MovementConstraint*)constraint;
            
            if([[mConstraint objId] isEqualToString:objId])
                [movementConstraintsForObject addObject:mConstraint];
        }
    }

    return movementConstraintsForObject;
}

/* Add a hotspot to the dictionary with object ID: objId, action act, object role, orjRole and
 * location loc.
 * The key for the hotspot is the objId. Since there may be multiple hotspots for each object, a 
 * mutableArray is used in the value spot of the NSDictionary to store the Hotspot objects for each
 * objectId.
 */
- (void) addHotspot:(NSString*) objId :(NSString*) act :(NSString*) objRole :(CGPoint) loc {
    //Hotspot *hotspot = [[Hotspot alloc] initWithValues:objId :loc];
    Hotspot *hotspot = [[Hotspot alloc] initWithValues:objId :act :objRole :loc];

    //Check to see if the key exists.
    //If it doesn't, we add the key with a new NSMutableArray that will contain the Hotspot created.
    NSMutableSet* hotspotsForKey = [hotspots objectForKey:objId];
    
    if(hotspotsForKey == nil) {
        hotspotsForKey = [[NSMutableSet alloc] init];
        [hotspotsForKey addObject:hotspot];
        [hotspots setObject:hotspotsForKey forKey:objId];
    }
    //if it does, we just add the hotspot to the array.
    else {
        [hotspotsForKey addObject:hotspot];
        //[hotspots addObject:hotspot];
    }
}

/* Return all saved hotspots in case we want to draw all the hotspots on the screen.
 */
- (NSMutableArray*) getAllHotspots {
    NSArray* hotspotsByObjId = [hotspots allValues];
    NSMutableArray* allHotspots = [[NSMutableArray alloc] init];
    
    for(NSMutableSet* set in hotspotsByObjId) {
        [allHotspots addObjectsFromArray:[set allObjects]];
    }
    
    return allHotspots;
}

/* Return all hotspots for a particular object. 
 */
- (NSMutableArray*) getHotspotsForObjectId:(NSString* )objId {
    return [[NSMutableArray alloc] initWithArray:[[hotspots objectForKey:objId] allObjects]];
}

//TODO: Re-name the parameters or the function name, or both to clarify that one of these is the object that I'm returning the hotspots for and the other is the object that is currently overlapping with it. obj2 is the object for which the hotspots are being generated. 
-(NSMutableArray*) getHotspotsForObjectOverlappingWithObject:(NSString*) obj1 :(NSString*) obj2 {
    NSMutableArray* hotspotsForObject = [self getHotspotsForObjectId:obj2];
    
    //If we want to constrain the hotspots shown by the possible relationships between two objects, then we need to filter hotspots based on those relationships. E.g. of a relationship would be: the farmer can pick up the hay.
    if(useRelationships) {
        //Get relationships for the two overlapping objects.
        NSMutableArray* relationshipForObjects = [self getRelationshipsForObjects:obj1 :obj2];
        NSMutableArray* relevantHotspots = [[NSMutableArray alloc] init];
        
        for(Relationship* relationship in relationshipForObjects) {
            
            //Use the relationships to reduce the hotspots available.
            for(Hotspot* hotspot in hotspotsForObject) {
                if([[relationship action] isEqualToString:[hotspot action]]) {
                    [relevantHotspots addObject:hotspot];
                }
            }
        }
        
        hotspotsForObject = relevantHotspots;
    }
    
    //Come back to this shortly. First fix the grouping objects part.
    if(useConstraints) {
        
    }
    
    return hotspotsForObject;
}

-(void) addSentenceMetadata {

}

@end
