//
//  AlternateImage.m
//  EMBRACE
//
//  Created by Administrator on 7/7/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "AlternateImage.h"

@implementation AlternateImage

@synthesize objectId;
@synthesize action;
@synthesize originalSrc;
@synthesize alternateSrc;
@synthesize width;
@synthesize height;
@synthesize location;
@synthesize className;
@synthesize zPosition;

- (id) initWithValues:(NSString*)objId :(NSString*)act :(NSString*)origSrc :(NSString*)altSrc :(NSString*)wdth :(NSString*)heigh : (CGPoint)loc :(NSString*)cls :(NSString*)zpos {
    if (self = [super init]) {
        objectId = objId;
        action = act;
        originalSrc = origSrc;
        alternateSrc = altSrc;
        width = wdth;
        height = heigh;
        location = loc;
        className = cls;
        zPosition = zpos;
    }
    
    return self;
}

@end
