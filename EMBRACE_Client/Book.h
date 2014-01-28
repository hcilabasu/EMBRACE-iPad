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
    
    NSMutableArray *chapters;
    InteractionModel *model;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;

@property (nonatomic, strong) NSString *coverImagePath;
@property (nonatomic, strong) NSString *bookPath;
@property (nonatomic, strong) NSString* mainContentPath;

@property (nonatomic, strong) NSDictionary *bookItems;
@property (nonatomic, strong) NSMutableArray *itemOrder;

@property (nonatomic, strong) NSMutableArray* chapters;

@property (nonatomic, strong) InteractionModel* model;

- (id) initWithTitleAndAuthor:(NSString*)path :(NSString*)bookTitle :(NSString*)bookAuthor;

- (NSString*) getHTMLURL;

- (NSInteger)totalPages; //Get the total number of pages in the book.

- (NSString*) getPageAt:(int)pageNum; //Get the page at a particular page number;

- (NSString*) getPageForChapter:(NSString*)chapterTitle; //Get the first page of the chapter with the specified chapter title.

-(void) addChapter:(Chapter*)chapter; //Add a chapter to the book as we're reading it in.

-(NSString*) getNextPageForChapterAndActivity:(NSString*)chapterTitle :(Mode) activity :(NSString*) currentPage; //Get the page number for the specified chapter and activity mode.

-(NSString* ) getChapterAfterChapter:(NSString* )chapterTitle;
@end
