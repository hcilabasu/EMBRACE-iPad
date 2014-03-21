//
//  PhysicalManipulationActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"
#import "Setup.h"

@interface PhysicalManipulationActivity : Activity {
    Setup* setup;
}

@property (nonatomic, strong) Setup *setup;

- (void) addSetup:(NSString*)title;

@end
