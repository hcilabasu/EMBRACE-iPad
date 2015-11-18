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

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    NSMutableArray* bookImages;
    NSMutableArray* bookTitles;
    NSMutableArray* chapterImages;
    NSMutableArray* chapterTitles;
    
    NSInteger selectedBookIndex;
    BOOL showBooks; //whether library is currently showing books or not
    
    NSUInteger lockedItemIndex; //index of long pressed item
}

@property (nonatomic, strong) IBOutlet UICollectionView *libraryView;
@property (nonatomic, strong) EBookImporter *bookImporter;
@property (nonatomic, strong) NSMutableArray *books;
@property (nonatomic, strong) NSString* bookToOpen;
@property (nonatomic, strong) NSString* chapterToOpen;

@end

@implementation LibraryViewController

@synthesize bookImporter;
@synthesize books;
@synthesize student;
@synthesize studentProgress;

NSString* const LIBRARY_PASSWORD = @"hello"; //used to unlock locked books/chapters

ConditionSetup *conditionSetup;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    //Add background image
    UIImageView* backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"library_background"]];
    [backgroundImageView setFrame:CGRectMake(0, 0, self.libraryView.frame.size.height, self.libraryView.frame.size.width)];
    [self.libraryView addSubview:backgroundImageView];
    [self.libraryView sendSubviewToBack:backgroundImageView];
    
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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //Set the next incomplete chapter to in progress if it exists
    if (![studentProgress setNextChapterInProgressForBook:[bookTitles objectAtIndex:selectedBookIndex]]) {
        BOOL inProgressBookExists = false; //whether another book is already in progress
        BOOL foundNextBook = false; //whether an incomplete book was found
        NSString* nextBookTitle;
        
        for (NSString* bookTitle in bookTitles) {
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
    
    //Update progress indicators
    [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
}

/*
 * Goes through the imported books and pulls the data necessary to display the books and their associated chapters
 */
- (void) createCollectionLayoutDataSource {
    bookImages = [[NSMutableArray alloc] init];
    bookTitles = [[NSMutableArray alloc] init];
    chapterImages = [[NSMutableArray alloc] init];
    chapterTitles = [[NSMutableArray alloc] init];
    
    for (Book* book in books) {
        //Use the image for the first chapter as the image for the book
        NSString* bookImagePath = [[[book chapters] objectAtIndex:0] chapterImagePath];
        
        UIImage* bookImage;
        
        if (bookImagePath != nil) {
            bookImage = [[UIImage alloc] initWithContentsOfFile:bookImagePath];
        }
        
        //Add book image and title
        [bookImages addObject:bookImage];
        [bookTitles addObject:[book title]];
        
        //Create temporary arrays to hold chapter images and titles for the book
        NSMutableArray* bookChapterImages = [[NSMutableArray alloc] init];
        NSMutableArray* bookChapterTitles = [[NSMutableArray alloc] init];
        
        for (Chapter* chapter in [book chapters]) {
            //Get image for chapter
            NSString* chapterImagePath = [chapter chapterImagePath];
            
            UIImage* chapterImage;
            
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
- (void) setupCurrentSession  {
    conditionSetup = [[ConditionSetup alloc] init];
    currentMode = PM_MODE;
    
    if (student != nil) {
        [[ServerCommunicationController sharedManager] logContext:student];
        
        //Set title to display condition and language (e.g., EMBRACE English)
        self.title = [NSString stringWithFormat:@"%@ %@",[conditionSetup ReturnConditionEnumToString:conditionSetup.condition],[conditionSetup ReturnLanguageEnumtoString: conditionSetup.language]];
    }
    else {
        student = [[Student alloc] initWithName:@"Study Code" :@"Study Day":@"Experimenter":@"School Day"];
    }
    
    //Load progress for student if it exists
    studentProgress = [[ServerCommunicationController sharedManager] loadProgress:student];
    
    //Create new progress for student if needed
    if (studentProgress == nil) {
        studentProgress = [[Progress alloc] init];
        [studentProgress loadBooks:books];
        
        NSString* firstBookTitle = [bookTitles objectAtIndex:0];
        NSString* firstChapterTitle = [[chapterTitles objectAtIndex:0] objectAtIndex:0];
        
        //Start off with the first chapter of the first book in progress
        [studentProgress setStatusOfChapter:firstChapterTitle :IN_PROGRESS fromBook:firstBookTitle];
    }
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    //Dispose of any resources that can be recreated
    self.libraryView = nil;
}

/*
 * Segue prep to go from LibraryViewController to BookView Controller.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (conditionSetup.appmode == Authoring) {
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

        [[ServerCommunicationController sharedManager] logStoryButtonPressed: @"Library Icon" : @"Tap" : self.bookToOpen : self.chapterToOpen : @"NULL" : -1 : @"NULL": -1: -1];
        
        [destination loadFirstPage];
    }
    
    //Change the back button so that it doesn't show the LibraryView's title and instead shows "Back"
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: @"Library" style: UIBarButtonItemStyleBordered target: nil action: nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
}

/*
 * User pressed Books button. Switches to show books instead of chapters.
 */
- (IBAction) pressedBooks:(id)sender {
    showBooks = TRUE;
    
    [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    [booksButton setEnabled:FALSE];
}

/*
 * User pressed Logout button. Writes data to log file and returns to login screen.
 */
- (IBAction) pressedLogout:(id)sender {
    //Write log data to file
    [[ServerCommunicationController sharedManager] writeToFile:[[ServerCommunicationController sharedManager] studyFileName] ofType:@"txt"];
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*
 * Long press is used to unlock books and chapters
 */
- (void) longPressGesturePerformed:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGPoint location = [recognizer locationInView:self.libraryView];
    NSIndexPath* indexPath = [self.libraryView indexPathForItemAtPoint:location];
    
    if (indexPath != nil) {
        lockedItemIndex = indexPath.row;
        
        //Books
        if (showBooks) {
            if ([studentProgress getStatusOfBook:[bookTitles objectAtIndex:lockedItemIndex]] == INCOMPLETE) {
                [self showPasswordPrompt];
            }
        }
        //Chapters
        else {
            if ([studentProgress getStatusOfChapter:[[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex] fromBook:[bookTitles objectAtIndex:selectedBookIndex]] == INCOMPLETE) {
                [self showPasswordPrompt];
            }
        }
    }
}

/*
 * Displays prompt to enter password to unlock books and chapters
 */
- (void) showPasswordPrompt {
    UIAlertView* passwordPrompt = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter password to unlock this item" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    passwordPrompt.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [passwordPrompt show];
}

/*
 * Checks if user input for password prompt is correct to unlock the selected book or chapter
 */
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:@"Password"] && buttonIndex == 1) {
        //Password is correct
        if ([[[alertView textFieldAtIndex:0] text] isEqualToString:LIBRARY_PASSWORD]) {
            //Books
            if (showBooks) {
                //Unlock book by setting its first chapter to be in progress
                [studentProgress setStatusOfChapter:[[chapterTitles objectAtIndex:lockedItemIndex] objectAtIndex:0] :IN_PROGRESS fromBook:[bookTitles objectAtIndex:lockedItemIndex]];
            }
            //Chapters
            else {
                //Set this chapter to be in progress
                [studentProgress setStatusOfChapter:[[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:lockedItemIndex] :IN_PROGRESS fromBook:[bookTitles objectAtIndex:selectedBookIndex]];
            }
            
            //Update progress indicators
            [self.libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        }
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)libraryView {
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
    LibraryCellView* cell = (LibraryCellView*) [libraryView dequeueReusableCellWithReuseIdentifier:@"LibraryCellView" forIndexPath:indexPath];
    
    UIImage* image;
    NSString* title;
    Status currentStatus;

    //Books
    if (showBooks) {
        cell = (BookCellView*) [libraryView dequeueReusableCellWithReuseIdentifier:@"BookCellView" forIndexPath:indexPath];
        
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

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)libraryView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //Books
    if (showBooks) {
        selectedBookIndex = indexPath.row;
        
        //Only allow book to be opened if it is not incomplete
        if ([studentProgress getStatusOfBook:[bookTitles objectAtIndex:selectedBookIndex]] != INCOMPLETE) {
            showBooks = FALSE;
            
            [libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]]; //load chapters
            
            [booksButton setEnabled:TRUE];
        }
    }
    //Chapters
    else {
        //Only allow chapter to be opened if it is not incomplete
        if ([studentProgress getStatusOfChapter:[[chapterTitles objectAtIndex:selectedBookIndex] objectAtIndex:indexPath.row] fromBook:[bookTitles objectAtIndex:selectedBookIndex]] != INCOMPLETE) {
            //Get selected book
            Book* book = [books objectAtIndex:selectedBookIndex];
            
            NSString* title = [[book title] stringByAppendingString:@" - "];
            title = [title stringByAppendingString:[book author]];
            
            self.bookToOpen = title;
            self.chapterToOpen = [[[book chapters] objectAtIndex:indexPath.row] title];
            
            //Send the notification to open that mode for the particular book and activity chosen
            if (conditionSetup.appmode == Authoring) {
                [self performSegueWithIdentifier:@"OpenAuthoringSegue" sender:self];
            }
            else if (currentMode == PM_MODE) {
                [self performSegueWithIdentifier: @"OpenPMActivitySegue" sender:self];
            }
            else if (currentMode == IM_MODE) {
                [self performSegueWithIdentifier: @"OpenIMActivitySegue" sender:self];
            }
        }
    }
    
    //Deselect the cell so that it doesn't show as being selected when the user comes back to the library
    [libraryView deselectItemAtIndexPath:indexPath animated:YES];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: Right now return true, but eventually we'll have to go ahead and display 2 different images based on whether or not
    //the student has completed the activity. This means changing the data source for the collection view and returning no from
    //this function so the student cannot select the item.
    return YES;
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
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
        
        NSString* title;

        //Books
        if (showBooks) {
            title = @"Books";
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header1"];
        }
        //Chapters
        else {
            Book* book = [books objectAtIndex:selectedBookIndex];
            title = [book title]; //Set title to title of book
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header2"];
        }
        
        headerView.bookTitle.text = title;
        
        reusableview = headerView;
    }
    
    return reusableview;
}

@end
