//
//  OrderConstraint.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 9/9/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "OrderConstraint.h"

@implementation OrderConstraint

@synthesize action1;
@synthesize action2;
@synthesize ruleType;

- (id) initWithValues:(NSString*)act1 :(NSString*)act2 :(NSString*) rType {
    if(self = [super init]) {
        action1 = act1;
        action2 = act2;
        ruleType = rType;
    }
    
    return self;
}

@end
