//
//  PossibleInteraction.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 10/24/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum InteractionType {
    GROUP,
    UNGROUP,
    DISAPPEAR,
    TRANSFERANDGROUP,
    TRANSFERANDDISAPPEAR
} InteractionType;

@interface PossibleInteraction: NSObject {
    InteractionType interactionType;
    NSArray *objects; //List of objects in a predetermined order.
    NSArray *hotspots; // List of Hotspot objects. One hotspot per object.
}

@property (nonatomic, assign) InteractionType interactionType;
@property (nonatomic, strong) NSArray* objects;
@property (nonatomic, strong) NSArray* hotspots;

- (id)initWithValues:(InteractionType)type :(NSArray*) objs :(NSArray*) hotspts;

@end
