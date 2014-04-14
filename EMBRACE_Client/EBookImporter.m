//
//  Readebook.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "EBookImporter.h"
#import "ActionStep.h"
#import "PhysicalManipulationSolution.h"

@implementation EBookImporter

@synthesize docsDir;
@synthesize dirPaths;
@synthesize library;

- (id) init {
	if (self = [super init]) {
        library = [[NSMutableArray alloc] init];
        [self findDocDir];
	}
	
	return self;
}

- (void) dealloc {
    [super dealloc];
}

// finds the documents directory for the application
- (void) findDocDir {
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                   NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    
    //NSLog(@"documents directory: %@", docsDir);
}

/* This method looks through the Documents directory of the app to find all the books in the
 library. */
-(NSMutableArray*) importLibrary {
    //NSLog(@"In import library");
    NSFileManager *filemgr;
    NSArray *docFileList;
    
    //Starting from the Documents directory of the app.
    filemgr =[NSFileManager defaultManager];
    docFileList = [filemgr contentsOfDirectoryAtPath:docsDir error:NULL];
    
    //Find all the authors directories.
    for (NSString* item in docFileList) {
        NSString* authorPath = [docsDir stringByAppendingString:@"/"];
        authorPath = [authorPath stringByAppendingString:item];
        
        NSDictionary *attribs = [filemgr attributesOfItemAtPath:authorPath error: NULL];
        
        if([attribs objectForKey:NSFileType] == NSFileTypeDirectory) {
            NSArray* authorBookList = [filemgr contentsOfDirectoryAtPath:authorPath error:NULL];
            
            //Find all the book directories for this author.
            for(NSString* bookDir in authorBookList) {
                NSString* bookPath = [authorPath stringByAppendingString:@"/"];
                bookPath = [bookPath stringByAppendingString:bookDir];
                
                NSDictionary *attribsBook = [filemgr attributesOfItemAtPath:bookPath error: NULL];
                
                if([attribsBook objectForKey:NSFileType] == NSFileTypeDirectory) {
                    if(![[(NSString*) bookDir substringToIndex:1] isEqualToString:@"."]) {
                        
                        //Find all the files for this book.
                        NSArray* fileList = [filemgr contentsOfDirectoryAtPath:bookPath error:NULL];
                        
                        for(NSString* file in fileList) {
                            NSString* filePath = [bookPath stringByAppendingString:@"/"];
                            filePath = [filePath stringByAppendingString:file];
                            
                            NSDictionary *attribsFile = [filemgr attributesOfItemAtPath:filePath error: NULL];
                            
                            //make sure we're looking at a file and not a directory.
                            if([attribsFile objectForKey:NSFileType] != NSFileTypeDirectory) {
                                NSRange fileExtensionLoc = [file rangeOfString:@"."];
                                NSString* fileExtension = [file substringFromIndex:fileExtensionLoc.location];
                                
                                //find the epub file and unzip it.
                                if([fileExtension isEqualToString:@".epub"]) {
                                    [self unzipEpub:bookPath :file];
                                }
                            }
                        }
                    }
                }
                
            }
            
        }
    }
    //NSLog(@"at end of import library");
    return library;
    //[filemgr release];
}

//Unzips the epub.
-(void) unzipEpub:(NSString*) filepath :(NSString*) filename{
    //NSLog(@"at beginning of unzip epub for filename: %@", filename);
    NSString *epubFilePath = [filepath stringByAppendingString:@"/"];
    epubFilePath = [epubFilePath stringByAppendingString:filename];
    
    NSString *epubDirectoryPath = [filepath stringByAppendingString:@"/epub/"];
    //NSString *filepath = [[NSBundle mainBundle] pathForResource:@"ZipFileName" ofType:@"zip"];
    
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    
    [zipArchive UnzipOpenFile:epubFilePath];
    [zipArchive UnzipFileTo:epubDirectoryPath overWrite:YES];
    [zipArchive UnzipCloseFile];
    
    [zipArchive release];
    //NSLog(@"at end of unzip epub for filename: %@", filename);
    //read the container to find the path for the opf.
    [self readContainerForBook:filepath];
}

-(Book*) getBookWithTitle:(NSString*) bookTitle{
    NSRange dashRange = [bookTitle rangeOfString:@" - "];
    NSString* title = [bookTitle substringToIndex:dashRange.location];
    NSString* author = [bookTitle substringFromIndex:dashRange.location + dashRange.length];
    
    for(Book *book in library) {
        if(([book.title compare:title] == NSOrderedSame) && ([book.author compare:author] == NSOrderedSame)){
            return book;
            break;
        }
    }
    
    return nil;
}

//Reads the container for the book to get the filepath for the content.opf file.
-(void) readContainerForBook:(NSString*)filepath {
    //NSLog(@"at beginning of read container for book");
    NSString* containerPath = [filepath stringByAppendingString:@"/epub/META-INF/container.xml"];
    
    //Get xml data of the container file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:containerPath];
    
    NSError *error;
    //GDataXMLDocument *containerDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    GDataXMLDocument *containerDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Find the name of the opf file for the book.
    NSArray *rootFiles = [containerDoc.rootElement elementsForName:@"rootfiles"];
    GDataXMLElement *rootFilesElement = (GDataXMLElement *) [rootFiles objectAtIndex:0];
    
    NSArray *rootFileItem = [rootFilesElement elementsForName:@"rootfile"];
    GDataXMLElement *rootFileItemElement = (GDataXMLElement *) [rootFileItem objectAtIndex:0];
    
    NSString *mediaType = [[rootFileItemElement attributeForName:@"media-type"] stringValue];
    
    if([mediaType isEqualToString:@"application/oebps-package+xml"]) {
        NSString* opfBookFile = [[rootFileItemElement attributeForName:@"full-path"] stringValue];
        //Once opf file has been found, read the opf file for the book.
        [self readOpfForBook:opfBookFile :filepath];
    }
    //NSLog(@"at end of read container for book");
}

/* Reads the opf file for the book. This file provides information about the title and author of the book,
 * as well as a list of all the files associated with this book. The spine provides an order for which pages
 * should be displayed. For the purposes of this application, the program will instead use the TOC to identify
 * which pages belong to which part of the book.
 */
-(void) readOpfForBook:(NSString*)filename :(NSString*)filepath {
    //NSLog(@"at beginning of read opf for book. filename: %@ filepath: %@", filename, filepath);
    //Get the filepath of the opf book file.
    NSString *opfFilePath = [filepath stringByAppendingString:@"/epub/"];
    opfFilePath = [opfFilePath stringByAppendingString:filename];
    
    //Get xml data of the opf file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:opfFilePath];
    
    NSError *error;
    //GDataXMLDocument *opfDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    GDataXMLDocument *opfDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Extract metadata, which includes author and title information.
    NSArray *metadataElement = [opfDoc.rootElement elementsForName:@"metadata"];
    GDataXMLElement *metadata = (GDataXMLElement *) [metadataElement objectAtIndex:0];
    Book *book;
    
    //Extract title.
    NSArray *titleElement = [metadata elementsForName:@"dc:title"];
    GDataXMLElement *titleData = (GDataXMLElement *) [titleElement objectAtIndex:0];
    NSString* title = titleData.stringValue;
    
    //Extract author.
    NSArray *authorElement = [metadata elementsForName:@"dc:creator"];
    GDataXMLElement *authorData = (GDataXMLElement *) [authorElement objectAtIndex:0];
    NSString* author = authorData.stringValue;
    
    //if there is no title and author information, go ahead and just list it as Unknown.
    if(title == nil)
        title = @"Unknown";
    if(author == nil)
        author = @"Unknown";
    
    //Create Book with author and title.
    book = [[Book alloc] initWithTitleAndAuthor:filepath :title :author];
    
    //set the mainContentPath so we can access the cover image and all other files of the book.
    NSRange rangeOfContentFile = [opfFilePath rangeOfString:@"content.opf"];
    [book setMainContentPath:[opfFilePath substringToIndex:rangeOfContentFile.location]];
    
    //Extract the cover if it has one.
    //cover image is in <meta content=<> name<>/> inside of metadata.
    //content is the id of the jpg that can be found in the manifest.
    //name is always cover for the cover page.
    //can also be found in the guide as an html, but I'm not sure that will work in this instance.
    NSString* coverFilePath = nil;
    NSString* coverId = nil;
    
    NSArray* metaElement = [metadata elementsForName:@"meta"];
    
    for(GDataXMLElement *element in metaElement) {
        NSString* name = [[element attributeForName:@"name"] stringValue];
        
        if([name compare:@"cover"] == NSOrderedSame) {
            coverId = [[element attributeForName:@"content"] stringValue];
        }
    }
    
    //read manifest items and store them in an NSDictionary for easy access.
    NSArray *manifest = [opfDoc.rootElement elementsForName:@"manifest"];
    GDataXMLElement *manifestElement = (GDataXMLElement *)[manifest objectAtIndex:0];
    
    NSArray *items = [manifestElement elementsForName:@"item"];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    NSMutableArray *hrefs = [[NSMutableArray alloc] init];
    
    for(GDataXMLElement* item in items) {
        NSString* itemId = [[item attributeForName:@"id"] stringValue];
        NSString* itemHref = [[item attributeForName:@"href"] stringValue];
        
        [ids addObject:itemId];
        [hrefs addObject:itemHref];
    }
    
    NSDictionary *bookItems = [[NSDictionary alloc] initWithObjects:hrefs forKeys:ids]; //create NSDictionary.
    [book setBookItems:bookItems]; //it may be unnecessary to store the dictionary directly in the book object...instead we may want to store it elsewhere, or process this data and store it in some other way.
    
    //read spine and store that for the time being. See comment above re: bookItems.
    NSArray *spine = [opfDoc.rootElement elementsForName:@"spine"];
    GDataXMLElement *spineElement = (GDataXMLElement *)[spine objectAtIndex:0];
    
    NSArray* itemOrderElement = [spineElement elementsForName:@"itemref"];
    NSMutableArray *itemOrder = [[NSMutableArray alloc] init];
    
    for(GDataXMLElement* itemRef in itemOrderElement) {
        NSString* itemId = [[itemRef attributeForName:@"idref"] stringValue];
        [itemOrder addObject:itemId];
    }
    
    [book setItemOrder:itemOrder];
    
    if(coverId != nil) {
        //NSLog(@"looking for coverfilename.");
        NSString* coverFilename = [bookItems objectForKey:coverId];
        //NSLog(@"coverfilame: %@", coverFilename);
        coverFilePath = [[book mainContentPath] stringByAppendingString:coverFilename];
        [book setCoverImagePath:coverFilePath];
    }
    
    //Read the TOC for the book and create any Chapters and Activities as necessary.
    [self readTOCForBook:book];
    
    //Read the metadata for the book
    [self readMetadataForBook:book];
    
    [library addObject:book];
    
    NSLog(@"at end of read opf for book");
}

//TOC is in the same location as the .opf file. That means that we can use the mainContentPath to find it.
//TOC file is always named toc.ncx
-(void) readTOCForBook:(Book*)book {
    //NSLog(@"in beginning of TOC for book");
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"toc.ncx"];
    
    //Get xml data of the toc file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    NSError *error;
    //GDataXMLDocument *tocDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    GDataXMLDocument *tocDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Get the list of chapters from the NavMap first.
    //_def_ns is the default namespace for GDataXML. Must use that or register our own namespace.
    NSArray* chapterList = [tocDoc nodesForXPath:@"//_def_ns:navPoint[@class='ChapterTitle']" error:nil];
    
    for(GDataXMLElement* chapterNode in chapterList) {
        Chapter *currChapter = [[Chapter alloc] init]; //Create a new chapter.
        
        //Get the ChapterId
        NSString* chapterId = [[chapterNode attributeForName:@"id"] stringValue];
        [currChapter setChapterId:chapterId];
        
        //Get the chapter title from the navLabel text
        GDataXMLElement* navLabelElement = [[chapterNode elementsForName:@"navLabel"] objectAtIndex:0];
        GDataXMLElement* navLabelTextElement =  [[navLabelElement elementsForName:@"text"] objectAtIndex:0];
        [currChapter setTitle:[navLabelTextElement stringValue]];
        
        //NSLog(@"chapter title: %@", [currChapter title]);
        
        //Get the title page and the image for the chapter
        GDataXMLElement* contentElement = [[chapterNode elementsForName:@"content"] objectAtIndex:0];
        NSString* chapterFilename = [[contentElement attributeForName:@"src"] stringValue];
        [currChapter setChapterTitlePage:[[book mainContentPath] stringByAppendingString:chapterFilename]];
        
        //Extract the image from the chapter title page.
        [self extractCoverForChapter:book :currChapter];
        
        //NSLog(@"image path: %@", [currChapter chapterImagePath]);
        
        //Read in all pages associated with this chapter.
        NSArray *pageElements = [chapterNode elementsForName:@"navPoint"];
        //NSLog(@"number of pages for chapter %@: %d", [currChapter title], [pageElements count]);
        
        //For each page, we'll have to create an Activity if it belongs to a specific type of activity. Otherwise, we just add it as a page. If an Activity contains additional pages, we'll have to ensure that we add it to the existing activity, instead of creating a new one.
        for(GDataXMLElement* element in pageElements){
            NSString* modeType = [[element attributeForName:@"class"] stringValue];
            NSString* pageId = [[element attributeForName:@"id"] stringValue]; //Get the ID.
            
            Page *currPage = [[Page alloc] init];
            [currPage setPageId:pageId];
            
            GDataXMLElement *pagePathElement = [[element elementsForName:@"content"] objectAtIndex:0];
            NSString* pagePathFilename = [[pagePathElement attributeForName:@"src"] stringValue];
            [currPage setPagePath:[[book mainContentPath] stringByAppendingString:pagePathFilename]];
            
            //NSLog(@"current page id:%@ and path:%@", [currPage pageId], [currPage pagePath]);
            
            //For the moment make the assumption that the first IM that you come across is the one that you create the activity for..and for all other IM pages you just add it to that activity.
            
            bool newActivity = FALSE;
            Activity *currActivity;
            if([modeType isEqualToString:@"PM_MODE"]) {
                currActivity= [currChapter getActivityOfType:PM_MODE];
                
                //the chapter doesn't currently have an Activity of the current type.
                if(currActivity == nil) {
                    currActivity = [[PhysicalManipulationActivity alloc] init];
                    newActivity = TRUE;
                }
            }
            else if([modeType isEqualToString:@"IM_MODE"]) {
                currActivity = [currChapter getActivityOfType:IM_MODE];
                
                if(currActivity == nil) {
                    currActivity = [[ImagineManipulationActivity alloc] init];
                    newActivity = TRUE;
                }
            }
            else {
                currActivity = [[Activity alloc] init]; //Generic activity since I have no idea what it is.
                newActivity = TRUE;
            }
            
            [currActivity setActivityId:pageId ];
            [currActivity addPage:currPage];
            
            //Get the title of the activity. Don't care about this right now.
            GDataXMLElement *activityTitleElement = [[element elementsForName:@"navLabel"] objectAtIndex:0];
            NSString* activityTitle = [activityTitleElement stringValue];
            [currActivity setActivityTitle:activityTitle];
            
            //If we had to create an activity that doesn't exist in the chapter..add the activity.
            if (newActivity) {
                //NSLog(@"adding activity with title:%@ to chapter: %@", [currActivity activityTitle], [currChapter title]);
                [currChapter addActivity:currActivity];
            }
        }
        
        //NSLog(@"number of activities in chapter: %d", [[currChapter activities] count]);
        
        //Add chapter to book.
        [book addChapter:currChapter];
    }
    
    //NSLog(@"at end of read TOC for book. number in chapterList: %d", [chapterList count]);
}

-(void) extractCoverForChapter:(Book*)book :(Chapter*) chapter {
    NSData *htmlData = [[NSMutableData alloc] initWithContentsOfFile:[chapter chapterTitlePage]];
    
    NSError *error;
    //Get the html data of the chapter title page.
    GDataXMLDocument *chapterTitlePage = [[GDataXMLDocument alloc] initWithHTMLData:htmlData error:&error];
    
    //Find the cover image and extract the path to the image.
    NSArray* coverImageDivElements = [chapterTitlePage nodesForXPath:@"//div[@class='cover']" error:nil];
    
    GDataXMLElement* coverImageDivElement = [coverImageDivElements objectAtIndex:0];
    
    GDataXMLElement *coverImageElement = [[coverImageDivElement elementsForName:@"img"] objectAtIndex:0];
    
    NSString* chapterFilename = [[coverImageElement attributeForName:@"src"] stringValue];
    
    NSRange filenameRange = [chapterFilename rangeOfString:@".."];
    chapterFilename = [chapterFilename substringFromIndex:filenameRange.location + filenameRange.length];
    
    NSString*  chapterFilePath = [[book mainContentPath] stringByAppendingString:chapterFilename];
    
    [chapter setChapterImagePath:chapterFilePath];
}

-(void) readMetadataForBook:(Book*) book {
    //NSLog(@"at beginning of read metadata for book");
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"metadata.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    NSError *error;
    //GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    InteractionModel *model = [book model];
    
    //Read in the Relationship information
    NSArray* relationshipsElements = [metadataDoc nodesForXPath:@"//relationships" error:nil];
    GDataXMLElement *relationshipsElement = (GDataXMLElement *) [relationshipsElements objectAtIndex:0];
    
    NSArray* relationships = [relationshipsElement elementsForName:@"relationship"];
    
    for(GDataXMLElement *relationship in relationships){
        NSString* obj1Id = [[relationship attributeForName:@"obj1Id"] stringValue];
        NSString* can = [[relationship attributeForName:@"can"] stringValue];
        NSString* type = [[relationship attributeForName:@"action"] stringValue];
        NSString* obj2Id = [[relationship attributeForName:@"obj2Id"] stringValue];
        
        [model addRelationship:obj1Id :can :type :obj2Id];
    }
    
    //Read in the Constraints
    NSArray* constraintsElements = [metadataDoc nodesForXPath:@"//constraints" error:nil];
    GDataXMLElement *constraintsElement = (GDataXMLElement *) [constraintsElements objectAtIndex:0];
    
    //NSArray * constraints = [constraintsElement elementsForName:@"constraint"];
    /*for(GDataXMLElement *constraint in constraints) {
     NSString* action1 = [[constraint attributeForName:@"action1"] stringValue];
     NSString* rule = [[constraint attributeForName:@"rule"] stringValue];
     NSString* action2 = [[constraint attributeForName:@"action2"] stringValue];
     
     [model addConstraint:action1 :action2 :rule];
     }*/
    
    //Get movement constraints
    NSArray * movementConstraintsElements = [constraintsElement elementsForName:@"movementConstraints"];
    GDataXMLElement *movementConstraintsElement = (GDataXMLElement *) [movementConstraintsElements objectAtIndex:0];
    
    NSArray *movementConstraints = [movementConstraintsElement elementsForName:@"constraint"];
    
    for(GDataXMLElement *constraint in movementConstraints) {
        NSString* objectId = [[constraint attributeForName:@"objId"] stringValue];
        NSString* action = [[constraint attributeForName:@"action"] stringValue];
        NSString* originX = [[constraint attributeForName:@"x"] stringValue];
        NSString* originY = [[constraint attributeForName:@"y"] stringValue];
        NSString* width = [[constraint attributeForName:@"width"] stringValue];
        NSString* height = [[constraint attributeForName:@"height"] stringValue];
        
        [model addMovementConstraint:objectId :action :originX :originY :width :height];
    }
    //Get order constraints
    NSArray *orderConstraintsElements = [constraintsElement elementsForName:@"orderConstraints"];
    GDataXMLElement *orderConstraintsElement = (GDataXMLElement *) [orderConstraintsElements objectAtIndex:0];
    
    NSArray *orderConstraints = [orderConstraintsElement elementsForName:@"constraint"];
    
    for(GDataXMLElement *constraint in orderConstraints) {
        NSString* action1 = [[constraint attributeForName:@"action1"] stringValue];
        NSString* rule = [[constraint attributeForName:@"rule"] stringValue];
        NSString* action2 = [[constraint attributeForName:@"action2"] stringValue];
        
        [model addOrderConstraint:action1 :action2 :rule];
    }
    
    //Reading in the hotspot information.
    NSArray* hotspotsElements = [metadataDoc nodesForXPath:@"//hotspots" error:nil];
    GDataXMLElement *hotspotsElement = (GDataXMLElement *)[hotspotsElements objectAtIndex:0];
    
    NSArray* hotspots = [hotspotsElement elementsForName:@"hotspot"];
    
    //Read in the hotspot information.
    for(GDataXMLElement *hotspot in hotspots) {
        NSString* objectId = [[hotspot attributeForName:@"objId"] stringValue];
        NSString* action = [[hotspot attributeForName:@"action"] stringValue];
        NSString* role = [[hotspot attributeForName:@"role" ] stringValue];
        NSString* locationXString = [[hotspot attributeForName:@"x"] stringValue];
        NSString* locationYString = [[hotspot attributeForName:@"y"] stringValue];
        
        //Find the range of "," in the location string.
        CGFloat locX = [locationXString floatValue];
        CGFloat locY = [locationYString floatValue];
        
        CGPoint location = CGPointMake(locX, locY);
        //[model addHotspot:objectId :location];
        [model addHotspot:objectId :action :role :location];
    }
    
    //Read in any setup information.
    NSArray* setupElements = [metadataDoc nodesForXPath:@"//setups" error:nil];
    GDataXMLElement* setupElement = (GDataXMLElement*)[setupElements objectAtIndex:0];
    
    NSArray* storySetupElements = [setupElement elementsForName:@"story"];
    
    for(GDataXMLElement* storySetupElement in storySetupElements) {
        //Get story title
        NSString* storyTitle = [[storySetupElement attributeForName:@"title"] stringValue];
        Chapter* chapter = [book getChapterWithTitle:storyTitle];
        //NSLog(@"chapter name:%@", [chapter title]);
        if(chapter != nil) {
            PhysicalManipulationActivity* PMActivity = (PhysicalManipulationActivity*)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
            
            NSArray* storySetupSteps = [storySetupElement children];
            
            for(GDataXMLElement* storySetupStep in storySetupSteps) {
                //Uses the same format as the solutions. Can we create the Connection object? Should we rename it to something else?
                //<setup obj1Id="cart" action="hook" obj2Id="tractor"/>
                
                //Get setup step information
                NSString* stepType = [storySetupStep name];
                NSString* obj1Id = [[storySetupStep attributeForName:@"obj1Id"] stringValue];
                NSString* action = [[storySetupStep attributeForName:@"action"] stringValue];
                NSString* obj2Id = [[storySetupStep attributeForName:@"obj2Id"] stringValue];
                
                ActionStep* setupStep = [[ActionStep alloc] initAsSetupStep:stepType :obj1Id :obj2Id :action];
                [PMActivity addSetupStep:setupStep];
            }
        }
    }
    
    //Read in the solutions and add them to the PhysicalManipulationActivity they belong to.
    NSArray* solutionsElements = [metadataDoc nodesForXPath:@"//solutions" error:nil];
    GDataXMLElement* solutionsElement = (GDataXMLElement*)[solutionsElements objectAtIndex:0];
    
    NSArray* storySolutions = [solutionsElement elementsForName:@"story"];
    
    for(GDataXMLElement* solution in storySolutions) {
        //Get story title
        NSString* title = [[solution attributeForName:@"title"] stringValue];
        Chapter* chapter = [book getChapterWithTitle:title];
        //NSLog(@"chapter name:%@", [chapter title]);
        
        if (chapter != nil) {
            PhysicalManipulationActivity* PMActivity = (PhysicalManipulationActivity*)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
            PhysicalManipulationSolution* PMSolution = [PMActivity PMSolution]; //get PM solution
            
            NSArray* sentenceSolutions = [solution elementsForName:@"sentence"];
            
            for(GDataXMLElement* sentence in sentenceSolutions) {
                //Get sentence number
                int sentenceNumber = [[[sentence attributeForName:@"number"] stringValue] integerValue];
                NSNumber* sentenceNum = [NSNumber numberWithInt:sentenceNumber];
                
                NSArray* stepSolutions = [sentence elementsForName:@"step"];
                
                for(GDataXMLElement* stepSolution in stepSolutions) {
                    //Get step number
                    int stepNumber = [[[stepSolution attributeForName:@"number"] stringValue] integerValue];
                    NSNumber* stepNum = [NSNumber numberWithInt:stepNumber];
                    
                    //Get solution steps for sentence.
                    NSArray* stepsForSentence = [stepSolution children];
                    
                    for(GDataXMLElement* step in stepsForSentence) {
                        NSString* stepType = [step name]; //get step type
                        
                        //All solution step types have at least an obj1Id and action
                        NSString* obj1Id = [[step attributeForName:@"obj1Id"] stringValue];
                        NSString* action = [[step attributeForName:@"action"] stringValue];
                        
                        //Group and ungroup also have an obj2Id
                        if([[step name] isEqualToString:@"group"] || [[step name] isEqualToString:@"ungroup"]) {
                            NSString* obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
                            
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :obj2Id :nil :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                        //Move also has either an obj2Id or waypointId
                        else if([[step name] isEqualToString:@"move"]) {
                            if([step attributeForName:@"obj2Id"]) {
                                NSString* obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
                                
                                ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :obj2Id :nil :nil :action];
                                [PMSolution addSolutionStep:solutionStep];
                            }
                            else if([step attributeForName:@"waypointId"]) {
                                NSString* waypointId = [[step attributeForName:@"waypointId"] stringValue];
                                
                                ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :nil :nil :waypointId :action];
                                [PMSolution addSolutionStep:solutionStep];
                            }
                        }
                        //Check also has a locationId
                        else if([[step name] isEqualToString:@"check"]) {
                            NSString* locationId = [[step attributeForName:@"locationId"] stringValue];
                            
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :nil :locationId :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                        //Disappear also has an obj2Id
                        else if([[step name] isEqualToString:@"disappear"]) {
                            NSString* obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
                            
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :obj2Id :nil :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                    }
                }
            }
            //NSLog(@"chapter:%@, steps:%d",[chapter title], [[PMSolution solutionSteps] count]);
        }
    }
}

@end
