//
//  AssessmentActivityViewController.m
//  EMBRACE
//
//  Created by James Rodriguez on 12/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "AssessmentActivityViewController.h"
#import "ServerCommunicationController.h"

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

//Context variables
NSString *BookTitle;
NSString *CurrentPage;
NSString *CurrentSentence;
NSString *CurrentStep;

@implementation AssessmentActivityViewController
@synthesize AnswerList;
@synthesize nextButton;
@synthesize ChapterTitleLabel;
//@synthesize model;
@synthesize ChapterTitle;
@synthesize playAudioFileClass;

- (id)initWithModel:(InteractionModel*) model : (UIViewController*) libraryViewController : (NSString*) bookTitle : (NSString*) chapterTitle : (NSString*) currentPage : (NSString*)currentSentence :(NSString*) currentStep
{
    self=[super init];//self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        libraryView=libraryViewController;
        
        //context variables for logging
        BookTitle = bookTitle;
        CurrentPage = currentPage;
        CurrentSentence=currentSentence;
        CurrentStep = currentStep;
        
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
        
        playAudioFileClass = [[PlayAudioFile alloc]init];
        
        //log loading assessment activity
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Start Assessment" :BookTitle :ChapterTitle : @"1"];
        
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

//not being used currently may delete
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
        
        //log load next assessment activity step
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Display Assessment" :BookTitle :ChapterTitle : [NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
        
    }
    else
    {
        //log end of assessment activity
        
        [super.navigationController popViewControllerAnimated:YES]; //return to library view
    }
}


//log user pressed play audio
-(IBAction)PlayQuestionAudioPressed:(id)sender
{
    //[playAudioFileClass playAudioFile:QuestionAudio];
    [playAudioFileClass textToSpeech:Question];//Question:BookTitle:ChapterTitle:CurrentPage:CurrentSentence:CurrentStep];
}

-(IBAction)PlayAnswer1AudioPressed:(id)sender
{
    //[playAudioFileClass playAudioFile:AnswerOption1EnglishAudio];
    [playAudioFileClass textToSpeech:AnswerOptions[0]];
}

-(IBAction)PlayAnswer2AudioPressed:(id)sender
{
    //[playAudioFileClass playAudioFile:AnswerOption2EnglishAudio];
    [playAudioFileClass textToSpeech:AnswerOptions[1]];
}

-(IBAction)PlayAnswer3AudioPressed:(id)sender
{
    //[playAudioFileClass playAudioFile:AnswerOption3EnglishAudio];
    [playAudioFileClass textToSpeech:AnswerOptions[2]];
}

-(IBAction)PlayAnswer4AudioPressed:(id)sender
{
    //[playAudioFileClass playAudioFile:AnswerOption4EnglishAudio];
    [playAudioFileClass textToSpeech:AnswerOptions[3]];
}

- (IBAction)NextButtonPressed:(id)sender {
    
    //[self loadNextAssessmentActivityQuestion];
    
    //log user pressed next button
    [[ServerCommunicationController sharedManager] logUserAssessmentPressedNext:@"Next" :@"Next Assessment" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",  currentAssessmentActivityStep]];
    
    currentAssessmentActivityStep++;
    
    if(currentAssessmentActivityStep<=totalAssessmentActivitySteps)
    {
        [[ServerCommunicationController sharedManager] logComputerAssessmentLoadNextActivityStep:@"Next" :@"Next Assessment" :[NSString stringWithFormat:@"%d", (currentAssessmentActivityStep-1)] :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep] :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",(currentAssessmentActivityStep-1)]];
        
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
        
        for (int i=0; i<[AnswerOptions count]; i++)
        {
            UITableViewCell *tempCell = [AnswerList cellForRowAtIndexPath:cells[i]];
            tempCell.contentView.alpha = 1;
            tempCell.backgroundColor = [UIColor whiteColor];
            tempCell.backgroundView.alpha = 1;
            tempCell.alpha = 1;
            tempCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [AnswerList reloadData];
        
        //log Display assessment activity
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Display Assessment" :BookTitle :ChapterTitle : [NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
        
    }
    else
    {
        //log return to library ie log end of assessment
        [[ServerCommunicationController sharedManager] logComputerAssessmentLoadNextActivityStep:@"Next" :@"End Assessment" :[NSString stringWithFormat:@"%d", (currentAssessmentActivityStep-1)] :@"End of Assessment" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",(currentAssessmentActivityStep-1)]];
        
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
     
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        //log user pressed answer option
        [[ServerCommunicationController sharedManager] logUserAssessmentPressedAnswerOption:Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",currentAssessmentActivityStep]];
        
            //checks if option is correct else gray out
            if(([indexPath row]+1) == correctSelection)
            {
                //log correct answer selected
                [[ServerCommunicationController sharedManager] logComputerAssessmentAnswerVerification:true : Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
                
                //[playAudioFileClass textToSpeech:@"Good Job!"];
                
                //gray out other options
                
                for(int i=0;i<[AnswerOptions count];i++)
                {
                    
                    if (i!=(correctSelection-1)) {
                        //gray out option
                        
                        //UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:cells[i]];
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
                }
                
            }
            else
            {
                //log incorrect answer selected
                [[ServerCommunicationController sharedManager] logComputerAssessmentAnswerVerification:false : Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
                
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
