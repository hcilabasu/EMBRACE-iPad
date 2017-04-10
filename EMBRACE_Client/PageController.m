//
//  PageController.m
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "PageController.h"
#import "LibraryViewController.h"

@implementation PageController
@synthesize mvc;
@synthesize pageContext;
@synthesize stepContext;
@synthesize sentenceContext;
@synthesize manipulationContext;
@synthesize conditionSetup;
//@synthesize model;
//@synthesize book;
@synthesize bookImporter;
@synthesize bookTitle;
@synthesize chapterTitle;
@synthesize manipulationView;
@synthesize animatingObjects;
//@synthesize allowInteractions;

-(id)initWithController:(ManipulationViewController *) superMvc {
    self = [super init];
    
    if (self) {
        //Create local Pointers to needed classes, variables and properties within mvc
        self.mvc = superMvc;
        self.pageContext = mvc.pageContext;
        self.stepContext = mvc.stepContext;
        self.sentenceContext = mvc.sentenceContext;
        //self.model = mvc.model;
        self.conditionSetup = mvc.conditionSetup;
        self.manipulationContext = mvc.manipulationContext;
        //self.book = mvc.book;
        self.bookImporter = mvc.bookImporter;
        self.bookTitle = mvc.bookTitle;
        self.chapterTitle = mvc.chapterTitle;
        self.manipulationView = mvc.manipulationView;
        self.animatingObjects = mvc.animatingObjects;
    }
    
    return self;
}

/*
 * Gets the book reference for the book that's been opened.
 * Also sets the reference to the interaction model of the book.
 * Sets the page to the one for the current chapter activity.
 * Calls the function to load the html content for the activity.
 */
- (void)loadFirstPage {
    mvc.book = [bookImporter getBookWithTitle:bookTitle]; //Get the book reference.
    mvc.model = [mvc.book model];
    
    pageContext.currentPage = [mvc.book getNextPageForChapterAndActivity:chapterTitle : conditionSetup.currentMode :nil];

    if (!conditionSetup.isVocabPageEnabled && [pageContext.currentPage containsString:DASH_INTRO]) {
        sentenceContext.currentSentence = 1;
        pageContext.currentPage = [mvc.book getNextPageForChapterAndActivity:chapterTitle :((conditionSetup.currentMode == IM_MODE || conditionSetup.currentMode == ITSIM_MODE) ? PM_MODE : conditionSetup.currentMode) :pageContext.currentPage];
    }
    
    pageContext.actualPage = pageContext.currentPage;
    
    [self loadPage];
}

/*
 * Loads the html content and solution steps for the current page.
 */
- (void)loadPage {
    
    mvc.animatingObjects = [[NSMutableDictionary alloc] init];
    animatingObjects = mvc.animatingObjects;
    [manipulationView loadPageFor:mvc.book andCurrentPage:pageContext.currentPage];
    mvc.title = chapterTitle;
    
    //Set the current page id
    pageContext.currentPageId = [mvc.book getIdForPageInChapterAndActivity:pageContext.currentPage :chapterTitle :conditionSetup.currentMode];
    
    [mvc setManipulationContext];
    
    NSString *pageLanguage = [pageContext.currentPage containsString:@"S.xhtml"] ? SPANISH_TXT : ENGLISH_TXT;
    manipulationContext.pageLanguage = pageLanguage;
    
    if (conditionSetup.appMode == ITS && conditionSetup.useKnowledgeTracing && ![chapterTitle isEqualToString:@"The Naughty Monkey"]) {
        // Set the complexity level at the beginning of the chapter (except for the first chapter of the story)
        if (manipulationContext.chapterNumber > 1 && [pageContext.currentPageId rangeOfString:PM1].location != NSNotFound) {
            EMComplexity prevComplexity = [[ITSController sharedInstance] getCurrentComplexity];
            [[ITSController sharedInstance] setCurrentComplexity];
            EMComplexity newComplexity = [[ITSController sharedInstance] getCurrentComplexity];
            
            [[ServerCommunicationController sharedInstance] logAdaptSyntax:prevComplexity :newComplexity context:manipulationContext];
        }
        
        manipulationContext.pageComplexity = [[ITSController sharedInstance] getCurrentComplexity];
    }
    
    [[ServerCommunicationController sharedInstance] logLoadPage:[manipulationContext pageLanguage] mode:[manipulationContext pageMode] number:[manipulationContext pageNumber] complexity:[manipulationContext pageComplexity] context:manipulationContext];
    
    //TODO: Remove hard coded strings
    //Get the solutions for the appropriate manipulation activity
    if (conditionSetup.condition == EMBRACE || ([chapterTitle isEqualToString:@"The Naughty Monkey"])) {
        PhysicalManipulationActivity *PMActivity;
        ITSPhysicalManipulationActivity *ITSPMActivity;
        ImagineManipulationActivity *IMActivity;
        ITSImagineManipulationActivity *ITSIMActivity;
        
        if (([chapterTitle isEqualToString:@"The Naughty Monkey"] && ([pageContext.currentPageId rangeOfString:PM2].location != NSNotFound) && conditionSetup.condition == CONTROL))
        {
            mvc.allowInteractions = false;
            //Get the PM solution steps for the current chapter
            Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
            PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
            stepContext.PMSolution = [[[PMActivity PMSolutions] objectForKey:pageContext.currentPageId] objectAtIndex:0]; //get PM solution
            sentenceContext.currentIdea = [[[stepContext.PMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = sentenceContext.currentIdea;
        }
        else if (([chapterTitle isEqualToString:@"The Naughty Monkey"] && (([pageContext.currentPageId rangeOfString:PM1].location != NSNotFound)|| ([pageContext.currentPageId rangeOfString:PM3].location != NSNotFound)) && conditionSetup.condition == CONTROL))
        {
            mvc.allowInteractions = false;
        }
        else if (conditionSetup.currentMode == PM_MODE) {
            if ([pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound) {
                mvc.allowInteractions = false;
            }
            else {
                mvc.allowInteractions = true;
            }
            
            //Get the PM solution steps for the current chapter
            Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
            PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
            stepContext.PMSolution = [[[PMActivity PMSolutions] objectForKey:pageContext.currentPageId] objectAtIndex:0]; //get PM solution
            sentenceContext.currentIdea = [[[stepContext.PMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = sentenceContext.currentIdea;
        }
        else if (conditionSetup.currentMode == ITSPM_MODE) {
            if ([pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound) {
                mvc.allowInteractions = false;
            }
            else {
                mvc.allowInteractions = true;
            }
            
            //Get the PM solution steps for the current chapter
            Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
            ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE]; //get PM Activity from chapter
            stepContext.ITSPMSolution = [[[ITSPMActivity ITSPMSolutions] objectForKey:pageContext.currentPageId] objectAtIndex:0]; //get ITSPM solution
            sentenceContext.currentIdea = [[[stepContext.ITSPMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = sentenceContext.currentIdea;
        }
        else if (conditionSetup.currentMode == IM_MODE) {
            //Get the IM solution steps for the current chapter
            Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
            IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE]; //get IM Activity from chapter
            stepContext.IMSolution = [[[IMActivity IMSolutions] objectForKey:pageContext.currentPageId] objectAtIndex:0]; //get IM solution
        }
        else if (conditionSetup.currentMode == ITSIM_MODE) {
            //Get the IM solution steps for the current chapter
            Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
            ITSIMActivity = (ITSImagineManipulationActivity *)[chapter getActivityOfType:ITSIM_MODE]; //get IM Activity from chapter
            stepContext.ITSIMSolution = [[[ITSIMActivity ITSIMSolutions] objectForKey:pageContext.currentPageId] objectAtIndex:0]; //get IM solution
            sentenceContext.currentIdea = [[[stepContext.ITSIMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = sentenceContext.currentIdea;
        }
    }
}

/*
 * Loads the next page for the current chapter based on the current activity.
 * If the activity has multiple pages, it would load the next page in the activity.
 * Otherwise, it will load the next chaper.
 */
- (void) loadNextPage {
    mvc.isLoadPageInProgress = true;
    [mvc.playaudioClass stopPlayAudioFile];
    
    pageContext.currentPage = [mvc.book getNextPageForChapterAndActivity:chapterTitle :((conditionSetup.currentMode == IM_MODE || conditionSetup.currentMode == ITSIM_MODE) ? PM_MODE : conditionSetup.currentMode) :pageContext.currentPage];
    
    //No more pages in chapter
    if (pageContext.currentPage == nil) {
        [[ServerCommunicationController sharedInstance] logCompleteManipulation:manipulationContext];
        
        if(conditionSetup.isAssessmentPageEnabled && conditionSetup.assessmentMode == ENDOFCHAPTER)
        {
            [mvc.view setUserInteractionEnabled:YES];
            [self loadAssessmentActivity];
        }
        else
        {
            [[ServerCommunicationController sharedInstance] studyContext].condition = NULL_TXT;
            
            //Set chapter as completed
            [[(LibraryViewController *)mvc.libraryViewController studentProgress] setStatusOfChapter:chapterTitle :COMPLETED fromBook:bookTitle];
            [mvc.view setUserInteractionEnabled:YES];
            
            if(conditionSetup.isAssessmentPageEnabled && conditionSetup.assessmentMode == ENDOFBOOK && [[(LibraryViewController *)mvc.libraryViewController studentProgress] getStatusOfBook:[mvc.book title]] == COMPLETED){
                
                    //Move to Assessment Activity
                    [self loadAssessmentActivity];
            }
            else{
                [[ServerCommunicationController sharedInstance] createNewLogFile];
                
                //Return to library view
                [mvc.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    else {
        [self loadPage];
    }
}

/*
 * Loads the previous page for the current chapter based on the current activity.
 * If the activity has multiple pages, it would load the previous page in the activity.
 * Otherwise, it will load the previous chaper.
 */
- (void) loadPreviousPage {
    mvc.isLoadPageInProgress = true;
    [mvc.playaudioClass stopPlayAudioFile];
    
    pageContext.currentPage = [mvc.book getPreviousPageForChapterAndActivity:chapterTitle :((conditionSetup.currentMode == IM_MODE || conditionSetup.currentMode == ITSIM_MODE) ? PM_MODE : conditionSetup.currentMode) :pageContext.currentPage];
    
    //No more pages in chapter
    if (pageContext.currentPage == nil) {
        //Return to library view
        [mvc.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self loadPage];
    }
}

/*
 * Displays the assessment activity view controller
 */
- (void)loadAssessmentActivity {
    UIImage *background = [mvc getBackgroundImage];
    
    //TODO: Remove hard coded workaround and find way to have same functionality
    //Hardcoding for second Introduction to EMBRACE
    if ([[(LibraryViewController *)mvc.libraryViewController studentProgress] getStatusOfBook:[mvc.book title]] == COMPLETED && ([[(LibraryViewController *)mvc.libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == IN_PROGRESS || [[(LibraryViewController *)mvc.libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == COMPLETED)){
        //Create an instance of the assessment activity view controller
        AssessmentActivityViewController *assessmentActivityViewController = [[AssessmentActivityViewController alloc]initWithModel:mvc.model : mvc.libraryViewController :background :@"Second Introduction to EMBRACE" :chapterTitle :pageContext.currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)sentenceContext.currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)stepContext.currentStep]];
        
        //Push the assessment view controller as the top controller
        [mvc.navigationController pushViewController:assessmentActivityViewController animated:YES];
    }
    else if (conditionSetup.assessmentMode == ENDOFCHAPTER || (conditionSetup.assessmentMode == ENDOFBOOK && [[(LibraryViewController *)mvc.libraryViewController studentProgress] getStatusOfBook:[mvc.book title]] == COMPLETED)) {
        
        //Create an instance of the assessment activity view controller
        AssessmentActivityViewController *assessmentActivityViewController = [[AssessmentActivityViewController alloc]initWithModel:mvc.model : mvc.libraryViewController :background :[mvc.book title] :chapterTitle :pageContext.currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)sentenceContext.currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)stepContext.currentStep]];
        
        //Push the assessment view controller as the top controller
        [mvc.navigationController pushViewController:assessmentActivityViewController animated:YES];
    }
    else{
        //TODO: Log fatal error and return to library view
    }
}

@end
