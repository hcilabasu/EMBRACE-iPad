//
//  Student.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 5/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Student : NSObject

@property (nonatomic, copy) NSString *schoolCode;
@property (nonatomic, copy) NSString *participantCode;
@property (nonatomic, copy) NSString *studyDay;
@property (nonatomic, copy) NSString *experimenterName;
@property (nonatomic, copy) NSString *currentTimestamp; //appended to end of current log session file name

- (id)initWithValues:(NSString *)school :(NSString *)participant :(NSString *)study :(NSString *)experimenter;
- (void)setCurrentTimestamp:(NSString *)timestamp;

@end
