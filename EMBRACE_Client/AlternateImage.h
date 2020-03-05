//
//  AlternateImage.h
//  EMBRACE
//
//  Created by Administrator on 7/7/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlternateImage : NSObject {
    NSString* objectId;
    NSString* action;
    NSString* originalSrc;
    NSString* alternateSrc;
    NSString* width;
    NSString* height;
    CGPoint location;
    NSString* className;
    NSString* zPosition;
}

@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* originalSrc;
@property (nonatomic, strong) NSString* alternateSrc;
@property (nonatomic, strong) NSString* height;
@property (nonatomic, strong) NSString* width;
@property (nonatomic, strong) NSString* heigh;
@property (nonatomic, assign) CGPoint location;
@property (nonatomic, strong) NSString* className;
@property (nonatomic, strong) NSString* zPosition;

- (id) initWithValues:(NSString*)objId :(NSString*)act :(NSString*)origSrc :(NSString*)altSrc :(NSString*)wdth : (NSString*)height : (CGPoint)loc :(NSString*)cls : (NSString*)zpos;

@end
