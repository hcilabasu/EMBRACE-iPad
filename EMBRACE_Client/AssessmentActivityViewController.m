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
NSMutableArray *AnswerAudios;
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
NSString* correctSelection;
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

UIImage *BackgroundImage;

@implementation AssessmentActivityViewController
@synthesize AnswerList;
@synthesize transparentLayer;
@synthesize nextButton;
//@synthesize model;
@synthesize ChapterTitle;
@synthesize playAudioFileClass;

- (id)initWithModel:(InteractionModel*) model : (UIViewController*) libraryViewController : (UIImage*) backgroundImage : (NSString*) bookTitle : (NSString*) chapterTitle : (NSString*) currentPage : (NSString*)currentSentence :(NSString*) currentStep
{
    self=[super init];//self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
        libraryView=libraryViewController;
        
        //context variables for logging
        BookTitle = bookTitle;
        CurrentPage = currentPage;
        CurrentSentence=currentSentence;
        CurrentStep = currentStep;
        
        BackgroundImage = backgroundImage;
        
        currentAssessmentActivityStep = 1;
        
        // Custom initialization
        //AnswerList = [[UITableView alloc]init];
        AnswerList.backgroundColor = [UIColor clearColor];
        AnswerList.backgroundView.backgroundColor = [UIColor clearColor];
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
        AnswerAudios = [[NSMutableArray alloc] init];
        
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer1Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer2Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer3Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer4Audio]];
        
        [self shuffleAnswers];
        
        playAudioFileClass = [[PlayAudioFile alloc]init];
        
        //log loading assessment activity
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Start Assessment" :BookTitle :ChapterTitle : @"1"];
        
    }
    return self;
}

-(void)shuffleAnswers{
    NSUInteger count = [AnswerOptions count];
    for (NSUInteger i=0; i<count; ++i) {
        NSInteger remainingCount = count-i;
        NSInteger exchangeIndex = i+ arc4random_uniform((u_int32_t)remainingCount);
        [AnswerOptions exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
        [AnswerAudios exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    nextButton.hidden =true;
    self.view.backgroundColor = [UIColor colorWithRed: 165.0/255.0 green: 203.0/255.0 blue:231.0/255.0 alpha: 1.0];
    transparentLayer.backgroundColor = [UIColor whiteColor];
    transparentLayer.alpha = .5;
    AnswerList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.automaticallyAdjustsScrollViewInsets = NO;
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
    [playAudioFileClass playAudioFile:self:QuestionAudio];
}

-(IBAction)PlayAnswer1AudioPressed:(id)sender
{
    [playAudioFileClass playAudioFile:self:AnswerAudios[0]];
}

-(IBAction)PlayAnswer2AudioPressed:(id)sender
{
    [playAudioFileClass playAudioFile:self:AnswerAudios[1]];
}

-(IBAction)PlayAnswer3AudioPressed:(id)sender
{
    [playAudioFileClass playAudioFile:self:AnswerAudios[2]];
}

-(IBAction)PlayAnswer4AudioPressed:(id)sender
{
    [playAudioFileClass playAudioFile:self:AnswerAudios[3]];
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
        QuestionAudio =[currAssessmentActivityStep QuestionAudio];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        [AnswerOptions removeAllObjects];
        [AnswerAudios removeAllObjects];
        
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer1Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer2Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer3Audio]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
        [AnswerAudios addObject:[currAssessmentActivityStep Answer4Audio]];
        
        [self shuffleAnswers];
        
        //reset tableview cells, reload tableview
        NSArray *cells = [AnswerList indexPathsForVisibleRows];
        
        for (int i=0; i<[AnswerOptions count]; i++)
        {
            UITableViewCell *tempCell = [AnswerList cellForRowAtIndexPath:cells[i]];
            tempCell.contentView.alpha = 1;
            tempCell.backgroundColor = [UIColor clearColor];
            tempCell.backgroundView.alpha = .5;
            tempCell.backgroundView.backgroundColor = [UIColor clearColor];
            tempCell.alpha = .5;
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
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
        //AnswerList.alpha = 0;
        
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
            if([cell.textLabel.text isEqualToString: correctSelection])
            {
                //log correct answer selected
                [[ServerCommunicationController sharedManager] logComputerAssessmentAnswerVerification:true : Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
                
                //[playAudioFileClass textToSpeech:@"Good Job!"];
                
                //gray out other options
                
                for(int i=0;i<[AnswerOptions count];i++)
                {
                    
                    if ([AnswerOptions[i] isEqualToString:correctSelection]) {
                        UIColor *LightBlueColor = [UIColor colorWithRed: 135.0/255.0 green: 180.0/255.0 blue:225.0/255.0 alpha: 1.0];
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.backgroundColor= LightBlueColor;
                        nextButton.hidden = false;
                    }
                    else{
                        //gray out option
                        
                        //UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:cells[i]];
                        AnswerSelection[i] = 1;
                        //tempCell.contentView.alpha=.2;
                        //tempCell.backgroundColor = [UIColor grayColor];
                        //tempCell.alpha =.2;
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
    return [NSString stringWithFormat:@"%d. %@      ", questionNum,Question];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.font = [UIFont fontWithName:@"GillSans" size:22];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
}

/*
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    
    [myLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [myLabel setText:[self tableView:tableView titleForHeaderInSection:section]];
    [view addSubview:myLabel];
    
    //UILabel *chapterTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, tableView.frame.size.width, 22)];
    //chapterTitle.center = CGPointMake(tableView.frame.size.width  / 2, 0);
    //[chapterTitle setFont:[UIFont boldSystemFontOfSize:20]];
    //[chapterTitle setText:ChapterTitle];
    //[view addSubview:chapterTitle];
    
    return view;
}
 */

@end
