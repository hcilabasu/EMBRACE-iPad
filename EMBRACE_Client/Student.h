//
//  Student.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 5/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Student : NSObject {
    NSString* firstName;
    NSString* lastName;
    
    //Need some way to keep track of activities.
    //I need to know which activities were done in PM and IM and which are still locked.
    //Currently the Book represents the scenario: eg. Farm, House.
    //Can have Chapters that represent individual stories - Eg. Halloween.
    //Can then have associated Activities for each chapter. - Eg. PM and IM.
}

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

-(id)initWithName:(NSString*) first :(NSString*) last;

@end
