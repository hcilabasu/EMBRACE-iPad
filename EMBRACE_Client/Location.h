//
//  Location.h
//  EMBRACE
//
//  Created by Administrator on 4/11/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Location : NSObject {
    NSString* locationId;
    NSString* originX;
    NSString* originY;
    NSString* height;
    NSString* width;
}

@property (nonatomic, strong) NSString* locationId;
@property (nonatomic, strong) NSString* originX;
@property (nonatomic, strong) NSString* originY;
@property (nonatomic, strong) NSString* height;
@property (nonatomic, strong) NSString* width;

- (id) initWithValues:(NSString*)locId :(NSString*)x :(NSString*)y :(NSString*)h :(NSString*)w;

@end
