//
//  MovementConstraint.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 9/9/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Constraint.h"

@interface MovementConstraint : Constraint {
    NSString* objId;
    NSString* action;
    NSString* originX;
    NSString* originY;
    NSString* height;
    NSString* width;
}

@property (nonatomic, strong) NSString* objId;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* originX;
@property (nonatomic, strong) NSString* originY;
@property (nonatomic, strong) NSString* height;
@property (nonatomic, strong) NSString* width;

- (id) initWithValues:(NSString*)objectId :(NSString*)act :(NSString*)x :(NSString*)y :(NSString*)w :(NSString*)h;

@end
