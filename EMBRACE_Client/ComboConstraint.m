//
//  ComboConstraint.m
//  EMBRACE
//
//  Created by Administrator on 8/26/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "ComboConstraint.h"

@implementation ComboConstraint

@synthesize objId;
@synthesize comboActions;

- (id) initWithValues:(NSString*)objectId :(NSMutableArray*)comboActs {
    if(self = [super init]) {
        objId = objectId;
        comboActions = comboActs;
    }
    
    return self;
}

@end
