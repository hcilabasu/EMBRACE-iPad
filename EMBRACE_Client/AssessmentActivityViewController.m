//
//  AssessmentActivityViewController.m
//  EMBRACE
//
//  Created by James Rodriguez on 12/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "AssessmentActivityViewController.h"

@interface AssessmentActivityViewController ()

@end

NSInteger AnswerSelection[4];
NSMutableArray *AnswerOptions;
NSArray *AnswerOptionEnglishAudio;
NSArray *AnswerOptionSpanishAudio;
NSString *Question;
NSString *QuestionAudio;
NSInteger questionNum;
NSInteger correctSelection;
NSMutableDictionary *assessmentActivities;
NSMutableArray *currentAssessmentActivitySteps;
NSInteger totalAssessmentActivitySteps;
NSInteger currentAssessmentActivityStep;
UIViewController *libraryView;

@implementation AssessmentActivityViewController
@synthesize AnswerList;
//@synthesize model;
//@synthesize chapterTitle;




- (id)initWithModel:(InteractionModel*) model : (NSString*)chapterTitle : (UIViewController*)libraryViewController
{
    self=[super init];//self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        libraryView=libraryViewController;
        
        currentAssessmentActivityStep = 1;
        
        // Custom initialization
        //AnswerList = [[UITableView alloc]init];
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        assessmentActivities =  [model getAssessmentActivity];
        currentAssessmentActivitySteps = [assessmentActivities objectForKey:chapterTitle];
        totalAssessmentActivitySteps = [currentAssessmentActivitySteps count];
        
        AssessmentActivity* currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep-1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        AnswerOptions =[[NSMutableArray alloc] init];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)loadNextAssessmentActivityQuestion{
    
    currentAssessmentActivityStep++;
    
    if(currentAssessmentActivityStep<totalAssessmentActivitySteps)
    {
        
        //AnswerList = [[UITableView alloc]init];
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        AssessmentActivity* currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep-1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        [AnswerOptions removeAllObjects];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        
    }
    else
    {
        [super.navigationController popViewControllerAnimated:YES]; //return to library view
    }
}

- (IBAction)NextButtonPressed:(id)sender {
    //move to next question -> load next set of question paramters
    //reset table row colors
    //hide next button
    //[self loadNextAssessmentActivityQuestion];
    currentAssessmentActivityStep++;
    
    if(currentAssessmentActivityStep<=totalAssessmentActivitySteps)
    {
        
        //AnswerList = [[UITableView alloc]init];
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        AssessmentActivity* currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep-1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        [AnswerOptions removeAllObjects];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        
        //reset tableview cells, reload tableview
        NSArray *cells = [AnswerList indexPathsForVisibleRows];
        
        int i=0;
        while(i<[AnswerOptions count])
        {
            UITableViewCell *tempCell = [AnswerList cellForRowAtIndexPath:cells[i]];
            tempCell.contentView.alpha = 1;
            tempCell.backgroundColor = [UIColor whiteColor];
            tempCell.alpha = 1;
            tempCell.accessoryType = UITableViewCellAccessoryNone;
            i++;
        }
        
        [AnswerList reloadData];
        
    }
    else
    {
        //[super.navigationController dismissViewControllerAnimated:YES completion:nil];
        //[self.navigationController popViewControllerAnimated:YES]; //return to pmview
        //[self.navigationController popViewControllerAnimated:YES]; //return to library view
        [self.navigationController popToViewController:libraryView animated:YES];
    }
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier =  [NSString stringWithFormat:@"MyCell%d", [indexPath row]];
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell==nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    int row = [indexPath row];
    cell.textLabel.text = AnswerOptions[row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //checks if option has already been selected else do nothing
    if (AnswerSelection[[indexPath row]] == 0) {
     
            AnswerSelection[[indexPath row]] =1;
     
            //UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"MyCell%d", [indexPath row]]];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSArray *cells = [tableView indexPathsForVisibleRows];
        
            //checks if option is correct else gray out
            if(([indexPath row]+1) == correctSelection)
            {
                //gray out other options
                int i=0;
                while(i<[AnswerOptions count])
                {
                    if (i!=(correctSelection-1)) {
                        //gray out option
                        
                        UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:cells[i]];
                        AnswerSelection[i] = 1;
                        tempCell.contentView.alpha=.2;
                        tempCell.backgroundColor = [UIColor grayColor];
                        tempCell.alpha =.2;
                        
                    }
                    else{
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    i++;
                }
                //show next button
            }
            else
            {
                //gray out option
                cell.contentView.alpha=.2;
                cell.backgroundColor = [UIColor grayColor];
                cell.alpha =.2;
            }
     }
    
    [tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
    //AssessmentArrray *question = [questions objectAtIndex:section];
    return [NSString stringWithFormat:@"%d. %@", questionNum,Question];
}

@end
