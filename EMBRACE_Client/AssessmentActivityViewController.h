//
//  AssessmentActivityViewController.h
//  EMBRACE
//
//  Created by James Rodriguez on 12/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InteractionModel.h"

@interface AssessmentActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *AnswerList;
@property(nonatomic,strong) IBOutlet UILabel *ChapterTitleLabel;
@property(nonatomic,strong) IBOutlet UIButton *nextButton;
@property(nonatomic,strong) NSString *ChapterTitle;

@property(nonatomic,strong) IBOutlet UIButton *questionButton;
@property(nonatomic,strong) IBOutlet UIButton *answer1Button;
@property(nonatomic,strong) IBOutlet UIButton *answer2Button;
@property(nonatomic,strong) IBOutlet UIButton *answer3Button;
@property(nonatomic,strong) IBOutlet UIButton *answer4Button;

- (id)initWithModel:(InteractionModel*) model : (NSString*) chapterTitle : (UIViewController*) libraryViewController;
-(void)loadNextAssessmentActivityQuestion;


@end
