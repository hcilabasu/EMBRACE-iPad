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

@property (nonatomic, weak) IBOutlet UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, weak) IBOutlet UITableView *AnswerList;
@property (nonatomic, weak) IBOutlet UIView *transparentLayer;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, copy) NSString *chapterTitle;

@property (nonatomic, weak) IBOutlet UIButton *questionButton;
@property (nonatomic, weak) IBOutlet UIButton *answer1Button;
@property (nonatomic, weak) IBOutlet UIButton *answer2Button;
@property (nonatomic, weak) IBOutlet UIButton *answer3Button;
@property (nonatomic, weak) IBOutlet UIButton *answer4Button;


- (id)initWithModel:(InteractionModel *)model :(UIViewController *)libraryViewController :(UIImage *)backgroundImage :(NSString *)bookTitle :(NSString *)chapterTitle :(NSString *)currentPage :(NSString *)currentSentence :(NSString *)currentStep;
- (void)loadNextAssessmentActivityQuestion;

@end
