//
//  AssessmentActivity.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Activity.h"

@interface AssessmentActivity : Activity
{
}


@property (nonatomic, assign) NSInteger QuestionNumber;
@property (nonatomic, assign) NSString *QuestionText;
@property (nonatomic, assign) NSString *Answer1;
@property (nonatomic, assign) NSString *Answer2;
@property (nonatomic, assign) NSString *Answer3;
@property (nonatomic, assign) NSString *Answer4;
@property (nonatomic, assign) NSInteger expectedSelection;

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext :(NSString*)answer1 :(NSString*)answer2 :(NSString*)answer3 : (NSString *)answer4 : (NSInteger)selection;
@end
