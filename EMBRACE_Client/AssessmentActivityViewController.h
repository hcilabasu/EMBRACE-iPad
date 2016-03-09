//
//  AssessmentActivityViewController.h
//  EMBRACE
//
//  Created by James Rodriguez on 12/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InteractionModel.h"
#import "PlayAudioFile.h"

@interface AssessmentActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, strong) IBOutlet UITableView *AnswerList;
@property (nonatomic, strong) IBOutlet UIView *transparentLayer;
@property (nonatomic, strong) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSString *ChapterTitle;

@property (nonatomic,strong) IBOutlet UIButton *questionButton;
@property (nonatomic,strong) IBOutlet UIButton *answer1Button;
@property (nonatomic,strong) IBOutlet UIButton *answer2Button;
@property (nonatomic,strong) IBOutlet UIButton *answer3Button;
@property (nonatomic,strong) IBOutlet UIButton *answer4Button;
@property (nonatomic, strong) PlayAudioFile *playAudioFileClass;

- (id)initWithModel:(InteractionModel *)model :(UIViewController *)libraryViewController :(UIImage *)backgroundImage :(NSString *)bookTitle :(NSString *)chapterTitle :(NSString *)currentPage :(NSString *)currentSentence :(NSString *)currentStep;
- (void)loadNextAssessmentActivityQuestion;

@end
