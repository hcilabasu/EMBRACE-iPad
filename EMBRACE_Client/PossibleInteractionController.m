//
//  PossibleInteractionController.m
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "PossibleInteractionController.h"
#import "SolutionStepController.h"
#import "PieContextualMenu.h"

@implementation PossibleInteractionController

@synthesize mvc;
@synthesize ssc;
@synthesize stepContext;
//@synthesize conditionSetup;
//@synthesize pageContext;
//@synthesize sentenceContext;
@synthesize manipulationContext;

-(id)initWithController:(ManipulationViewController *) superMvc {
    self = [super init];
    
    if (self) {
        //Create local Pointers to needed classes, variables and properties within mvc
        self.mvc = superMvc;
        self.ssc = mvc.ssc;
        self.stepContext = mvc.stepContext;
        //self.conditionSetup = mvc.conditionSetup;
        //self.pageContext = mvc.pageContext;
        //self.sentenceContext = mvc.sentenceContext;
        self.manipulationContext = mvc.manipulationContext;
    }
    
    return self;
}

/*
 * This checks the PossibleInteractin passed in to figure out what type of interaction it is,
 * extracts the necessary information and calls the appropriate function to perform the interaction.
 */
- (void)performInteraction:(PossibleInteraction *)interaction {
    for (Connection *connection in [interaction connections]) {
        NSArray *objectIds = [connection objects]; //get the object Ids for this particular menuItem.
        NSArray *hotspots = [connection hotspots]; //Array of hotspot objects.
        
        //Get object 1 and object 2
        NSString *obj1 = [objectIds objectAtIndex:0];
        NSString *obj2 = [objectIds objectAtIndex:1];
        
        if ([connection interactionType] == UNGROUP && [[ssc getCurrentSolutionStep] isEqualToString:UNGROUPANDSTAY]) {
            [mvc ungroupObjectsAndStay:obj1 :obj2];
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1 object2:obj2 ofType:UNGROUP_AND_STAY_OBJECTS hotspot:NULL_TXT :manipulationContext];
        }
        else if ([connection interactionType] == UNGROUP) {
            [mvc ungroupObjects:obj1 :obj2]; //ungroup objects
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1  object2:obj2 ofType:UNGROUP_OBJECTS hotspot:NULL_TXT :manipulationContext];
        }
        else if ([connection interactionType] == GROUP) {
            //Get hotspots.
            Hotspot *hotspot1 = [hotspots objectAtIndex:0];
            Hotspot *hotspot2 = [hotspots objectAtIndex:1];
            
            CGPoint hotspot1Loc = [mvc.manipulationView getHotspotLocation:hotspot1];
            CGPoint hotspot2Loc = [mvc.manipulationView getHotspotLocation:hotspot2];
            
            [mvc groupObjects:obj1 :hotspot1Loc :obj2 :hotspot2Loc]; //group objects
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1  object2:obj2 ofType:GROUP_OBJECTS hotspot:[hotspot1 action] :manipulationContext];
        }
        else if ([connection interactionType] == DISAPPEAR) {
            [mvc consumeAndReplenishSupply:obj2]; //make object disappear
            
            [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:obj2 ofType:DISAPPEAR_OBJECT context:manipulationContext];
        }
    }
}

/*
 * Re-orders the possible interactions in place based on the location in the story at which the user is currently.
 * TODO: Pull up information from solution step and rank based on the location in the story and the current step
 * For now, the function makes sure the interaction which ensures going to the next step in the story is present
 * somewhere in the first three (maximum menu items) indexes of the possibleInteractions array.
 */
- (void)rankPossibleInteractions:(NSMutableArray *)possibleInteractions {
    PossibleInteraction* correctInteraction = [self getCorrectInteraction];
    
    int correctIndex; //index to insert correct menu item
    
    //Generate a random index number up to the number of PossibleInteraction objects (if less than the maximum number of menu items) or up to the maximum number of menu items otherwise. The index is random to ensure that the correct interaction won't always be at the same location on the menu.
    if ([possibleInteractions count] < maxMenuItems) {
        correctIndex = arc4random_uniform([possibleInteractions count]);
    }
    else {
        correctIndex = arc4random_uniform(maxMenuItems);
    }
    
    //Look for the correct interaction and swap it with the element at the correct index
    for (int i = 0; i < [possibleInteractions count]; i++) {
        if ([[possibleInteractions objectAtIndex:i] isEqual:correctInteraction]) {
            [possibleInteractions exchangeObjectAtIndex:i withObjectAtIndex:correctIndex];
        }
    }
}

//TODO: add descrption
- (NSMutableArray *)getPossibleTransferInteractionsforObjects:(NSString *)objConnected :(NSString *)objConnectedTo :(NSString *)currentUnconnectedObj :(Hotspot *)objConnectedHotspot :(Hotspot *)currentUnconnectedObjHotspot{
    NSMutableArray *groupings = [[NSMutableArray alloc] init];
    
    //Get the hotspots for the grouped objects
    NSMutableArray *hotspotsForObjConnected = [mvc.model getHotspotsForObject:objConnected OverlappingWithObject :objConnectedTo];
    NSMutableArray *hotspotsForObjConnectedTo = [mvc.model getHotspotsForObject:objConnectedTo OverlappingWithObject :objConnected];
    
    //Compare their hotspots to determine where the two objects are currently grouped
    for (Hotspot *hotspot1 in hotspotsForObjConnectedTo) {
        for (Hotspot *hotspot2 in hotspotsForObjConnected) {
            //Need to calculate exact pixel location of one of the hotspots and then make sure it is connected to the other object at that location
            CGPoint hotspot1Loc = [mvc.manipulationView getHotspotLocation:hotspot1];
            NSString *isConnectedObjHotspotConnectedString  = [mvc.manipulationView groupedObject:objConnectedTo atHotSpot:hotspot1Loc];
            
            //Make sure the two hotspots have the same action and make sure the roles do not match (there are only two possibilities right now: subject and object). Also make sure the hotspots are connected to each other. If all is well, these objects can be ungrouped.
            bool rolesMatch = [[hotspot1 role] isEqualToString:[hotspot2 role]];
            bool actionsMatch = [[hotspot1 action] isEqualToString:[hotspot2 action]];
            
            if (actionsMatch && ![isConnectedObjHotspotConnectedString isEqualToString:EMPTYSTRING] && !rolesMatch) {
                PossibleInteraction *interaction = [[PossibleInteraction alloc] init];
                
                //Add the connection to ungroup first.
                NSArray *ungroupObjects;
                NSArray *hotspotsForUngrouping;
                
                //Add the subject to the ungroup connection before the object
                if ([[hotspot1 role] isEqualToString:SUBJECT]) {
                    ungroupObjects = [[NSArray alloc] initWithObjects:objConnectedTo, objConnected, nil];
                    hotspotsForUngrouping = [[NSArray alloc] initWithObjects:hotspot1, hotspot2, nil];
                }
                else {
                    ungroupObjects = [[NSArray alloc] initWithObjects:objConnected, objConnectedTo, nil];
                    hotspotsForUngrouping = [[NSArray alloc] initWithObjects:hotspot2, hotspot1, nil];
                }
                
                [interaction addConnection:UNGROUP :ungroupObjects :hotspotsForUngrouping];
                
                //Then add the connection to group or disappear
                NSArray *transferObjects;
                NSArray *hotspotsForTransfer;
                
                //Add the subject to the group or disappear interaction before the object
                if ([[objConnectedHotspot role] isEqualToString:SUBJECT]) {
                    transferObjects = [[NSArray alloc] initWithObjects:objConnected, currentUnconnectedObj, nil];
                    hotspotsForTransfer = [[NSArray alloc] initWithObjects:objConnectedHotspot, currentUnconnectedObjHotspot, nil];
                }
                else {
                    transferObjects = [[NSArray alloc] initWithObjects:currentUnconnectedObj, objConnected, nil];
                    hotspotsForTransfer = [[NSArray alloc] initWithObjects:currentUnconnectedObjHotspot, objConnectedHotspot, nil];
                }
                
                //Get the relationship between the connected and currently unconnected objects so we can check to see what type of relationship it is.
                Relationship *relationshipBetweenObjects = [mvc.model getRelationshipForObjectsForAction:objConnected :currentUnconnectedObj :[objConnectedHotspot action]];
                mvc.lastRelationship = relationshipBetweenObjects;
                [mvc.allRelationships addObject:mvc.lastRelationship];
                
                if ([[relationshipBetweenObjects  actionType] isEqualToString:GROUP_TXT]) {
                    [interaction addConnection:GROUP :transferObjects :hotspotsForTransfer];
                    [interaction setInteractionType:TRANSFERANDGROUP];
                    
                    [groupings addObject:interaction];
                }
                else if ([[relationshipBetweenObjects actionType] isEqualToString:DISAPPEAR_TXT]) {
                    [interaction addConnection:DISAPPEAR :transferObjects :hotspotsForTransfer];
                    [interaction setInteractionType:TRANSFERANDDISAPPEAR];
                    
                    [groupings addObject:interaction];
                }
            }
        }
    }
    
    return groupings;
}

/*
 * This function takes in a possible interaction and calculates the layout of the images after the interaction occurs.
 * It then adds the result to the menuDataSource in order to display each menu item appropriately.
 * NOTE: For the moment this code could be used to create both the ungroup and all other interactions...lets see if this is the case after this code actually simulates the end result. If it is, the code should be simplified to use the same function.
 * NOTE: This should be pushed to the JS so that all actual positioning information is in one place and we're not duplicating code that's in the JS in the objC as well. For now...we'll just do it here.
 * Come back to this...
 */
- (void)simulatePossibleInteractionForMenuItem:(PossibleInteraction *)interaction :(Relationship *)relationship {
    NSMutableDictionary *images = [[NSMutableDictionary alloc] init];
    
    //Populate the mutable dictionary of menuItemImages.
    for (Connection* connection in [interaction connections]) {
        NSArray *objectIds = [connection objects];
        
        //Get all the necessary information of the UIImages.
        for (int i = 0; i < [objectIds count]; i++) {
            NSString *objId = objectIds[i];
            
            if ([images objectForKey:objId] == nil) {
                MenuItemImage *itemImage;
                
                //Horizontally flip the image of the subject performing a transfer and disappear interaction to make it look like it is giving an object to the receiver.
                if ([interaction interactionType] == TRANSFERANDDISAPPEAR
                    && [connection interactionType] == UNGROUP
                    && objId == [[connection objects] objectAtIndex:0]) {
                    itemImage = [mvc createMenuItemForImage:objId :@"rotate"];
                }
                else if ([[relationship action] isEqualToString:@"flip"])
                {
                    itemImage = [mvc createMenuItemForImage:objId : @"flipHorizontal"];
                }
                //Otherwise, leave the image unflipped
                else {
                    itemImage = [mvc createMenuItemForImage:objId : @"normal"];
                }
                
                if (itemImage != nil)
                    [images setObject:itemImage forKey:objId];
            }
        }
        
        //If the objects are already connected to other objects, create images for those as well, if they haven't already been created
        for (NSString *objectId in objectIds) {
            NSMutableArray *connectedObject = [mvc.currentGroupings objectForKey:objectId];
            
            for (int i = 0; connectedObject && [connection interactionType] != UNGROUP && i < [connectedObject count]; i++) {
                if ([images objectForKey:connectedObject[i]] == nil) {
                    MenuItemImage *itemImage = [mvc createMenuItemForImage:connectedObject[i] :@"normal"];
                    
                    if (itemImage != nil) {
                        [images setObject:itemImage forKey:connectedObject[i]];
                    }
                }
            }
        }
    }
    
    //Perform the changes to the connections.
    for (Connection* connection in [interaction connections]) {
        NSArray *objectIds = [connection objects];
        NSArray *hotspots = [connection hotspots];
        
        //Update the locations of the UIImages based on the type of interaction with the simulated location.
        //get the object Ids for this particular menuItem.
        NSString *obj1 = [objectIds objectAtIndex:0]; //get object 1
        NSString *obj2 = [objectIds objectAtIndex:1]; //get object 2
        NSString *connectedObject;
        Hotspot *connectedHotspot1;
        Hotspot *connectedHotspot2;
        
        if ([connection interactionType] == UNGROUP) {
            float GAP; //we want a pixel gap between objects to show that they're no longer grouped together.
            
            //The object performing a transfer and disappear interaction will be ungrouped from the object
            //it is transferring, but we use a negative GAP value because we still want it to appear close
            //enough to look as though it is giving the object to the receiver.
            if ([interaction interactionType] == TRANSFERANDDISAPPEAR)
                GAP = -15;
            //For other ungroup interactions, we want a 15 pixel gap between objects to show they are separated
            else
                GAP = 15;
            
            [mvc simulateUngrouping:obj1 :obj2 :images :GAP];
        }
        else if ([connection interactionType] == GROUP || [connection interactionType] == DISAPPEAR) {
            //Get hotspots.
            Hotspot *hotspot1 = [hotspots objectAtIndex:0];
            Hotspot *hotspot2 = [hotspots objectAtIndex:1];
            
            //Find all objects connected to the moving object
            for (int objectIndex = 2; objectIndex < [objectIds count]; objectIndex++) {
                //For each object, find the hotspots that serve as the connection points
                connectedObject = [objectIds objectAtIndex:objectIndex];
                
                NSMutableArray *movingObjectHotspots = [mvc.model getHotspotsForObject:obj1 OverlappingWithObject:connectedObject];
                NSMutableArray *containedHotspots = [mvc.model getHotspotsForObject:connectedObject OverlappingWithObject:obj1];
                
                connectedHotspot1 = [mvc findConnectedHotspot:movingObjectHotspots :connectedObject];
                connectedHotspot2 = [mvc findConnectedHotspot:containedHotspots :connectedObject];
                
                //This object is connected to the moving object at a particular hotspot
                if (![[connectedHotspot2 objectId] isEqualToString:EMPTYSTRING]) {
                    for (Hotspot *ht in containedHotspots) {
                        CGPoint hotspotLoc = [mvc.manipulationView getHotspotLocation:ht];
                        NSString *isHotspotConnectedMovingObjectString = [mvc.manipulationView groupedObject:connectedObject atHotSpot:hotspotLoc];
                        if ([isHotspotConnectedMovingObjectString isEqualToString:obj1])
                            connectedHotspot2 = ht;
                    }
                }
            }
            
            NSMutableArray *groupObjects = [[NSMutableArray alloc] initWithObjects:obj1, obj2, connectedObject, nil];
            NSMutableArray *hotspotsForGrouping = [[NSMutableArray alloc] initWithObjects:hotspot1, hotspot2, connectedHotspot2, nil];
            
            [mvc simulateGroupingMultipleObjects:groupObjects :hotspotsForGrouping :images];
        }
    }
    
    NSMutableArray *imagesArray = [[images allValues] mutableCopy];
    
    //Calculate the bounding box for the group of objects being passed to the menu item.
    CGRect boundingBox = [mvc getBoundingBoxOfImages:imagesArray];
    
    [mvc.menuDataSource addMenuItem:interaction :relationship :imagesArray :boundingBox];
}

/*
 * Gets the current solution step of ActionStep type and converts it to a PossibleInteraction
 * object
 */
- (PossibleInteraction *)getCorrectInteraction {
    PossibleInteraction* correctInteraction;
    
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        //If step type involves transference, we must manually create the PossibleInteraction object.
        //Otherwise, it can be directly converted.
        if ([[currSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT] ||
            [[currSolStep stepType] isEqualToString:TRANSFERANDDISAPPEAR_TXT]) {
            correctInteraction = [[PossibleInteraction alloc] init];
            
            //Get step information for current step
            NSString *currObj1Id = [currSolStep object1Id];
            NSString *currObj2Id = [currSolStep object2Id];
            NSString *currAction = [currSolStep action];
            
            //Objects involved in group setup for current step
            NSArray *currObjects = [[NSArray alloc] initWithObjects:currObj1Id, currObj2Id, nil];
            
            //Get hotspots for both objects associated with action for current step
            Hotspot *currHotspot1 = [mvc.model getHotspotforObjectWithActionAndRole:currObj1Id :currAction :SUBJECT];
            Hotspot *currHotspot2 = [mvc.model getHotspotforObjectWithActionAndRole:currObj2Id :currAction :OBJECT];
            NSArray *currHotspotsForInteraction = [[NSArray alloc]initWithObjects:currHotspot1, currHotspot2, nil];
            
            [correctInteraction addConnection:UNGROUP :currObjects :currHotspotsForInteraction];
            
            //Get next step to be completed
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            //Get step information for next step
            NSString *nextObj1Id = [nextSolStep object1Id];
            NSString *nextObj2Id = [nextSolStep object2Id];
            NSString *nextAction = [nextSolStep action];
            
            //Objects involved in group setup for next step
            NSArray *nextObjects = [[NSArray alloc] initWithObjects:nextObj1Id, nextObj2Id, nil];
            
            //Get hotspots for both objects associated with action for next step
            Hotspot *nextHotspot1 = [mvc.model getHotspotforObjectWithActionAndRole:nextObj1Id :nextAction :SUBJECT];
            Hotspot *nextHotspot2 = [mvc.model getHotspotforObjectWithActionAndRole:nextObj2Id :nextAction :OBJECT];
            NSArray *nextHotspotsForInteraction = [[NSArray alloc]initWithObjects:nextHotspot1, nextHotspot2, nil];
            
            //Add the group or disappear connection and set the interaction to the appropriate type
            if ([[currSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT]) {
                [correctInteraction addConnection:GROUP :nextObjects :nextHotspotsForInteraction];
                [correctInteraction setInteractionType:TRANSFERANDGROUP];
            }
            else if ([[currSolStep stepType] isEqualToString:TRANSFERANDDISAPPEAR_TXT]) {
                [correctInteraction addConnection:DISAPPEAR :nextObjects :nextHotspotsForInteraction];
                [correctInteraction setInteractionType:TRANSFERANDDISAPPEAR];
            }
        }
        else {
            correctInteraction = [mvc convertActionStepToPossibleInteraction:currSolStep];
        }
    }
    
    return correctInteraction;
}

@end
