//
//  Connection.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 11/21/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum InteractionType {
    GROUP,
    UNGROUP,
    DISAPPEAR,
    TRANSFERANDGROUP,
    TRANSFERANDDISAPPEAR,
    NONE
} InteractionType;

@interface Connection : NSObject {
    InteractionType interactionType;
    NSArray *objects; //The two objects that are affected by this change.
    NSArray *hotspots; // The hotspots associated with those objects.
}

@property (nonatomic, assign) InteractionType interactionType;
@property (nonatomic, strong) NSArray* objects;
@property (nonatomic, strong) NSArray* hotspots;

- (id)initWithValues:(InteractionType)type :(NSArray*) objs :(NSArray*) hotspts;
- (BOOL)isEqualToConnection:(Connection*)connection;

@end
