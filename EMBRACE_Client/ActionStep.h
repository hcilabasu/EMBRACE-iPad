//
//  ActionStep.h
//  EMBRACE
//
//  Created by Administrator on 3/31/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionStep : NSObject {
    NSNumber *sentNumber;
    NSNumber *stepNumber;
    NSString *stepType;
    NSString *object1Id;
    NSString *object2Id;
    NSString *locationId;
    NSString *waypointId;
    NSString *action;
}

@property (nonatomic, strong) NSNumber *sentNumber;
@property (nonatomic, strong) NSNumber *stepNumber;
@property (nonatomic, strong) NSString *stepType;
@property (nonatomic, strong) NSString *object1Id;
@property (nonatomic, strong) NSString *object2Id;
@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, strong) NSString *waypointId;
@property (nonatomic, strong) NSString *action;

- (id) initAsSetupStep:(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)act;
- (id) initAsSolutionStep:(NSNumber*)sentNum :(NSNumber*)stepNum :(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)loc :(NSString*)waypt :(NSString*)act;

@end

