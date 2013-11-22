//
//  PossibleInteraction.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 10/24/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Connection.h"

//Note: Instead of doing it this way, it may make more sense to break each possible interaction down into a set of connections, similar to how the groupings are stored in the JS. In this way, each connection has 2 objects, 2 hotspots, and contains the interaction type for that particular connection (group, ungroup, disappear). There also exists a list of connections that happen in order that are stored in the possible interaction. For those that do not change that we want to incorporate in some way, we can have another interaction type that says "none".
//This may make the possible interaction easier to read, easier to implement, and will provide is with the necessary hotspot information for displaying the hotspots to the user.
//TODO: This duplicates the images in the menu items. Fix this.
@interface PossibleInteraction: NSObject {
    NSMutableArray *connections; //List of connections in the order that they need to be changed. Any connections that are not changed will be listed with the interactionType of NONE.
    InteractionType interactionType;
}

@property (nonatomic, strong) NSArray* connections;
@property (nonatomic, assign) InteractionType interactionType;

- (id)initWithInteractionType:(InteractionType)type;
- (void)addConnection:(InteractionType)type :(NSArray*) objs :(NSArray*) hotspts;

@end
