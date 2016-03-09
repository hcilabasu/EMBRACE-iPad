//
//  StudyContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface StudyContext : Context

@property (nonatomic, assign) NSString *condition;
@property (nonatomic, assign) NSString *schoolCode;
@property (nonatomic, assign) NSString *participantCode;
@property (nonatomic, assign) NSString *studyDay;
@property (nonatomic, assign) NSString *experimenterName;

@end
