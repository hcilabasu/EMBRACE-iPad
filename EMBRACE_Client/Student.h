//
//  Student.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 5/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Student : NSObject

@property (nonatomic, strong) NSString *schoolCode;
@property (nonatomic, strong) NSString *participantCode;
@property (nonatomic, strong) NSString *studyDay;
@property (nonatomic, strong) NSString *experimenterName;
@property (nonatomic, strong) NSString *currentTimestamp; //appended to end of current log session file name

- (id)initWithValues:(NSString *)school :(NSString *)participant :(NSString *)study :(NSString *)experimenter;
- (void)setCurrentTimestamp:(NSString *)timestamp;

@end
