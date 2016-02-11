//
//  ActivitySequence.m
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ActivitySequence.h"

@implementation ActivitySequence

@synthesize bookTitle;
@synthesize modes;

- (id)initWithValues:(NSString *)title :(NSMutableArray *)modesArray {
    if (self = [super init]) {
        bookTitle = title;
        modes = modesArray;
    }
    
    return self;
}

/*
 * Returns ActivityMode for chapter with the specified title
 */
- (ActivityMode *)getModeForChapter:(NSString *)title {
    for (ActivityMode *mode in modes) {
        if ([[mode chapterTitle] isEqualToString:title]) {
            return mode;
        }
    }
    
    return nil; //chapter was not found
}

@end
