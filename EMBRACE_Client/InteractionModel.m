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
@synthesize locations;
@synthesize waypoints;
@synthesize alternateImages;
@synthesize sentenceMetadata;
@synthesize introductions;
@synthesize vocabularies;
@synthesize assessmentActivities;
@synthesize areas;

- (id) init {
    if (self = [super init]) {
        relationships = [[NSMutableSet alloc] init];
        constraints = [[NSMutableSet alloc] init];
        hotspots = [[NSMutableDictionary alloc] init];
        locations = [[NSMutableSet alloc] init];
        waypoints = [[NSMutableSet alloc] init];
        alternateImages = [[NSMutableSet alloc] init];
        sentenceMetadata = [[NSMutableSet alloc] init];
        useRelationships = TRUE;
        useConstraints = TRUE;
        introductions = [[NSMutableDictionary alloc] init];
        vocabularies = [[NSMutableDictionary alloc] init];
        assessmentActivities = [[NSMutableDictionary alloc] init];
        areas = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void) addAssessmentActivity:(NSString*) storyTitle :(NSMutableArray*) questions {
    [assessmentActivities setObject:questions forKey:storyTitle];
}

- (NSMutableDictionary*) getAssessmentActivity{
    return assessmentActivities;
}

/*
 * Adds a relationship "can" between obj1 and obj2 of the specified type.
 */
- (void) addRelationship:(NSString*) obj1Id :(NSString*) can :(NSString*)type :(NSString*) obj2Id {
    Relationship *relationship = [[Relationship alloc] initWithValues:obj1Id :can :type :obj2Id];
    [relationships addObject:relationship];
}

/* 
 * Return all relationships between two objects.
 */
- (NSMutableArray*) getRelationshipsForObjects:(NSString*)obj1Id :(NSString*)obj2Id {
    NSMutableArray* relationshipsBetweenObjects = [[NSMutableArray alloc] init];
    
    for(Relationship *relation in relationships) {
        if(([[relation object1Id] isEqualToString:obj1Id] && [[relation object2Id] isEqualToString:obj2Id]) || ([[relation object1Id] isEqualToString:obj2Id] && [[relation object2Id] isEqualToString:obj1Id])) {
            //filter based on valid action types.
            if([actionTypes containsObject:[relation actionType]])
                [relationshipsBetweenObjects addObject:relation];
        }
    }
    
    return relationshipsBetweenObjects;
}

/*
 * Returns the relationship between two objects taking into account the action that we're interested in.
 */
- (Relationship*) getRelationshipForObjectsForAction:(NSString*)obj1Id :(NSString*)obj2Id :(NSString*)action {
    for(Relationship *relation in relationships) {
        
        if(([[relation object1Id] isEqualToString:obj1Id] && [[relation object2Id] isEqualToString:obj2Id]) || ([[relation object1Id] isEqualToString:obj2Id] && [[relation object2Id] isEqualToString:obj1Id])) {
 
            //Check to make sure the action is appropriate and filter based on valid action types.
            if(([[relation action] isEqualToString:action]) && ([actionTypes containsObject:[relation actionType]]))
                return relation;
        }
    }
    
    return nil;
}

/*
 * Returns a list of the relationships between the specified object and all other objects with the given action.
 */
- (NSMutableArray*) getRelationshipForObjectForAction:(NSString*) obj1Id :(NSString*)action {
    NSMutableArray* relationshipsBetweenObjects = [[NSMutableArray alloc] init];

    for(Relationship *relation in relationships) {
        if([[relation object1Id] isEqualToString:obj1Id] || [[relation object2Id] isEqualToString:obj1Id]) {
            //Check to make sure we have the correct action.
            if([[relation action] isEqualToString:action])
                [relationshipsBetweenObjects addObject:relation];
        }
    }
    
    return relationshipsBetweenObjects;
}

/*
 * Adds a MovementConstraint tied to the specific object id, action, xy coordinate of the top left corner of the bounding box 
 * (originX and originY), and height and width of the bounding box
 */
- (void) addMovementConstraint:(NSString*) objectId :(NSString*) action :(NSString*) originX :(NSString*) originY :(NSString*) width :(NSString*)height {
    
    Constraint *constraint = [[MovementConstraint alloc] initWithValues:objectId :action :originX :originY :width :height];
    [constraints addObject:constraint];
}

/*
 * Adds an OrderConstraint specifying a rule type between action1 and action2
 */
- (void) addOrderConstraint:(NSString*)action1 :(NSString*) action2 :(NSString*) ruleType {
    Constraint *constraint = [[OrderConstraint alloc] initWithValues:action1 :action2 :ruleType];
    [constraints addObject:constraint];    
}

/*
 * Adds a ComboConstraint tied to a specific object id with a list of actions/hotspots
 * that cannot be used simultaneously
 */
- (void) addComboConstraint:(NSString*)objectId :(NSMutableArray*)comboActs {
    Constraint *constraint = [[ComboConstraint alloc] initWithValues:objectId :comboActs];
    [constraints addObject:constraint];
}

/*
 * Returns the MovementConstraint tied to the specified object id
 */
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

/*
 * Returns the ComboConstraint tied to the specified object id
 */
- (NSMutableArray*) getComboConstraintsForObjectId:(NSString*)objId {
    NSMutableArray* comboConstraintsForObject = [[NSMutableArray alloc] init];
    
    for (Constraint* constraint in constraints) {
        if ([constraint class] == [ComboConstraint class]) {
            ComboConstraint *cConstraint = (ComboConstraint*)constraint;
            
            if ([[cConstraint objId] isEqualToString:objId])
                [comboConstraintsForObject addObject:cConstraint];
        }
    }
    
    return comboConstraintsForObject;
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

/* 
 * Return all saved hotspots in case we want to draw all the hotspots on the screen.
 */
- (NSMutableArray*) getAllHotspots {
    NSArray* hotspotsByObjId = [hotspots allValues];
    NSMutableArray* allHotspots = [[NSMutableArray alloc] init];
    
    for(NSMutableSet* set in hotspotsByObjId) {
        [allHotspots addObjectsFromArray:[set allObjects]];
    }
    
    return allHotspots;
}

/* 
 * Return all hotspots for a particular object.
 */
- (NSMutableArray*) getHotspotsForObjectId:(NSString* )objId {
    return [[NSMutableArray alloc] initWithArray:[[hotspots objectForKey:objId] allObjects]];
}

/*
 * Get the hotspots for obj1 that are overlapping with obj2. 
 * Filter the hotspots based on the relationships for the objects. 
 * Eventually we may want to also filter the hotspots based on the constraints.
 */
- (NSMutableArray*) getHotspotsForObject:(NSString*)obj1 OverlappingWithObject:(NSString*) obj2{
    NSMutableArray* hotspotsForObject = [self getHotspotsForObjectId:obj1];
    
    //If we want to constrain the hotspots shown by the possible relationships between two objects, then we need to filter hotspots based on those relationships. E.g. of a relationship would be: the farmer can pick up the hay.
    if(useRelationships) {
        //Get relationships for the two overlapping objects.
        NSMutableArray* relationshipForObjects = [self getRelationshipsForObjects:obj1 :obj2];        
        NSMutableArray* relevantHotspots = [[NSMutableArray alloc] init];
        
        for(Relationship* relationship in relationshipForObjects) {
            //Use the relationships to reduce the hotspots available.
            for(Hotspot* hotspot in hotspotsForObject) {
                //Need to make sure the relationship and the hotspot share the same verb. Also want to make sure that object1 of the relationship is the subject and object2 of the relationship is the object.
                if([[relationship action] isEqualToString:[hotspot action]]) {
                    //if the object of this hotspot is the subject, then it should be object 1 in the relationship. Otherwise, if the object of this hotspot is the object, it should be object 2 in the relationship.
                    if(([[hotspot role] isEqualToString:@"subject"] && [[relationship object1Id] isEqualToString:obj1])
                       || ([[hotspot role] isEqualToString:@"object"] && [[relationship object2Id] isEqualToString:obj1]))
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

/*
 * Returns the hotspot for the specified object relevant to the specified action and role. The assumption is that the 
 * combination of those three is unique.
 */
- (Hotspot*) getHotspotforObjectWithActionAndRole:(NSString*)obj :(NSString*)action :(NSString*)role {
    NSMutableArray* hotspotsForObject = [self getHotspotsForObjectId:obj];
    
    for(Hotspot* hotspot in hotspotsForObject) {
        if(([[hotspot action] isEqualToString:action]) && ([[hotspot role] isEqualToString:role]))
            return hotspot;
    }
    
    return nil;
}

- (void) addSentenceMetadata {

}

/*
 * Adds a Location with the specified id, xy coordinate of the top left corner of the bounding box (originX and originY),
 * and height and width of the bounding box
 */
- (void) addLocation:(NSString*)locationId :(NSString*)originX :(NSString*)originY :(NSString*)height :(NSString*)width {
    Location *location = [[Location alloc] initWithValues:locationId :originX :originY :height :width];
    [locations addObject:location];
}

/*
 * Returns the Location with the specified id
 */
- (Location*) getLocationWithId:(NSString*)locId {
    for (Location* location in locations) {
        if ([[location locationId] isEqualToString:locId]) {
            return location;
        }
    }
    
    return nil;
}

/*
 * Adds a Waypoint with the specific id and x-y coordinate
 */
- (void) addWaypoint:(NSString*)wayptId :(CGPoint)loc {
    Waypoint *waypoint = [[Waypoint alloc] initWithValues:wayptId :loc];
    [waypoints addObject:waypoint];
}

/*
 * Returns the Waypoint with the specified id
 */
- (Waypoint*) getWaypointWithId:(NSString *)wayptId {
    for (Waypoint* waypoint in waypoints) {
        if ([[waypoint waypointId] isEqualToString:wayptId]) {
            return waypoint;
        }
    }
    
    return nil;
}

/*
 * Adds an AlternateImage with the specified object id, action, original src, alternate src, alternate image width, 
 * and alternate location (x-y coordinate of top left corner of image)
 */
- (void) addAlternateImage:(NSString *)objId :(NSString *)act :(NSString *)origSrc :(NSString *)altSrc :(NSString *)wdth :(CGPoint)loc :(NSString *)cls :(NSString *)zpos {
    AlternateImage* altImage = [[AlternateImage alloc] initWithValues:objId :act :origSrc :altSrc :wdth :loc :cls :zpos];
    [alternateImages addObject:altImage];
}

/*
 * Returns the AlternateImage with the specified action
 */
- (AlternateImage*) getAlternateImageWithAction:(NSString *)action {
    for (AlternateImage* altImage in alternateImages) {
        if ([[altImage action] isEqualToString:action]) {
            return altImage;
        }
    }
    
    return nil;
}

/*
 * Returns the AlternateImage with the specified action && ObjectID
 */
- (AlternateImage*) getAlternateImageWithActionAndObjectID:(NSString *)action : (NSString *) objectId {
    for (AlternateImage* altImage in alternateImages) {
        if ([[altImage action] isEqualToString:action] && [[altImage objectId] isEqualToString:objectId]) {
            return altImage;
        }
    }
    
    return nil;
}


- (void) addIntroduction:(NSString*) introTitle : (NSMutableArray*) introductionSteps {
    [introductions setObject:introductionSteps forKey:introTitle];
}

- (NSMutableDictionary*) getIntroductions {
    return introductions;
}

- (void) addVocabulary:(NSString*) storyTitle :(NSMutableArray*) words {
    [vocabularies setObject:words forKey:storyTitle];
}

- (NSMutableDictionary*) getVocabularies{
    return vocabularies;
}

/*
 * Adds an area with the specified id and its set of points
 */
- (void) addArea:(NSString*)areaId :(UIBezierPath *)path :(NSMutableDictionary*)points :(NSString*)pageId {
    Area *area = [[Area alloc] initWithValues:areaId :path :points: pageId];
    [areas addObject:area];
}

/*
 * Returns the area with the specified id
 */
- (Area*) getAreaWithId:(NSString*)aId {
    for (Area* area in areas) {
        if ([[area areaId] isEqualToString:aId]) {
            return area;
        }
    }
    
    return nil;
}

/*
 * Returns the area with the specified page id
 */
- (Area*) getAreaWithPageId:(NSString*)pId {
    for (Area* area in areas) {
        if ([[area pageId] isEqualToString:pId]) {
            return area;
        }
    }
    
    return nil;
}

@end
