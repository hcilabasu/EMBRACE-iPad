//
//  OrderConstraint.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 9/9/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Constraint.h"

@interface OrderConstraint : Constraint {
    NSString* action1;
    NSString* action2;
    NSString* ruleType;
}

@property (nonatomic, strong) NSString* action1;
@property (nonatomic, strong) NSString* action2;
@property (nonatomic, strong) NSString* ruleType;

- (id) initWithValues:(NSString*)act1 :(NSString*)act2 :(NSString*) rType;

@end
