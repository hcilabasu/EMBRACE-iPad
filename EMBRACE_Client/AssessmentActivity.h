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
@property (nonatomic, copy) NSString *QuestionText;
@property (nonatomic,copy)  NSString *QuestionAudio;
@property (nonatomic, copy) NSString *Answer1;
@property (nonatomic,copy)  NSString *Answer1Audio;
@property (nonatomic, copy) NSString *Answer2;
@property (nonatomic,copy)  NSString *Answer2Audio;
@property (nonatomic, copy) NSString *Answer3;
@property (nonatomic,copy)  NSString *Answer3Audio;
@property (nonatomic, copy) NSString *Answer4;
@property (nonatomic,copy)  NSString *Answer4Audio;
@property (nonatomic, copy) NSString *expectedSelection;

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext : (NSString*)questionAudio :(NSString*)answer1 : (NSString*)answer1Audio : (NSString*)answer2 : (NSString*)answer2Audio :(NSString*)answer3 : (NSString*)answer3Audio : (NSString *)answer4 : (NSString*)answer4Audio : (NSString*)selection;
@end
