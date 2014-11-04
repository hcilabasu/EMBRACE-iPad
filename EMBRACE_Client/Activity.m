//
//  Activity.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"

@implementation Activity

@synthesize activityId;
@synthesize activityTitle;
@synthesize pageNum;
@synthesize pages;
@synthesize solution;

- (id) init {
    if (self = [super init]) {
        pages = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) addPage:(Page*) page {
    [pages addObject:page];
}

@end
