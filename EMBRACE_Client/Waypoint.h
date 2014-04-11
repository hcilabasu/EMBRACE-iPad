//
//  Waypoint.h
//  EMBRACE
//
//  Created by Administrator on 4/11/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Waypoint : NSObject {
    NSString* waypointId;
    CGPoint location; //This point represents a percentage for the moment.
}

@property (nonatomic, strong) NSString* waypointId;
@property (nonatomic, assign) CGPoint location;

- (id) initWithValues:(NSString*)wayptId :(CGPoint)loc;

@end
