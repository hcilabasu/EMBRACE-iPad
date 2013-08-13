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
    NSString* action;
}

@property (nonatomic, strong) NSString* object1Id;
@property (nonatomic, strong) NSString* object2Id;
@property (nonatomic, strong) NSString* action;

- (id) initWithValues:(NSString*)obj1Id :(NSString*)can :(NSString*) obj2Id;

@end
