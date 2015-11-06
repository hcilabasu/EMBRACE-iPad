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
}

@property (nonatomic, strong) IBOutlet UICollectionView *libraryView;

@property (nonatomic, strong) NSMutableArray* bookImages;
@property (nonatomic, strong) NSMutableArray* bookTitles;
@property (nonatomic, strong) NSMutableArray* chapterImages;
@property (nonatomic, strong) NSMutableArray* chapterTitles;

@property (nonatomic, strong) EBookImporter *bookImporter;

@property (nonatomic, strong) NSMutableArray *books;

@property (nonatomic, strong) NSString* bookToOpen;
@property (nonatomic, strong) NSString* chapterToOpen;

@property (nonatomic, assign) NSInteger selectedBookIndex;
@property (nonatomic, assign) BOOL showBooks;

@end

@implementation LibraryViewController

@synthesize bookImporter;
@synthesize books;
@synthesize student;

@synthesize bookImages;
@synthesize bookTitles;
@synthesize chapterImages;
@synthesize chapterTitles;

@synthesize booksButton;

ConditionSetup *conditionSetup;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    //Add background image
    UIImageView* backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"library_background"]];
    [backgroundImageView setFrame:CGRectMake(0, 0, self.libraryView.frame.size.height, self.libraryView.frame.size.width)];
    [self.libraryView addSubview:backgroundImageView];
    [self.libraryView sendSubviewToBack:backgroundImageView];
    
    [self.libraryView registerClass:[LibraryCellView class] forCellWithReuseIdentifier:@"LibraryCellView"];
    [self.libraryView registerClass:[BookCellView class] forCellWithReuseIdentifier:@"BookCellView"];
    
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
    
    //Initialize book importer
    self.bookImporter = [[EBookImporter alloc] init];
    
    //Find the documents directory and start reading book
    self.books = [bookImporter importLibrary];
    
    //Create data source for collection view
    [self createCollectionLayoutDataSource];
    
    self.selectedBookIndex = 0;
    self.showBooks = TRUE; //initially show books
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

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    //Dispose of any resources that can be recreated
    self.libraryView = nil;
    self.bookImages = nil;
    self.chapterImages = nil;
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
    self.showBooks = TRUE;
    
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

#pragma mark - UICollectionViewDataSource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)libraryView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)libraryView numberOfItemsInSection:(NSInteger)section {
    //Books
    if (self.showBooks) {
        return [books count];
    }
    //Chapters
    else {
        return [[chapterImages objectAtIndex:self.selectedBookIndex] count];
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)libraryView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LibraryCellView* cell = (LibraryCellView*) [libraryView dequeueReusableCellWithReuseIdentifier:@"LibraryCellView" forIndexPath:indexPath];
    
    UIImage* image;
    NSString* title;

    //Books
    if (self.showBooks) {
        cell = (BookCellView*) [libraryView dequeueReusableCellWithReuseIdentifier:@"BookCellView" forIndexPath:indexPath];
        
        image = [bookImages objectAtIndex:indexPath.row];
        title = [bookTitles objectAtIndex:indexPath.row];
        
        [[cell coverImage] setImage:image];
        [[cell coverTitle] setText:title];
    }
    //Chapters
    else {
        image = [[chapterImages objectAtIndex:self.selectedBookIndex] objectAtIndex:indexPath.row];
        title = [[chapterTitles objectAtIndex:self.selectedBookIndex] objectAtIndex:indexPath.row];
        
        [[cell coverImage] setImage:image];
        [[cell coverTitle] setText:title];
    }
    
    //TEST: Display progress indicator
    if (indexPath.row < 2) {
        [cell displayIndicator:COMPLETED];
    }
    else if (indexPath.row == 2) {
        [cell displayIndicator:IN_PROGRESS];
    }
    else {
        [cell displayIndicator:INCOMPLETE];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)libraryView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //Books
    if (self.showBooks) {
        self.selectedBookIndex = indexPath.row;
        self.showBooks = FALSE;
        
        [libraryView reloadSections:[NSIndexSet indexSetWithIndex:0]]; //load chapters
        
        [booksButton setEnabled:TRUE];
    }
    //Chapters
    else {
        //Get selected book
        Book* book = [books objectAtIndex:self.selectedBookIndex];
        
        NSString* title = [[book title] stringByAppendingString:@" - "];
        title = [title stringByAppendingString:[book author]];
        
        self.bookToOpen = title;
        self.chapterToOpen = [[[book chapters] objectAtIndex:indexPath.row] title];
        
        //Deselect the cell so that it doesn't show as being selected when the user comes back to the library
        [libraryView deselectItemAtIndexPath:indexPath animated:YES];
        
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
    if (self.showBooks) {
        numberOfCells = [books count];
    }
    //Chapters
    else {
        numberOfCells = [[chapterImages objectAtIndex:self.selectedBookIndex] count];
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
        if (self.showBooks) {
            title = @"Books";
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header1"];
        }
        //Chapters
        else {
            Book* book = [books objectAtIndex:self.selectedBookIndex];
            title = [book title]; //Set title to title of book
            
            headerView.backgroundImage.image = [UIImage imageNamed:@"library_header2"];
        }
        
        headerView.bookTitle.text = title;
        
        reusableview = headerView;
    }
    
    return reusableview;
}

@end
