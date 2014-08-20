//
//  LibraryViewController.m
//  eBookReader
//
//  Created by Andreea Danielescu on 1/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LibraryViewController.h"
#import "BookCellView.h"
#import "BookHeaderView.h"
#import "Book.h"
#import "PMViewController.h"
#import "ServerCommunicationController.h"

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    NSMutableArray *libraryImages;
    NSMutableArray *libraryTitles;
}

@property (nonatomic, strong) IBOutlet UICollectionView *libraryView;
//@property (strong, nonatomic) IBOutlet UILabel *libraryLabel;

@property (nonatomic, strong) NSMutableArray *libraryImages;
@property (nonatomic, strong) NSMutableArray *libraryTitles;

@property (nonatomic, strong) EBookImporter *bookImporter;

@property (nonatomic, strong) NSMutableArray *books;

@property (nonatomic, strong) NSString* bookToOpen;
@property (nonatomic, strong) NSString* chapterToOpen;

@end

@implementation LibraryViewController

@synthesize bookImporter;
@synthesize books;
@synthesize student;

@synthesize libraryImages;
@synthesize libraryTitles;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the title to something personalized.
    if(student != nil) {
        
        //added by James for xml logging
        [[ServerCommunicationController sharedManager] logContext:student];
        //Logging Completes Here.
        
        self.title = @"Temp Condition";
    }
    else
    {
        student = [[Student alloc] initWithName:@"Study Code" :@"Study Day":@"Experimenter"];
        
        //added by James for xml logging
        //[[ServerCommunicationController sharedManager] logContext:student];
        //Logging Completes Here.
    }
    
    //initialize and book importer.
    self.bookImporter = [[EBookImporter alloc] init];
    
    //find the documents directory and start reading book.
    self.books = [bookImporter importLibrary];
    
    //set the background color to something that looks like a library.
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ibooks_waller_vertical.png"]];
    
    //Create data source for collection view.
    [self createCollectionLayoutDataSource];
    
    //Disable all activities that need to be disabled based on the student information.
    //TODO: Connect student specific stuff later. Right now we'll just go through and disable all but the first one.
    
    //Currently defaulting to PM_MODE
    currentMode = PM_MODE;
}

/*public override bool ShouldHighlightItem (UICollectionView collectionView, NSIndexPath indexPath)
{
    return false;
}*/

//Goes through the imported books and pulls the  data necessary to display the books and their associated chapters.
- (void) createCollectionLayoutDataSource {
    //Setup the collection view information
    libraryImages = [[NSMutableArray alloc] init];
    libraryTitles = [[NSMutableArray alloc] init];
    
    for (Book *book in books) {
        NSMutableArray *imagesForBook = [[NSMutableArray alloc] init];
        NSMutableArray *titlesForBook = [[NSMutableArray alloc] init];
        
        //Go through the chapters and get the title of the chapters and their associated images.
        for(Chapter *chapter in [book chapters]) {
            NSString *chapterTitle = [chapter title];
            
            NSString* coverImagePath = [chapter chapterImagePath];
            UIImage *chapterImage;
            
            //Create an book cover image that displays the title and author in case book has no book cover.
            if(coverImagePath != nil) {
                chapterImage = [[UIImage alloc] initWithContentsOfFile:coverImagePath];
            }

            //If for some reason the path to the image is broken, or if we didn't have a cover image.
            if(coverImagePath == nil || chapterImage == nil) {
                chapterImage = [[UIImage alloc] init];
                chapterImage = [UIImage imageNamed:@"cover_default"];
            }
            
            //For now, each book is its own section and has no chapters.
            [titlesForBook addObject:chapterTitle];
            [imagesForBook addObject:chapterImage];            
        }
        
        //Each book is it's own section and gets its own array of chapters.
        [self.libraryImages addObject:imagesForBook];
        [self.libraryTitles addObject:titlesForBook];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
    self.libraryView = nil;
    self.libraryImages = nil;
}

//Segue prep to go from LibraryViewController to BookView Controller. 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PMViewController *destination = [segue destinationViewController];
    
    destination.bookImporter = bookImporter;
    destination.bookTitle = self.bookToOpen;
    destination.chapterTitle = self.chapterToOpen;
    
    //Instead of loading the first page, we're going to load the page that was selected.]
    //NSLog(@"chapter to Open: %@", self.chapterToOpen);
    
    //added by James for XML logging
    [[ServerCommunicationController sharedManager] logStoryButtonPressed: @"Library Icon" : @"Tap" : self.bookToOpen : self.chapterToOpen : @"NULL" : @"NULL" : @"NULL"];
    //logging ends here
    
    [destination loadFirstPage];
    
    //Change the back button so that it doesn't show the LibraryView's title and instead shows "Back"
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStyleBordered target: nil action: nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)libraryView {
    //Each book is in its own section, with each chapter laid out.
    
    //NSLog(@"number of books: %d", [books count]);
    return [books count];
}

-(NSInteger)collectionView:(UICollectionView *)libraryView numberOfItemsInSection:(NSInteger)section {
    NSMutableArray *sectionArray = [self.libraryImages objectAtIndex:section];

    //NSLog(@"number of chapters in book: %d", [sectionArray count]);
    return [sectionArray count]; //Return the number of chapters in each book section. 
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)libraryView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //Create cell
    BookCellView *cell = (BookCellView *)[libraryView dequeueReusableCellWithReuseIdentifier:@"BookCellView" forIndexPath:indexPath];

    //Set image.
    NSMutableArray *images = [self.libraryImages objectAtIndex:indexPath.section];
    UIImage *image = [images objectAtIndex:indexPath.row];
    [cell.coverImage setImage:image];

    //Set title. 
    NSMutableArray *titles = [self.libraryTitles objectAtIndex:indexPath.section];
    NSString *title = [titles objectAtIndex:indexPath.row];
    [cell.coverTitle setText:title]; 
    
    // Return the cell
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)libraryView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Ge the title that was selected and set that title to the book that needs to be opened.
    //NSMutableArray *titles = [self.libraryTitles objectAtIndex:indexPath.section];
    //NSString *title = [titles objectAtIndex:indexPath.row];

    Book* book = [books objectAtIndex:indexPath.section];

    NSString *title = [[book title] stringByAppendingString:@" - "];
    title = [title stringByAppendingString:[book author]];
    
    self.bookToOpen = title;
    self.chapterToOpen = [[[book chapters] objectAtIndex:indexPath.row] title];
    
    //Deselect the cell so that it doesn't show as being selected when the user comes back to the library.
    [self.libraryView deselectItemAtIndexPath:indexPath animated:YES];
    
    //Send the notification to open that mode for the particular book and activity chosen.
    if(currentMode == PM_MODE)
        [self performSegueWithIdentifier: @"OpenPMActivitySegue" sender:self];
    else if(currentMode == IM_MODE)
        [self performSegueWithIdentifier: @"OpenIMActivitySegue" sender:self];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: Right now return true, but eventually we'll have to go ahead and display 2 different images based on whether or not
    //the student has completed the activity. This means changing the data source for the collection view and returning no from
    //this function so the student cannot select the item.
    return YES;
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(-6, 16, 15, 16);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {        
        BookHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BookHeaderView" forIndexPath:indexPath];
        
        NSString *title = [[books objectAtIndex:indexPath.section] title];
        headerView.bookTitle.text = title;
        
        reusableview = headerView;
    }
    
    return reusableview;
}

@end
