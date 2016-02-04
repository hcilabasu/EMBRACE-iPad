//
//  ActivityMode.m
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ActivityMode.h"

@implementation ActivityMode

@synthesize chapterTitle;
@synthesize reader;
@synthesize language;
@synthesize interventionType;

- (id) initWithValues:(NSString*)title :(Reader)read :(Language)lang :(InterventionType)type {
    if (self = [super init]) {
        chapterTitle = title;
        reader = read;
        language = lang;
        interventionType = type;
    }
    
    return self;
}

@end
