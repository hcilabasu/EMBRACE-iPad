//
//  Hotspot.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Hotspot : NSObject {
    NSString* objectId;
    NSString* action;
    NSString* role;
    CGPoint location; //This point represents a percentage for the moment. 
}

@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* role;
@property (nonatomic, assign) CGPoint location;

- (id) initWithValues:(NSString*)objId :(CGPoint)loc;

- (id) initWithValues:(NSString*)objId :(NSString*)act :(NSString*)objRole :(CGPoint)loc;
@end
