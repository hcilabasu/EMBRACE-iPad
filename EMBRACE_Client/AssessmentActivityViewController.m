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


NSInteger AnswerSelection[4];           //Array of answers selected
NSMutableArray *AnswerOptions;          //Array of Answer options
NSMutableArray *AnswerAudios;           //Array of Answer Audio file names
NSString *AnswerOption1EnglishAudio;    //English Audio file for Answer 1
NSString *AnswerOption1SpanishAudio;    //Spanish Audio file for Answer 1
NSString *AnswerOption2EnglishAudio;    //English Audio file for Answer 2
NSString *AnswerOption2SpanishAudio;    //Spanish Audio file for Answer 2
NSString *AnswerOption3EnglishAudio;    //English Audio file for Answer 3
NSString *AnswerOption3SpanishAudio;    //Spanish Audio file for Answer 3
NSString *AnswerOption4EnglishAudio;    //English Audio file for Answer 4
NSString *AnswerOption4SpanishAudio;    //Spanish Audio file for Answer 4
NSString *Question;                     //Question Text
NSString *QuestionAudio;                //Question audio file name
NSInteger questionNum;                  //Current Question Number
NSString* correctSelection;             //correct Selection text
NSMutableDictionary *assessmentActivities;          //the total assessment activity steps details
NSMutableArray *currentAssessmentActivitySteps;     //the current assessment activity step details
NSInteger totalAssessmentActivitySteps;             //the total assessment activity steps
NSInteger currentAssessmentActivityStep;            //the current assessment activity step
UIViewController *libraryView;                      //Local instance of the library view controller

//Context variables
NSString *BookTitle;
NSString *CurrentPage;
NSString *CurrentSentence;
NSString *CurrentStep;

UIImage *BackgroundImage;   //The background image related to the story

@implementation AssessmentActivityViewController
@synthesize AnswerList;
@synthesize transparentLayer;
@synthesize nextButton;
//@synthesize model;
@synthesize ChapterTitle;
@synthesize playAudioFileClass;

- (id)initWithModel:(InteractionModel*) model : (UIViewController*) libraryViewController : (UIImage*) backgroundImage : (NSString*) bookTitle : (NSString*) chapterTitle : (NSString*) currentPage : (NSString*)currentSentence :(NSString*) currentStep
{
    self=[super init];
    if (self) {
        
        //local instance of library view controller
        libraryView=libraryViewController;
        
        //context variables for logging
        BookTitle = bookTitle;
        ChapterTitle =chapterTitle;
        CurrentPage = currentPage;
        CurrentSentence=currentSentence;
        CurrentStep = currentStep;
        
        //local instance of background image for story
        BackgroundImage = backgroundImage;
        
        //Instantiate current assessment step
        currentAssessmentActivityStep = 1;
        
        //Instantiate answer selection array
        AnswerList.backgroundColor = [UIColor clearColor];
        AnswerList.backgroundView.backgroundColor = [UIColor clearColor];
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        //Load the assessment activity for the current chapter
        assessmentActivities =  [model getAssessmentActivity];
        currentAssessmentActivitySteps = [assessmentActivities objectForKey:chapterTitle];
        totalAssessmentActivitySteps = [currentAssessmentActivitySteps count];
        AssessmentActivity* currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep-1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        
        /*Set the current question, question number and answer options with their
        audio file names*/
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
        
        //Randomizes answer options
        [self shuffleAnswers];
        
        playAudioFileClass = [[PlayAudioFile alloc]init];
        
        //log loading assessment activity
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Start Assessment" :BookTitle :ChapterTitle : @"1"];
        
    }
    return self;
}

/*
 Randomizer function that randomizes the answer options
 */
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
    
    //Set up design
    nextButton.hidden =true;
    self.view.backgroundColor = [UIColor colorWithRed: 165.0/255.0 green: 203.0/255.0 blue:231.0/255.0 alpha: 1.0];
    transparentLayer.backgroundColor = [UIColor whiteColor];
    transparentLayer.alpha = .5;
    AnswerList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //Hide the navigation bar to force completion
    self.navigationController.navigationBar.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//not being used currently may delete
-(void)loadNextAssessmentActivityQuestion{
    
    currentAssessmentActivityStep++;
    
    //If there are more questions load the next question
    if(currentAssessmentActivityStep<totalAssessmentActivitySteps)
    {
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
    //return to the library view
    else
    {
        //log end of assessment activity
        self.navigationController.navigationBar.hidden = NO;
        [super.navigationController popViewControllerAnimated:YES]; //return to library view
    }
}


/*
 Play Audio functions that will play the matching text in english or spanish
 */
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

/*
 *  Increments the next question, resets the visual aspects of the question and answer options,
 */
- (IBAction)NextButtonPressed:(id)sender {
    
    //log user pressed next button
    [[ServerCommunicationController sharedManager] logUserAssessmentPressedNext:@"Next" :@"Next Assessment" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",  currentAssessmentActivityStep]];
    
    //Increment the current Assessment activity step
    currentAssessmentActivityStep++;
    
    //if there are more questions
    if(currentAssessmentActivityStep<=totalAssessmentActivitySteps)
    {
        //Log Automatic computer action: Next Assessment
        [[ServerCommunicationController sharedManager] logComputerAssessmentLoadNextActivityStep:@"Next" :@"Next Assessment" :[NSString stringWithFormat:@"%d", (currentAssessmentActivityStep-1)] :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep] :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",(currentAssessmentActivityStep-1)]];
        
        //Disable next button
        nextButton.hidden = true;
        
        //Reset selected answers to unselected
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        //Load the next assessment activity step
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
        
        //Randomize answer options
        [self shuffleAnswers];
        
        //reset tableview cells and reload tableview to be unselected
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
        
        //log Automatic computer step: Display assessment activity
        [[ServerCommunicationController sharedManager] logComputerAssessmentDisplayStep:Question :AnswerOptions :@"Next" :@"Display Assessment" :BookTitle :ChapterTitle : [NSString stringWithFormat:@"%d", currentAssessmentActivityStep]];
        
    }
    //return to the library view
    else
    {
        //log end of assessment and return to library view
        [[ServerCommunicationController sharedManager] logComputerAssessmentLoadNextActivityStep:@"Next" :@"End Assessment" :[NSString stringWithFormat:@"%d", (currentAssessmentActivityStep-1)] :@"End of Assessment" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",(currentAssessmentActivityStep-1)]];
        
        //Set chapter as completed
        NSRange titleRange = [BookTitle rangeOfString:@" - Unknown"];
        [[(LibraryViewController*) libraryView studentProgress] setStatusOfChapter:ChapterTitle :COMPLETED fromBook:[BookTitle substringToIndex:titleRange.location]];
        
        self.navigationController.navigationBar.hidden = NO;
        [self.navigationController popToViewController:libraryView animated:YES];
    }
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//Default 4 answer options
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

//set the answer option text for each row
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier =  [NSString stringWithFormat:@"MyCell%d", [indexPath row]];
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell==nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    }
    
    int row = [indexPath row];
    cell.textLabel.text = AnswerOptions[row];
    
    return cell;
}

/*
 *  If the user selects the correct answer highlight the answer and make the next button appear, otherwise
 *  show the answer as incorrect.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //checks if option has already been selected else do nothing
    if (AnswerSelection[[indexPath row]] == 0) {
     
            AnswerSelection[[indexPath row]] =1;
     
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        //log user pressed answer option
        [[ServerCommunicationController sharedManager] logUserAssessmentPressedAnswerOption:Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d",currentAssessmentActivityStep] : cell.textLabel.text];
        
            //checks if option is correct else gray out
            if([cell.textLabel.text isEqualToString: correctSelection])
            {
                //log correct answer selected
                [[ServerCommunicationController sharedManager] logComputerAssessmentAnswerVerification:true : Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep] : cell.textLabel.text];
                
                
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
                        AnswerSelection[i] = 1;
                    }
                }
                
            }
            else
            {
                //log incorrect answer selected
                [[ServerCommunicationController sharedManager] logComputerAssessmentAnswerVerification:false : Question :([indexPath row]+1) :AnswerOptions :@"Answer Option" :@"Verification" :BookTitle :ChapterTitle :[NSString stringWithFormat:@"%d", currentAssessmentActivityStep] : cell.textLabel.text];
                
                //gray out option
                cell.backgroundColor = [UIColor lightGrayColor];
                cell.backgroundView.alpha = .2;
            }
     }
    
    [tableView reloadData];
}

//Add the quesiton number and text
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
    return [NSString stringWithFormat:@"%d. %@      ", questionNum,Question];
}

//Custom field to change the font style and size of the header
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
