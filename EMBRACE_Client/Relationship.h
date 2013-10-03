//
//  Relationship.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 7/22/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Relationship : NSObject {
    NSString* object1Id;
    NSString* object2Id;
    NSString* action; //The actual action. For example: receive, putDown, etc.
    NSString* actionType; //whether it's a grouping/ungrouping action, or whether it's a disappearing action -- causes an object to disappear, and re-appear elsewhere.
}

@property (nonatomic, strong) NSString* object1Id;
@property (nonatomic, strong) NSString* object2Id;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* actionType;

- (id) initWithValues:(NSString*)obj1Id :(NSString*)can :(NSString*)type :(NSString*) obj2Id;

@end
