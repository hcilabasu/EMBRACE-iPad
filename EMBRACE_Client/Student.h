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
    NSString* experimenterName;
    //Need some way to keep track of activities.
    //I need to know which activities were done in PM and IM and which are still locked.
    //Currently the Book represents the scenario: eg. Farm, House.
    //Can have Chapters that represent individual stories - Eg. Halloween.
    //Can then have associated Activities for each chapter. - Eg. PM and IM.
    
    NSString* currentTimestamp; //appended to end of current log session file name
}

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *experimenterName;
@property (nonatomic, strong) NSString *schoolName;
@property (nonatomic, strong) NSString* currentTimestamp;


-(id)initWithName: (NSString*) school : (NSString*) first :(NSString*) last : (NSString *) experimenter;
- (void) setCurrentTimestamp:(NSString*)timestamp;

@end
