//
//  Introduction.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntroductionStep.h"

@interface Introduction : NSObject {
    NSString* title; // The title of the story
    NSMutableArray* steps;
}

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSMutableArray* steps;


- (id) initWithTitle:(NSString*)introTitle
                    : (NSMutableArray*)introSteps;
- (NSMutableArray*) getStepsForIntroduction:(NSString*)introTitle;

@end
