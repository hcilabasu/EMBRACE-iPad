//
//  SetupStep.h
//  EMBRACE
//
//  Created by Administrator on 3/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SetupStep : NSObject {
    NSString *stepType;
    NSString *object1Id;
    NSString *object2Id;
    NSString *action;
}

@property (nonatomic, strong) NSString *stepType;
@property (nonatomic, strong) NSString *object1Id;
@property (nonatomic, strong) NSString *object2Id;
@property (nonatomic, strong) NSString *action;

- (id) initWithValues:(NSString*)type :(NSString*)obj1Id :(NSString*) obj2Id :(NSString*)act;

@end
