//
//  Setup.h
//  EMBRACE
//
//  Created by Administrator on 3/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SetupStep.h"

@interface Setup : NSObject {
    NSString *storyTitle;
    NSMutableArray *setupSteps;
}

@property (nonatomic, strong) NSString *storyTitle;
@property (nonatomic, strong) NSMutableArray *setupSteps;

- (id) initWithTitle:(NSString*)title;
- (void) addSetupStep:(SetupStep*)setupStep;

@end
