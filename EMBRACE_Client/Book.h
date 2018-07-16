//
//  Book.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chapter.h"
#import "InteractionModel.h"

@interface Book : NSObject {
    NSString *title;
    NSString *author;
    
    NSString *coverImagePath; //Path of the book cover image.
    NSString *bookPath; //root path of the book:/Documents/<Author Folder>/<Book Folder>
    NSString *mainContentPath; //the root path of where the content is stored.
    
    NSDictionary *bookItems; //manifest items read in from opf file. The key is the id and the object is the href.
    NSMutableArray *itemOrder; //array that keeps track of the order the items should appear in. Stores the ids in order of the hrefs in bookItems.
    
    NSMutableArray *englishChapters;
    NSMutableArray *spanishChapters;
    InteractionModel *model;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;

@property (nonatomic, copy) NSString *coverImagePath;
@property (nonatomic, copy) NSString *bookPath;
@property (nonatomic, copy) NSString* mainContentPath;

@property (nonatomic, strong) NSDictionary *bookItems;
@property (nonatomic, strong) NSMutableArray *itemOrder;

@property (nonatomic, strong) NSMutableArray* englishChapters;
@property (nonatomic, strong) NSMutableArray* spanishChapters;

@property (nonatomic, strong) InteractionModel* model;

- (id) initWithTitleAndAuthor:(NSString*)path :(NSString*)bookTitle :(NSString*)bookAuthor;

- (NSString*) getHTMLURL;

- (NSInteger)totalPages; //Get the total number of pages in the book.

- (NSString*) getPageAt:(int)pageNum; //Get the page at a particular page number;

- (NSString*) getPageForChapter:(NSString*)chapterTitle; //Get the first page of the chapter with the specified chapter title.

- (NSString*) getIdForPageInChapterAndActivity:(NSString*)pagePath :(NSString*)chapterTitle :(Mode)activityMode; //Get the id for the specified page in the chapter with activity

-(void) addEnglishChapter:(Chapter*)chapter; //Add an english chapter to the book as we're reading it in.
-(void) addSpanishChapter:(Chapter*)chapter; //Add an english chapter to the book as we're reading it in.

- (NSMutableArray*) getChapters; // Returns the correct array of chapters based on current condition language

-(NSString*) getNextPageForChapterAndActivity:(NSString*)chapterTitle :(Mode) activity :(NSString*) currentPage; //Get the page number for the specified chapter and activity mode.

-(NSString*) getPreviousPageForChapterAndActivity:(NSString*)chapterTitle :(Mode) activity :(NSString*) currentPage; //Get the page number for the specified chapter and activity mode.

-(NSString* ) getChapterAfterChapter:(NSString* )chapterTitle;

-(NSString* ) getChapterBeforeChapter:(NSString* )chapterTitle;

-(Chapter* ) getChapterWithTitle:(NSString* )chapterTitle;
@end
