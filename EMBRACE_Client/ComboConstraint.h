//
//  ComboConstraint.h
//  EMBRACE
//
//  Created by Administrator on 8/26/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Constraint.h"

@interface ComboConstraint : Constraint {
    NSString* objId; //the object this constraint applies to
    NSMutableArray* comboActions; //list of actions/hotspots the object cannot use simultaneously
}

@property (nonatomic, strong) NSString* objId;
@property (nonatomic, strong) NSMutableArray* comboActions;

- (id) initWithValues:(NSString*)objectId :(NSMutableArray*)combActs;

@end
