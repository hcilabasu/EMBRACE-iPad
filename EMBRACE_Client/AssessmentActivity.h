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
@property (nonatomic,assign)  NSString *QuestionAudio;
@property (nonatomic, assign) NSString *Answer1;
@property (nonatomic,assign)  NSString *Answer1Audio;
@property (nonatomic, assign) NSString *Answer2;
@property (nonatomic,assign)  NSString *Answer2Audio;
@property (nonatomic, assign) NSString *Answer3;
@property (nonatomic,assign)  NSString *Answer3Audio;
@property (nonatomic, assign) NSString *Answer4;
@property (nonatomic,assign)  NSString *Answer4Audio;
@property (nonatomic, assign) NSString *expectedSelection;

- (id) initWithValues:(NSInteger)QuestionNum :(NSString*)questiontext : (NSString*)questionAudio :(NSString*)answer1 : (NSString*)answer1Audio : (NSString*)answer2 : (NSString*)answer2Audio :(NSString*)answer3 : (NSString*)answer3Audio : (NSString *)answer4 : (NSString*)answer4Audio : (NSString*)selection;
@end
