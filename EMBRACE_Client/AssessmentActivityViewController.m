//
//  AssessmentActivityViewController.m
//  EMBRACE
//
//  Created by James Rodriguez on 12/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "AssessmentActivityViewController.h"
#import "ConditionSetup.h"
#import "ServerCommunicationController.h"
#import "LibraryViewController.h"
#import "AssessmentContext.h"

@interface AssessmentActivityViewController () {
    ConditionSetup *conditionSetup;
    AssessmentContext *assessmentContext;
}

@property (nonatomic, strong) PlayAudioFile *playaudioClass;

@property (nonatomic, weak) UIViewController *libraryView;                      //Local instance of the library view controller

//Context variables
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *currentPage;
@property (nonatomic, copy) NSString *currentSentence;
@property (nonatomic, copy) NSString *currentStep;

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
NSString *correctSelection;             //correct Selection text
NSMutableDictionary *assessmentActivities;          //the total assessment activity steps details
NSMutableArray *currentAssessmentActivitySteps;     //the current assessment activity step details
NSInteger totalAssessmentActivitySteps;             //the total assessment activity steps
NSInteger currentAssessmentActivityStep;            //the current assessment activity step
NSInteger numAttemptsPerQuestion = 1;
NSInteger numCurrentAttempts = 0;

UIImage *BackgroundImage;   //The background image related to the story

@implementation AssessmentActivityViewController
@synthesize AnswerList;
@synthesize transparentLayer;
@synthesize nextButton;



- (id)initWithModel:(InteractionModel *)model :(UIViewController *)libraryViewController :(UIImage *)backgroundImage :(NSString *)bookTitle :(NSString *)chapterTitle :(NSString *)currentPage :(NSString *)currentSentence :(NSString *)currentStep {
    self = [super init];
    
    if (self) {
        //Local instance of library view controller
        self.libraryView = libraryViewController;
        
        conditionSetup = [ConditionSetup sharedInstance];
        
        //Context variables for logging
        self.bookTitle = bookTitle;
        self.chapterTitle = chapterTitle;
        self.currentPage = currentPage;
        self.currentSentence = currentSentence;
        self.currentStep = currentStep;
        
        assessmentContext = [[AssessmentContext alloc] init];
        [self setAssessmentContext];
        
        //Local instance of background image for story
        BackgroundImage = backgroundImage;
        
        //Instantiate current assessment step
        currentAssessmentActivityStep = 1;
        assessmentContext.assessmentStepNumber = currentAssessmentActivityStep;
        
        [[ServerCommunicationController sharedInstance] logLoadAssessmentStep:currentAssessmentActivityStep context:assessmentContext];
        
        //Instantiate answer selection array
        AnswerList.backgroundColor = [UIColor clearColor];
        AnswerList.backgroundView.backgroundColor = [UIColor clearColor];
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        //Load the assessment activity for the current chapter
        assessmentActivities =  [model getAssessmentActivity];
        if(conditionSetup.assessmentMode == ENDOFBOOK){
            currentAssessmentActivitySteps = [assessmentActivities objectForKey:bookTitle];
        }
        else if(conditionSetup.assessmentMode == ENDOFCHAPTER){
            currentAssessmentActivitySteps = [assessmentActivities objectForKey:chapterTitle];
        }
        else{
            //TODO: Log fatal error and return to library view to prevent system crash
        }
        totalAssessmentActivitySteps = [currentAssessmentActivitySteps count];
        AssessmentActivity *currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep - 1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        
        //Set the current question, question number and answer options with their audio file names
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
        
        [[ServerCommunicationController sharedInstance] logDisplayAssessmentQuestion:Question withOptions:AnswerOptions context:assessmentContext];
        
        self.playaudioClass = [[PlayAudioFile alloc] init];
    }
    
    return self;
}

/*
 * Randomizer function that randomizes the answer options
 */
- (void)shuffleAnswers {
    NSUInteger count = [AnswerOptions count];
    
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
        [AnswerOptions exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
        [AnswerAudios exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%@ %@",self.chapterTitle, self.bookTitle);
    //Set up design
    nextButton.hidden = true;
    self.view.backgroundColor = [UIColor colorWithRed:165.0/255.0 green:203.0/255.0 blue:231.0/255.0 alpha:1.0];
    transparentLayer.backgroundColor = [UIColor whiteColor];
    transparentLayer.alpha = .5;
    AnswerList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //Hide the navigation bar to force completion
    self.navigationController.navigationBar.hidden = YES;
    
    if ([self.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
        
        self.playaudioClass = [[PlayAudioFile alloc]init];
        [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script_C12.mp3"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if (self.playaudioClass) {
        [self.playaudioClass stopPlayAudioFile];
    }
    self.playaudioClass = nil;
    [super viewWillDisappear:animated];

}


//Not being used currently may delete
- (void)loadNextAssessmentActivityQuestion{
    currentAssessmentActivityStep++;
    
    //If there are more questions load the next question
    if (currentAssessmentActivityStep<totalAssessmentActivitySteps) {
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        AssessmentActivity *currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep - 1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        questionNum = [currAssessmentActivityStep QuestionNumber];
        [AnswerOptions removeAllObjects];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer1]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer2]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer3]];
        [AnswerOptions addObject:[currAssessmentActivityStep Answer4]];
    }
    //Return to the library view
    else {
        self.navigationController.navigationBar.hidden = NO;
        [[ServerCommunicationController sharedInstance] createNewLogFile];
        [super.navigationController popViewControllerAnimated:YES]; //return to library view
    }
}

/*
 * Play Audio functions that will play the matching text in english or spanish
 */
- (IBAction)PlayQuestionAudioPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logTapAssessmentAudioButton:Question buttonType:@"Question" context:assessmentContext];
    
    [self.playaudioClass playAudioFile:self :QuestionAudio];
    
    [[ServerCommunicationController sharedInstance] logPlayAssessmentAudio:[QuestionAudio stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Play Question Audio" :assessmentContext];
}

- (IBAction)PlayAnswer1AudioPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logTapAssessmentAudioButton:AnswerOptions[0] buttonType:@"Answer Option" context:assessmentContext];
    
    [self.playaudioClass playAudioFile:self :AnswerAudios[0]];
    
    [[ServerCommunicationController sharedInstance] logPlayAssessmentAudio:[AnswerAudios[0] stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Play Answer Audio" :assessmentContext];
}

- (IBAction)PlayAnswer2AudioPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logTapAssessmentAudioButton:AnswerOptions[1] buttonType:@"Answer Option" context:assessmentContext];
    
    [self.playaudioClass playAudioFile:self :AnswerAudios[1]];
    
    [[ServerCommunicationController sharedInstance] logPlayAssessmentAudio:[AnswerAudios[1] stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Play Answer Audio" :assessmentContext];
}

- (IBAction)PlayAnswer3AudioPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logTapAssessmentAudioButton:AnswerOptions[2] buttonType:@"Answer Option" context:assessmentContext];
    
    [self.playaudioClass playAudioFile:self :AnswerAudios[2]];
    
    [[ServerCommunicationController sharedInstance] logPlayAssessmentAudio:[AnswerAudios[2] stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Play Answer Audio" :assessmentContext];
}

- (IBAction)PlayAnswer4AudioPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logTapAssessmentAudioButton:AnswerOptions[3] buttonType:@"Answer Option" context:assessmentContext];
    
    [self.playaudioClass playAudioFile:self :AnswerAudios[3]];
    
    [[ServerCommunicationController sharedInstance] logPlayAssessmentAudio:[AnswerAudios[3] stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Play Answer Audio" :assessmentContext];
}

/*
 * Swipe gesture. Only recognizes a downwards two finger swipe. Used to skip to the next assessment question
 */
- (IBAction)swipeGesturePerformed:(UISwipeGestureRecognizer *)recognizer {
    [[ServerCommunicationController sharedInstance] logAssessmentEmergencySwipe:assessmentContext];
    
    [self NextButtonPressed:self];
}

/*
 * Increments the next question, resets the visual aspects of the question and answer options,
 */
- (IBAction)NextButtonPressed:(id)sender {
    [[ServerCommunicationController sharedInstance] logPressNextInAssessmentActivity:assessmentContext];
    
    //Increment the current Assessment activity step
    currentAssessmentActivityStep++;
    
    assessmentContext.assessmentStepNumber = currentAssessmentActivityStep;
    [[ServerCommunicationController sharedInstance] logLoadAssessmentStep:currentAssessmentActivityStep context:assessmentContext];
    
    //If there are more questions
    if (currentAssessmentActivityStep <= totalAssessmentActivitySteps) {
        //Disable next button
        nextButton.hidden = true;
        
        //Reset selected answers to unselected
        AnswerSelection[0] = 0;
        AnswerSelection[1] = 0;
        AnswerSelection[2] = 0;
        AnswerSelection[3] = 0;
        
        //Load the next assessment activity step
        AssessmentActivity *currAssessmentActivityStep = [currentAssessmentActivitySteps objectAtIndex:currentAssessmentActivityStep - 1];
        correctSelection = [currAssessmentActivityStep expectedSelection];
        Question = [currAssessmentActivityStep QuestionText];
        QuestionAudio = [currAssessmentActivityStep QuestionAudio];
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
        
        for (int i = 0; i < [AnswerOptions count]; i++) {
            UITableViewCell *tempCell = [AnswerList cellForRowAtIndexPath:cells[i]];
            tempCell.contentView.alpha = 1;
            tempCell.backgroundColor = [UIColor clearColor];
            tempCell.backgroundView.alpha = .5;
            tempCell.backgroundView.backgroundColor = [UIColor clearColor];
            tempCell.alpha = .5;
            tempCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        numCurrentAttempts = 0;
        
        [AnswerList reloadData];
        
        [[ServerCommunicationController sharedInstance] logDisplayAssessmentQuestion:Question withOptions:AnswerOptions context:assessmentContext];
    }
    //Return to the library view
    else {
        [[ServerCommunicationController sharedInstance] logCompleteAssessment:assessmentContext];
        [[ServerCommunicationController sharedInstance] studyContext].condition = @"NULL";
        
        //Set chapter as completed
        [[(LibraryViewController *)self.libraryView studentProgress] setStatusOfChapter:self.chapterTitle :COMPLETED fromBook:self.bookTitle];
        
        self.navigationController.navigationBar.hidden = NO;
        [[ServerCommunicationController sharedInstance] createNewLogFile];
        [self.navigationController popToViewController:self.libraryView animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//Default 4 answer options
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

//Set the answer option text for each row
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier =  [NSString stringWithFormat:@"MyCell%d", [indexPath row]];
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    }
    
    int row = [indexPath row];
    cell.textLabel.text = AnswerOptions[row];
    
    return cell;
}

/*
 * If the user selects the correct answer highlight the answer and make the next button appear, otherwise
 * show the answer as incorrect.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Checks if option has already been selected else do nothing
    if (AnswerSelection[[indexPath row]] == 0) {
        AnswerSelection[[indexPath row]] = 1;
        numCurrentAttempts++;
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSArray<NSIndexPath *> *indexPaths = [tableView indexPathsForVisibleRows];

        [[ServerCommunicationController sharedInstance] logSelectAssessmentAnswer:cell.textLabel.text context:assessmentContext];
        
        if(numCurrentAttempts <= numAttemptsPerQuestion && [cell.textLabel.text isEqualToString:correctSelection]){
            
                [[ServerCommunicationController sharedInstance] logVerification:true forAssessmentAnswer:cell.textLabel.text context:assessmentContext];
                
                //Gray out other options
                for (int i = 0; i < [AnswerOptions count]; i++) {
                    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPaths[i]];
                    if ([AnswerOptions[i] isEqualToString:correctSelection]) {
                        UIColor *LightBlueColor = [UIColor colorWithRed:135.0/255.0 green:180.0/255.0 blue:225.0/255.0 alpha:1.0];
                        tempCell.accessoryType = UITableViewCellAccessoryCheckmark;
                        tempCell.backgroundColor = LightBlueColor;
                        nextButton.hidden = false;
                    }
                    else {
                        //Gray out option
                        AnswerSelection[i] = 1;
                        tempCell.backgroundColor = [UIColor lightGrayColor];
                        tempCell.backgroundView.alpha = .2;
                    }
                }
        }
        else if(numCurrentAttempts < numAttemptsPerQuestion && ![cell.textLabel.text isEqualToString:correctSelection]){
            [[ServerCommunicationController sharedInstance] logVerification:false forAssessmentAnswer:cell.textLabel.text context:assessmentContext];
            
            //Gray out option
            cell.backgroundColor = [UIColor lightGrayColor];
            cell.backgroundView.alpha = .2;
        }
        else if(numCurrentAttempts >= numAttemptsPerQuestion && ![cell.textLabel.text isEqualToString:correctSelection]){
            [[ServerCommunicationController sharedInstance] logVerification:false forAssessmentAnswer:cell.textLabel.text context:assessmentContext];
            
            //Gray out other options
            for (int i = 0; i < [AnswerOptions count]; i++) {
                UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPaths[i]];
                if ([AnswerOptions[i] isEqualToString:correctSelection]) {
                    UIColor *LightBlueColor = [UIColor colorWithRed:135.0/255.0 green:180.0/255.0 blue:225.0/255.0 alpha:1.0];
                    tempCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    tempCell.backgroundColor = LightBlueColor;
                    nextButton.hidden = false;
                }
                else {
                    //Gray out option
                    AnswerSelection[i] = 1;
                    tempCell.backgroundColor = [UIColor lightGrayColor];
                    tempCell.backgroundView.alpha = .2;
                }
            }
        }
        
    }
    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *text = [NSString stringWithFormat:@"%d. %@      ", questionNum, Question];
    UIFont *font = [UIFont fontWithName:@"GillSans" size:22];
  
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    CGRect frame = CGRectInset(view.frame, 15, 0);
    frame.size.height = 200;
    UILabel *myLabel = [[UILabel alloc] initWithFrame:frame];
    [myLabel setFont:font];
    [myLabel setText:text];
    myLabel.numberOfLines = 10;
    float height = [myLabel.text
                     boundingRectWithSize:myLabel.frame.size
                     options:NSStringDrawingUsesLineFragmentOrigin
                     attributes:@{ NSFontAttributeName:font }
                     context:nil].size.height;
    frame.size.height = height + 20;
    myLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.frame = CGRectMake(0, 0, tableView.frame.size.width, height + 20);
    myLabel.frame = frame;
    
    [view addSubview:myLabel];
    return view;
}

- (void)setAssessmentContext {
    assessmentContext.bookTitle = self.bookTitle;
    assessmentContext.chapterTitle = self.chapterTitle;
    assessmentContext.assessmentStepNumber = currentAssessmentActivityStep;
}

@end
