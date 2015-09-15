//
//  ActionStep.h
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionStep : NSObject {
    NSUInteger sentenceNumber;
    NSUInteger stepNumber;
    NSString *stepType;
    NSString *object1Id;
    NSString *object2Id;
    NSString *locationId;
    NSString *waypointId;
    NSString *action;
    NSString *zIndex;
}

@property (nonatomic, assign) NSUInteger sentenceNumber;
@property (nonatomic, assign) NSUInteger stepNumber;
@property (nonatomic, strong) NSString *stepType;
@property (nonatomic, strong) NSString *object1Id;
@property (nonatomic, strong) NSString *object2Id;
@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, strong) NSString *waypointId;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSString *zIndex;

- (id) initAsSetupStep:(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)act;
- (id) initAsSolutionStep:(NSUInteger)sentNum :(NSUInteger)stepNum :(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)loc :(NSString*)waypt :(NSString*)act;

@end

