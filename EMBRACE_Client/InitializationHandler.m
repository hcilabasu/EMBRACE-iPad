//
//  InitializationHandler.m
//  EMBRACE
//
//  Created by Shang Wang on 4/9/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import "InitializationHandler.h"
#import "ManipulationViewController.h"
@implementation InitializationHandler
@synthesize parentManipulaitonCtr;


-(void)initlizeManipulaitonCtr{
    parentManipulaitonCtr.wasPathFollowed=NO;
    parentManipulaitonCtr.isAudioPlaying=NO;
    
    //hides the default navigation bar to add custom back button
    parentManipulaitonCtr.navigationItem.hidesBackButton = YES;
    
    parentManipulaitonCtr.conditionSetup = [ConditionSetup sharedInstance];
    parentManipulaitonCtr.manipulationContext = [[ManipulationContext alloc] init];
    parentManipulaitonCtr.forwardProgress = [[ForwardProgress alloc] init];
    parentManipulaitonCtr.pageContext = [[PageContext alloc] init];
    parentManipulaitonCtr.sentenceContext = [[SentenceContext alloc] init];
    parentManipulaitonCtr.stepContext = [[StepContext alloc] init];
    
    parentManipulaitonCtr.model = [[InteractionModel alloc]init];
    parentManipulaitonCtr.playaudioClass = [[PlayAudioFile alloc] init];
    parentManipulaitonCtr.playaudioClass.parentManipulationViewController=parentManipulaitonCtr;
    parentManipulaitonCtr.menuDataSource = [[ContextualMenuDataSource alloc] init];
    
    //initialize toDo image
    parentManipulaitonCtr.toDoIcon =[[UIImageView alloc] initWithFrame:CGRectMake(50,50,24,24)];
    parentManipulaitonCtr.toDoIcon.image=nil;
    [parentManipulaitonCtr.bookView addSubview:parentManipulaitonCtr.toDoIcon];
    parentManipulaitonCtr.PMIcon= [UIImage imageNamed:@"handIcon"];
    parentManipulaitonCtr.IMIcon= [UIImage imageNamed:@"thinkIcon"];
    parentManipulaitonCtr.RDIcon= [UIImage imageNamed:@"glassIcon"];
    parentManipulaitonCtr.PMIcon = [parentManipulaitonCtr imageWithImage:parentManipulaitonCtr.PMIcon scaledToSize:CGSizeMake(26, 26)];
    parentManipulaitonCtr.IMIcon = [parentManipulaitonCtr imageWithImage:parentManipulaitonCtr.IMIcon scaledToSize:CGSizeMake(24, 24)];
    parentManipulaitonCtr.RDIcon = [parentManipulaitonCtr imageWithImage:parentManipulaitonCtr.RDIcon scaledToSize:CGSizeMake(24, 24)];
    
    parentManipulaitonCtr.iconLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60, 20)];
    parentManipulaitonCtr.iconLabel.font=[parentManipulaitonCtr.iconLabel.font fontWithSize:13];
    parentManipulaitonCtr.iconLabel.textAlignment = NSTextAlignmentCenter;
    [parentManipulaitonCtr.bookView addSubview:parentManipulaitonCtr.iconLabel];
    //Added to deal with ios7 view changes. This makes it so the UIWebView and the navigation bar do not overlap.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        parentManipulaitonCtr.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    parentManipulaitonCtr.view.backgroundColor = [UIColor whiteColor];
    
   parentManipulaitonCtr. manipulationView.bookView.scalesPageToFit = YES;
    parentManipulaitonCtr.manipulationView.bookView.scrollView.delegate = parentManipulaitonCtr;
    
    [[parentManipulaitonCtr.manipulationView.bookView scrollView] setBounces: NO];
    [[parentManipulaitonCtr.manipulationView.bookView scrollView] setScrollEnabled:NO];
    
    parentManipulaitonCtr.pageContext.currentPage = nil;
    
    parentManipulaitonCtr.pinching = FALSE;
    parentManipulaitonCtr.pinchToUngroup = FALSE;
    parentManipulaitonCtr.replenishSupply = FALSE;
    parentManipulaitonCtr.allowSnapback = TRUE;
    parentManipulaitonCtr.pressedNextLock = false;
    parentManipulaitonCtr.isLoadPageInProgress = false;
    parentManipulaitonCtr.isUserMovingBack = false;
    parentManipulaitonCtr.didSelectCorrectMenuOption = false;
    
    parentManipulaitonCtr.movingObject = FALSE;
    parentManipulaitonCtr.movingObjectId = nil;
    parentManipulaitonCtr.collisionObjectId = nil;
    parentManipulaitonCtr.separatingObjectId = nil;
    parentManipulaitonCtr.lastRelationship = nil;
    parentManipulaitonCtr.allRelationships = [[NSMutableArray alloc] init];
    parentManipulaitonCtr.currentGroupings = [[NSMutableDictionary alloc] init];
    
    parentManipulaitonCtr.navigationItem.rightBarButtonItem = nil;
    
    
    
    if (parentManipulaitonCtr.conditionSetup.condition == CONTROL) {
        parentManipulaitonCtr.allowInteractions = FALSE;
        parentManipulaitonCtr.useSubject = NO_ENTITIES;
        parentManipulaitonCtr.useObject = NO_ENTITIES;
    }
    else if (parentManipulaitonCtr.conditionSetup.condition == EMBRACE) {
        parentManipulaitonCtr.allowInteractions = TRUE;
        
        //Shang: changed maxAttempts to 3
        parentManipulaitonCtr.stepContext.maxAttempts = 3;
        parentManipulaitonCtr.stepContext.numAttempts = 0;
        
        if (parentManipulaitonCtr.conditionSetup.currentMode == PM_MODE || parentManipulaitonCtr.conditionSetup.currentMode == ITSPM_MODE) {
            parentManipulaitonCtr.useSubject = ALL_ENTITIES;
            parentManipulaitonCtr.useObject = ONLY_CORRECT;
        }
        else if (parentManipulaitonCtr.conditionSetup.currentMode == IM_MODE || parentManipulaitonCtr.conditionSetup.currentMode == ITSIM_MODE) {
            parentManipulaitonCtr.useSubject = NO_ENTITIES;
            parentManipulaitonCtr.useObject = NO_ENTITIES;
        }
        
        if (parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && ![parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"]) {
            [[ITSController sharedInstance] setAnalyzerDelegate:self];
            parentManipulaitonCtr.stepContext.numSyntaxErrors = 0;
            parentManipulaitonCtr.stepContext.numVocabErrors = 0;
            parentManipulaitonCtr.stepContext.numUsabilityErrors = 0;
        }
    }
    
    
    if(parentManipulaitonCtr.conditionSetup.reader == USER || !parentManipulaitonCtr.conditionSetup.isSpeakerButtonEnabled){
        NSArray *arrSubviews = [parentManipulaitonCtr.view subviews];
        for(UIView *tmpView in arrSubviews)
        {
            if([tmpView isMemberOfClass:[UIButton class]])
            {
                // Optionally, check button.tag
                if(tmpView.tag == 2) {
                    //hide the Speaker Icon
                    [tmpView setHidden: true];
                }
            }
        }
    }
    
    if(!parentManipulaitonCtr.conditionSetup.isBackButtonEnabled){
        NSArray *arrSubviews = [parentManipulaitonCtr.view subviews];
        for(UIView *tmpView in arrSubviews)
        {
            if([tmpView isMemberOfClass:[UIButton class]])
            {
                // Optionally, check button.tag
                if(tmpView.tag == 3) {
                    //hide the Speaker Icon
                    [tmpView setHidden: true];
                }
            }
        }
    }
    
    
    if(ITS_SYSTEM== parentManipulaitonCtr.conditionSetup.ITSComplexity){
       parentManipulaitonCtr.conditionSetup.ITSComplexity=ITS_SYSTEM;
    }
    
    if( ITSIM_MODE==parentManipulaitonCtr.conditionSetup.currentMode  && ITS_SYSTEM== parentManipulaitonCtr.conditionSetup.ITSComplexity){
        parentManipulaitonCtr.conditionSetup.ITSComplexity=ITS_MEDIUM;
    }
    parentManipulaitonCtr.skipButton = [[UIButton alloc] initWithFrame:CGRectMake(0, parentManipulaitonCtr.bookView.frame.size.height-180, 120, 120)];
    parentManipulaitonCtr.skipButton.backgroundColor=[UIColor clearColor];
    [parentManipulaitonCtr.bookView addSubview:parentManipulaitonCtr.skipButton];
    
    parentManipulaitonCtr.overlayView=[[UIView alloc]initWithFrame:CGRectMake(parentManipulaitonCtr.bookView.frame.size.width-120, parentManipulaitonCtr.bookView.frame.size.height-150, 120, 150)];
    parentManipulaitonCtr.overlayView.backgroundColor=[UIColor clearColor];
    //overlayView.alpha=0.6;
    [parentManipulaitonCtr.view addSubview:parentManipulaitonCtr.overlayView];
}






@end
