//
//  LibraryViewController.m
//  eBookReader
//
//  Created by Andreea Danielescu on 1/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LibraryViewController.h"
#import "LibraryCellView.h"
#import "BookCellView.h"
#import "BookHeaderView.h"
#import "Book.h"
#import "PMViewController.h"
#import "AuthoringModeViewController.h"
#import "ServerCommunicationController.h"
#import "ConditionSetup.h"

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate> {
    NSMutableArray *bookImages;
    NSMutableArray *bookTitles;
    NSMutableArray *chapterImages;
    NSMutableArray *chapterTitles;
    
    NSInteger selectedBookIndex;
    BOOL showBooks; //whether library is currently showing books or not
    
    NSUInteger lockedItemIndex; //index of long pressed item
    
    BOOL useSequence; //whether user must complete books/chapters according to a particular sequence
    
    ConditionSetup *conditionSetup;
}

@property (nonatomic, strong) IBOutlet UICollectionView *libraryView;
@property (nonatomic, strong) EBookImporter *bookImporter;
@property (nonatomic, strong) NSMutableArray *books;
@property (nonatomic, strong) NSString *bookToOpen;
@property (nonatomic, strong) NSString *chapterToOpen;

@end

@implementation LibraryViewController

@synthesize bookImporter;
@synthesize books;
@synthesize student;
@synthesize studentProgress;
@synthesize sequenceController;

NSString* const LIBRARY_PASSWORD_INPROGRESS = @"hello"; //used to set locked books/chapters to in progress
NSString* const LIBRARY_PASSWORD_COMPLETED = @"goodbye"; //used to set locked books/chapters to completed

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add background image
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"library_background"] drawInRect:self.view.bounds];
    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];

    //Register cells used to display books and chapters
    [self.libraryView registerClass:[LibraryCellView class] forCellWithReuseIdentifier:@"LibraryCellView"];
    [self.libraryView registerClass:[BookCellView class] forCellWithReuseIdentifier:@"BookCellView"];
    
    //Create long press gesture recognizer for unlocking books/chapters
    UILongPressGestureRecognizer* lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesturePerformed:)];
    lpgr.minimumPressDuration = 0.5; //in seconds
    [lpgr setDelegate:self];
    [self.libraryView addGestureRecognizer:lpgr];
    
    //Initialize book importer
    self.bookImporter = [[EBookImporter alloc] init];
    
    //Find the documents directory and start reading book
    self.books = [bookImporter importLibrary];
    
    //Create data source for collection view
    [self createCollectionLayoutDataSource];
    
    selectedBookIndex = 0;
    showBooks = TRUE; //initially show books
    
    [self setupCurrentSession];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateProgress];
}

/*
 * Goes through the imported books and pulls the data necessary to display the books and their associated chapters
 */
- (void)createCollectionLayoutDataSource {
    bookImages = [[NSMutableArray alloc] init];
    bookTitles = [[NSMutableArray alloc] init];
    chapterImages = [[NSMutableArray alloc] init];
    chapterTitles = [[NSMutableArray alloc] init];
    
    for (Book *book in books) {
        //Use the image for the first chapter as the image for the book
        NSString *bookImagePath = [[[book chapters] objectAtIndex:0] chapterImagePath];
        
        UIImage *bookImage;
        
        if (bookImagePath != nil) {
            bookImage = [[UIImage alloc] initWithContentsOfFile:bookImagePath];
        }
        
        //Add book image and title
        [bookImages addObject:bookImage];
        [bookTitles addObject:[book title]];
        
        //Create temporary arrays to hold chapter images and titles for the book
        NSMutableArray *bookChapterImages = [[NSMutableArray alloc] init];
        NSMutableArray *bookChapterTitles = [[NSMutableArray alloc] init];
        
        for (Chapter *chapter in [book chapters]) {
            //Get image for chapter
            NSString *chapterImagePath = [chapter chapterImagePath];
            
            UIImage *chapterImage;
            
            if (chapterImagePath != nil) {
                chapterImage = [[UIImage alloc] initWithContentsOfFile:chapterImagePath];
            }
            
            //Add chapter image and title
            [bookChapterImages addObject:chapterImage];
            [bookChapterTitles addObject:[chapter title]];
        }
        
        //Add chapter image and title arrays
        [chapterImages addObject:bookChapterImages];
        [chapterTitles addObject:bookChapterTitles];
    }
}

/*
 * Sets up the current session including the condition/mode, student, and progress data
 */
- (void)setupCurrentSession  {
    conditionSetup = [ConditionSetup sharedInstance];
    
    if (student != nil) {
        [[ServerCommunicationController sharedInstance] setupStudyContext:student];
        
        //Set title to display condition and language (e.g., EMBRACE English)
        self.title = [NSString stringWithFormat:@"%@ %@",[conditionSetup returnConditionEnumToString:conditionSetup.condition],[conditionSetup returnLanguageEnumtoString: conditionSetup.language]];
    }
    else {
        student = [[Student alloc] initWithValues:@"Study Code" :@"Study Day" :@"Experimenter" :@"School Day"];
    }
    
    [[ServerCommunicationController sharedInstance] logPressLogin];
    
    //Create ActivitySequenceController
    sequenceController = [[ActivitySequenceController alloc] init];

    //Load sequences if they exist for student
    if ([sequenceController loadSequences:[student participantCode]]) {
        useSequence = TRUE; //student should follow particular sequence of activities
    }
    else {
        useSequence = FALSE; //student will follow default sequence of activities
    }
    
    //Load progress for student if it exists
    studentProgress = [[ServerCommunicationController sharedInstance] loadProgress:student];
    
    //Create new progress for student if needed
    if (studentProgress == nil) {
        studentProgress = [[Progress alloc] init];
        [studentProgress loadBooks:books];
        
        NSString *firstBookTitle; //title of first book to set in progress
        
        if (useSequence) {
            studentProgress.sequenceId = [[student participantCode] uppercaseString]; //sequence id is just the participant code
            studentProgress.currentSequence = 0; //index of first sequence
            
            firstBookTitle = [[[sequenceController sequences] objectAtIndex:[studentProgress currentSequence]] bookTitle];
        }
        else {
            firstBookTitle = [bookTitles objectAtIndex:0];
        }
        
        //Set first book as in progress
        [studentProgress setNextChapterInProgressForBook:firstBookTitle];
    }
    else {
        //Update progress with any new books/chapters that might have been added
        [studentProgress addNewContent:books];
    }
    
//    //NOTE: Still testing this functionality
//    //Download progress file from Dropbox
//    [[ServerCommunicationController sharedInstance] downloadProgressForStudent:student completionHandler:^(BOOL success) {
//        if (success) {
//            //Load progress for student
//            studentProgress = [[ServerCommunicationController sharedInstance] loadProgress:student];
//            
//            //Update progress with any new books/chapters that might have been added
//            [studentProgress addNewContent:books];
//        }
//        else {
//            //Create new progress for student
//            studentProgress = [[Progress alloc] init];
//            [studentProgress loadBooks:books];
//            
//            NSString *firstBookTitle; //title of first book to set in progress
//            
//            if (useSequence) {
//                studentProgress.sequenceId = [[student participantCode] uppercaseString]; //sequence id is just the participant code
//                studentProgress.currentSequence = 0; //index of first sequence
//                
//                firstBookTitle = [[[sequenceController sequences] objectAtIndex:[studentProgress currentSequence]] bookTitle];
//            }
//            else {
//                firstBookTitle = [bookTitles objectAtIndex:0];
//            }
//            
//            //Set first book as in progress
//            [studentProgress setNextChapterInProgressForBook:firstBookTitle];
//        }
//        
//        //Update progress indicators
//        [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
//    }];
}

/*
 * Sets next book/chapter to in progress and updates library and progress file
 */
- (void)updateProgress {
    //Sequence
    if (useSequence) {
        //Get current book title
        NSString *currentBookTitle = [[[sequenceController sequences] objectAtIndex:[studentProgress currentSequence]] bookTitle];
        
        //Set the next incomplete chapter to in progress if it exists
        if (![studentProgress setNextChapterInProgressForBook:currentBookTitle]) {
            if ([studentProgress currentSequence] + 1 < [[sequenceController sequences] count]) {
                //Use next sequence
                studentProgress.currentSequence++;
                
                //Get next book title
                NSString *nextBookTitle = [[[sequenceController sequences] objectAtIndex:[studentProgress currentSequence]] bookTitle];
                
                //Reset next book to in progress if it has already been completed
                if ([studentProgress getStatusOfBook:nextBookTitle] == COMPLETED) {
                    //Get list of chapters in next book
                    NSMutableArray *modes = [[sequenceController getSequenceForBook:nextBookTitle] modes];
                    
                    //Set all chapters to incomplete
                    for (ActivityMode *mode in modes) {
                        [studentProgress setStatusOfChapter:[mode chapterTitle] :INCOMPLETE fromBook:nextBookTitle];
                    }
                    
                    //Set first chapter to in progress
                    [studentProgress setStatusOfChapter:[[modes objectAtIndex:0] chapterTitle] :IN_PROGRESS fromBook:nextBookTitle];
                }
                else {
                    //Set next book in sequence to in progress
                    [studentProgress setNextChapterInProgressForBook:nextBookTitle];
                }
                
                [self pressedBooks:self];
            }
        }
    }
    //No sequence
    else {
        //Set the next incomplete chapter to in progress if it exists
        if (![studentProgress setNextChapterInProgressForBook:[bookTitles objectAtIndex:selectedBookIndex]]) {
            BOOL inProgressBookExists = false; //whether another book is already in progress
            BOOL foundNextBook = false; //whether an incomplete book was found
            NSString *nextBookTitle;
            
            for (NSString *bookTitle in bookTitles) {
                Status bookStatus = [studentProgress getStatusOfBook:bookTitle];
                
                //Stop searching if there is already another book in progress
                if (bookStatus == IN_PROGRESS) {
                    inProgressBookExists = true;
                    break;
                }
                //Record title of next incomplete book if it exists
                else if (bookStatus == INCOMPLETE && !foundNextBook) {
                    nextBookTitle = bookTitle;
                    foundNextBook = true;
                }
            }
            
            //No books already in progress, so set the next incomplete book to in progress
            if (!inProgressBookExists && foundNextBook) {
                [studentProgress setNextChapterInProgressForBook:nextBookTitle];
            }
        }
    }
    
    //Update progress indicators
    [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    //Save progress to file
    [[ServerCommunicationController sharedInstance] saveProgress:student :studentProgress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    //Dispose of any resources that can be recreated
    self.libraryView = nil;
}

# pragma mark - Navigation

/*
 * Segue prep to go from LibraryViewController to BookView Controller.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (conditionSetup.appMode == Authoring) {
        AuthoringModeViewController *destination = [segue destinationViewController];
        destination.bookImporter = bookImporter;
        destination.bookTitle = self.bookToOpen;
        destination.chapterTitle = self.chapterToOpen;
        destination.libraryViewController = self;
        
        [destination loadFirstPage];
    }
    else {
        PMViewController *destination = [segue destinationViewController];
        destination.bookImporter = bookImporter;
        destination.bookTitle = self.bookToOpen;
        destination.chapterTitle = self.chapterToOpen;
        destination.libraryViewController = self;
        
        [destination loadFirstPage];
    }
}

/*
 * User pressed Books button. Switches to show books instead of chapters.
 */
- (IBAction)pressedBooks:(id)sender {
    showBooks = TRUE;
    
    [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    [booksButton setEnabled:FALSE];
    
    [[ServerCommunicationController sharedInstance] logPressBooks];
}

/*
 * User pressed Logout button. Writes data to log file and returns to login screen.
 */
- (IBAction)pressedLogout:(id)sender {
    [[ServerCommunicationController sharedInstance] logPressLogout];
    
    //Save progress to file
    [[ServerCommunicationController sharedInstance] saveProgress:student :studentProgress];
    
    //NOTE: Still testing this functionality
    //Upload log file and progress file to Dropbox
    //[[ServerCommunicationController sharedInstance] uploadFilesForStudent:student];
    
    //Reset ServerCommunicationController to end session
    [ServerCommunicationController resetSharedInstance];
    
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - Unlock Books/Chapters

/*
 * Long press is used to unlock books and chapters
 */
- (void)longPressGesturePerformed:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGPoint location = [recognizer locationInView:self.libraryView];
    NSIndexPath *indexPath = [self.libraryView indexPathForItemAtPoint:location];
    
    if (indexPath != nil) {
        lockedItemIndex = indexPath.row;
        
        //Books
        if (showBooks) {
            if ([studentProgress getStatusOfBook:[bookTitles objectAtIndex:lockedItemIndex]] == INCOMPLETE || [studentProgress getStatusOfBook:[bookTitles objectAtIndex:lockedItemIndex]] == IN_PROGRESS) {
                [self showPasswordPrompt];
            }
        }
        //Chapters
        else {
            if ([studentProgress getStatusOfChapter:[[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex] fromBook:[bookTitles objectAtIndex:selectedBookIndex]] == INCOMPLETE || [studentProgress getStatusOfChapter:[[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex] fromBook:[bookTitles objectAtIndex:selectedBookIndex]] == IN_PROGRESS) {
                [self showPasswordPrompt];
            }
        }
    }
}

/*
 * Shows a message to indicate that a selected book/chapter is locked
 */
- (void)showLockedMessage {
    NSString *itemType = @"item";
    
    if (showBooks) {
        itemType = @"book";
    }
    else {
        itemType = @"chapter";
    }
    
    NSString *title = [NSString stringWithFormat:@"This %@ is locked.", itemType];
    NSString *message = [NSString stringWithFormat:@"Please select a %@ with a red bookmark icon.", itemType];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

/*
 * Displays prompt to enter password to unlock books and chapters
 */
- (void)showPasswordPrompt {
    UIAlertView *passwordPrompt = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter password to unlock this item" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    passwordPrompt.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [passwordPrompt show];
}

/*
 * Checks if user input for password prompt is correct to unlock the selected book or chapter
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:@"Password"] && buttonIndex == 1) {
        NSString *selectedBookTitle;
        NSString *selectedChapterTitle;
        
        //Password is correct for setting item to in progress
        if ([[[alertView textFieldAtIndex:0] text] isEqualToString:LIBRARY_PASSWORD_INPROGRESS]) {
            //Books
            if (showBooks) {
                selectedBookTitle = [bookTitles objectAtIndex:lockedItemIndex];
                selectedChapterTitle = [[chapterTitles objectAtIndex:lockedItemIndex] objectAtIndex:0];
                
                //Unlock book by setting its first chapter to be in progress
                [studentProgress setStatusOfChapter:selectedChapterTitle :IN_PROGRESS fromBook:selectedBookTitle];
                
                [[ServerCommunicationController sharedInstance] logUnlockBook:selectedBookTitle withStatus:@"IN_PROGRESS"];
            }
            //Chapters
            else {
                selectedBookTitle = [bookTitles objectAtIndex:selectedBookIndex];
                selectedChapterTitle = [[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex];
                
                //Set this chapter to be in progress
                [studentProgress setStatusOfChapter:selectedChapterTitle :IN_PROGRESS fromBook:selectedBookTitle];
                
                [[ServerCommunicationController sharedInstance] logUnlockChapter:selectedChapterTitle inBook:selectedBookTitle withStatus:@"IN_PROGRESS"];
            }
            
            //Update progress indicators
            [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
            //Save progress to file
            [[ServerCommunicationController sharedInstance] saveProgress:student :studentProgress];
        }
        //Password is correct for setting item to completed
        else if ([[[alertView textFieldAtIndex:0] text] isEqualToString:LIBRARY_PASSWORD_COMPLETED]) {
            //Books
            if (showBooks) {
                selectedBookTitle = [bookTitles objectAtIndex:lockedItemIndex];
                
                for (NSString *chapterTitle in [chapterTitles objectAtIndex:lockedItemIndex]) {
                    [studentProgress setStatusOfChapter:chapterTitle :COMPLETED fromBook:selectedBookTitle];
                }
                
                [[ServerCommunicationController sharedInstance] logUnlockBook:selectedBookTitle withStatus:@"COMPLETED"];
            }
            //Chapters
            else {
                selectedBookTitle = [bookTitles objectAtIndex:selectedBookIndex];
                selectedChapterTitle = [[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex];
                
                [studentProgress setStatusOfChapter:selectedChapterTitle :COMPLETED fromBook:selectedBookTitle];
                
                [[ServerCommunicationController sharedInstance] logUnlockChapter:selectedChapterTitle inBook:selectedBookTitle withStatus:@"COMPLETED"];
            }
            
            [self updateProgress];
        }
    }
}

# pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)libraryView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)libraryView numberOfItemsInSection:(NSInteger)section {
    //Books
    if (showBooks) {
        return [books count];
    }
    //Chapters
    else {
        return [[chapterImages objectAtIndex:selectedBookIndex] count];
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)libraryView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LibraryCellView *cell = (LibraryCellView *)[libraryView dequeueReusableCellWithReuseIdentifier:@"LibraryCellView" forIndexPath:indexPath];
    
    UIImage *image;
    NSString *title;
    Status currentStatus;

    //Books
    if (showBooks) {
        cell = (BookCellView *)[libraryView dequeueReusableCellWithReuseIdentifier:@"BookCellView" forIndexPath:indexPath];
        
        image = [bookImages objectAtIndex:indexPath.row];
        title = [bookTitles objectAtIndex:indexPath.row];
        
        [[cell coverImage] setImage:image];
        [[cell coverTitle] setText:title];
        
        currentStatus = [studentProgress getStatusOfBook:title];
    }
    //Chapters
    else {
        image = [[chapterImages objectAtIndex:selectedBookIndex] objectAtIndex:indexPath.row];
        title = [[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:indexPath.row];
        
        [[cell coverImage] setImage:image];
        [[cell coverTitle] setText:title];
        
        currentStatus = [studentProgress getStatusOfChapter:title fromBook:[bookTitles objectAtIndex:selectedBookIndex]];
    }
    
    //Display progress indicator
    [cell displayIndicator:currentStatus];
    
    return cell;
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)libraryView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //Books
    if (showBooks) {
        selectedBookIndex = indexPath.row;
        
        NSString *selectedBookTitle = [bookTitles objectAtIndex:selectedBookIndex];
        
        //Only allow book to be opened if it is not incomplete
        if ([studentProgress getStatusOfBook:selectedBookTitle] != INCOMPLETE) {
            showBooks = FALSE;
            
            [libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]]; //load chapters
            
            [booksButton setEnabled:TRUE];
            
            [[ServerCommunicationController sharedInstance] logLoadBook:selectedBookTitle];
        }
        else {
            [self showLockedMessage];
        }
    }
    //Chapters
    else {
        NSString *selectedBookTitle = [bookTitles objectAtIndex:selectedBookIndex];
        NSString *selectedChapterTitle = [[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:indexPath.row];
        
        //Get status of selected chapter
        Status chapterStatus = [studentProgress getStatusOfChapter:selectedChapterTitle fromBook:selectedBookTitle];
        
        //Only allow chapter to be opened if it is not incomplete
        if (chapterStatus != INCOMPLETE) {
            //Get selected book
            Book *book = [books objectAtIndex:selectedBookIndex];
            
            NSString *title = [[book title] stringByAppendingString:@" - "];
            title = [title stringByAppendingString:[book author]];
            
            self.bookToOpen = title;
            self.chapterToOpen = [[[book chapters] objectAtIndex:indexPath.row] title];
            
            if (useSequence) {
                //If chapter already completed, just open in read-only English mode for now
                if (chapterStatus == COMPLETED) {
                    conditionSetup.condition = CONTROL;
                    conditionSetup.language = ENGLISH;
                    conditionSetup.reader = USER;
                }
                else {
                    //Get current mode for chapter
                    ActivityMode *currentMode = [[[sequenceController sequences] objectAtIndex:[studentProgress currentSequence]] getModeForChapter:selectedChapterTitle];
                    
                    //Set conditions for chapter based on mode information
                    if ([currentMode interventionType] == PM_INTERVENTION) {
                        conditionSetup.condition = EMBRACE;
                        conditionSetup.currentMode = PM_MODE;
                    }
                    else if ([currentMode interventionType] == IM_INTERVENTION) {
                        conditionSetup.condition = EMBRACE;
                        conditionSetup.currentMode = IM_MODE;
                    }
                    else if ([currentMode interventionType] == R_INTERVENTION) {
                        conditionSetup.condition = CONTROL;
                    }
                    //Current mode for chapter was not found; default to control
                    else {
                        conditionSetup.condition = CONTROL;
                    }
                    
                    //Set language, reader, and new instructions
                    conditionSetup.language = [currentMode language];
                    conditionSetup.reader = [currentMode reader];
                    conditionSetup.newInstructions = [currentMode newInstructions];
                }
            }
            
            NSString *condition = @"Unknown";
            
            if (conditionSetup.condition == CONTROL) {
                condition = @"R";
            }
            else if (conditionSetup.condition == EMBRACE) {
                if (conditionSetup.currentMode == PM_MODE) {
                    condition = @"PM";
                }
                else if (conditionSetup.currentMode == IM_MODE) {
                    condition = @"IM";
                }
            }
            
            [[ServerCommunicationController sharedInstance] studyContext].condition = condition;
            [[ServerCommunicationController sharedInstance] logLoadChapter:selectedChapterTitle inBook:selectedBookTitle];
            
            //Send the notification to open that mode for the particular book and activity chosen
            if (conditionSetup.appMode == Authoring) {
                [self performSegueWithIdentifier:@"OpenAuthoringSegue" sender:self];
            }
            else if (conditionSetup.currentMode == PM_MODE) {
                [self performSegueWithIdentifier: @"OpenPMActivitySegue" sender:self];
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                //TODO: Currently only using PM segue and PMViewController
//                [self performSegueWithIdentifier: @"OpenIMActivitySegue" sender:self];
                [self performSegueWithIdentifier: @"OpenPMActivitySegue" sender:self];
            }
        }
        else {
            [self showLockedMessage];
        }
    }
    
    //Deselect the cell so that it doesn't show as being selected when the user comes back to the library
    [libraryView deselectItemAtIndexPath:indexPath animated:YES];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

# pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    NSInteger edgeInsets = 0;
    NSInteger cellWidth = 200;
    
    NSInteger maxCellsPerRow = 4;
    NSInteger numberOfCells = 0;
    
    //Books
    if (showBooks) {
        numberOfCells = [books count];
    }
    //Chapters
    else {
        numberOfCells = [[chapterImages objectAtIndex:selectedBookIndex] count];
    }
    
    if (numberOfCells <= maxCellsPerRow) {
        edgeInsets = (self.view.frame.size.width - (numberOfCells * cellWidth)) / 2;
    }
    else {
        edgeInsets = (self.view.frame.size.width - (maxCellsPerRow * cellWidth)) / 2;
    }
    
    return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {        
        BookHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BookHeaderView" forIndexPath:indexPath];
        
        NSString *title;

        //Books
        if (showBooks) {
            title = @"Books";
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header1"];
        }
        //Chapters
        else {
            Book *book = [books objectAtIndex:selectedBookIndex];
            title = [book title]; //Set title to title of book
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header2"];
        }
        
        headerView.bookTitle.text = title;
        
        reusableview = headerView;
    }
    
    return reusableview;
}

@end
