//
//  AssessmentContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface AssessmentContext : Context

@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, assign) NSInteger assessmentStepNumber;

@end
