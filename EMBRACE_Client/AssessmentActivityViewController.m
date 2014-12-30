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
NSString *AnswerOption1EnglishAudio;
NSString *AnswerOption1SpanishAudio;
NSString *AnswerOption2EnglishAudio;
NSString *AnswerOption2SpanishAudio;
NSString *AnswerOption3EnglishAudio;
NSString *AnswerOption3SpanishAudio;
NSString *AnswerOption4EnglishAudio;
NSString *AnswerOption4SpanishAudio;
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
@synthesize nextButton;
@synthesize ChapterTitleLabel;
//@synthesize model;
@synthesize ChapterTitle;

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
        
        ChapterTitle =chapterTitle;
        
        assessmentActivities =  [model getAssessmentActivity];
        currentAssessmentActivitySteps = [assessmentActivities objectForKey:chapterTitle];
        totalAssessmentActivitySteps = [currentAssessmentActivitySteps count];
        
        AssessmentActivity* currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep-1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        QuestionAudio = [currAssessmentActivityStep QuestionAudio];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        AnswerOptions =[[NSMutableArray alloc] init];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        AnswerOption1EnglishAudio = [currAssessmentActivityStep Answer1Audio];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        AnswerOption2EnglishAudio = [currAssessmentActivityStep Answer2Audio];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        AnswerOption3EnglishAudio = [currAssessmentActivityStep Answer3Audio];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        AnswerOption4EnglishAudio = [currAssessmentActivityStep Answer4Audio];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    nextButton.hidden =true;
    
    ChapterTitleLabel.text = ChapterTitle;
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

-(IBAction)PlayQuestionAudioPressed:(id)sender
{
    
}

-(IBAction)PlayAnswer1AudioPressed:(id)sender
{
    
}

-(IBAction)PlayAnswer2AudioPressed:(id)sender
{
    
}

-(IBAction)PlayAnswer3AudioPressed:(id)sender
{
    
}

-(IBAction)PlayAnswer4AudioPressed:(id)sender
{
    
}

- (IBAction)NextButtonPressed:(id)sender {
    //move to next question -> load next set of question paramters
    //reset table row colors
    //hide next button
    //[self loadNextAssessmentActivityQuestion];
    currentAssessmentActivityStep++;
    
    if(currentAssessmentActivityStep<=totalAssessmentActivitySteps)
    {
        nextButton.hidden = true;
        
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
            tempCell.backgroundView.alpha = 1;
            tempCell.alpha = 1;
            tempCell.accessoryType = UITableViewCellAccessoryNone;
            i++;
        }
        
        [AnswerList reloadData];
        
    }
    else
    {
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
                        //tempCell.contentView.alpha=.2;
                        //tempCell.backgroundColor = [UIColor grayColor];
                        //tempCell.alpha =.2;
                        
                    }
                    else{
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.backgroundColor= [UIColor blueColor];
                        nextButton.hidden = false;
                    }
                    i++;
                
                }
                
                //show next button
            }
            else
            {
                //gray out option
                //cell.contentView.alpha=.2;
                cell.backgroundColor = [UIColor lightGrayColor];
                cell.backgroundView.alpha = .2;
                //cell.alpha =.2;
            }
     }
    
    [tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
    //AssessmentArrray *question = [questions objectAtIndex:section];
    return [NSString stringWithFormat:@"%d. %@", questionNum,Question];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *myLabel = [[UILabel alloc]init];
    myLabel.frame = CGRectMake(5, 0, 791, 62);
    myLabel.font = [UIFont boldSystemFontOfSize:18];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    UIView *headerView = [[UIView alloc]init];
    headerView.backgroundColor = [UIColor lightTextColor];
    [headerView addSubview:myLabel];
    
    return headerView;
}

@end
