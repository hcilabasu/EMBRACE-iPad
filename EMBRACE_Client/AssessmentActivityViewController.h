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

- (id)initWithModel:(InteractionModel*) model : (NSString*) chapterTitle:(UIViewController*) libraryViewController;
-(void)loadNextAssessmentActivityQuestion;

@end
