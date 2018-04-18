//
//  StudyContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface StudyContext : Context

@property (nonatomic, copy) NSString *appMode;
@property (nonatomic, copy) NSString *condition;
@property (nonatomic, copy) NSString *schoolCode;
@property (nonatomic, copy) NSString *participantCode;
@property (nonatomic, copy) NSString *studyDay;
@property (nonatomic, copy) NSString *experimenterName;
@property (nonatomic, copy) NSString *language;

- (NSMutableDictionary *)generateTimestamp;

@end
