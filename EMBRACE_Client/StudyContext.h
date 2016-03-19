//
//  StudyContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface StudyContext : Context

@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSString *schoolCode;
@property (nonatomic, strong) NSString *participantCode;
@property (nonatomic, strong) NSString *studyDay;
@property (nonatomic, strong) NSString *experimenterName;
@property (nonatomic, strong) NSString *language;

- (NSMutableDictionary *)generateTimestamp;

@end
