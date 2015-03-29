//
//  Readebook.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "EBookImporter.h"

@implementation EBookImporter

@synthesize docsDir;
@synthesize dirPaths;
@synthesize library;

ConditionSetup *conditionSetup;

- (id) init {
	if (self = [super init]) {
        library = [[NSMutableArray alloc] init];
        [self findDocDir];
        // Create an instance of  ConditionSetup
        conditionSetup = [[ConditionSetup alloc] init];
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
}

//Unzips the epub.
-(void) unzipEpub:(NSString*) filepath :(NSString*) filename{
    //NSLog(@"at beginning of unzip epub for filename: %@", filename);
    NSString *epubFilePath = [filepath stringByAppendingString:@"/"];
    epubFilePath = [epubFilePath stringByAppendingString:filename];
    
    NSString *epubDirectoryPath = [filepath stringByAppendingString:@"/epub/"];
    
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
    NSString *filepath = nil;

    if(conditionSetup.language == BILINGUAL){
        filepath = [[book mainContentPath] stringByAppendingString:@"toc.ncx"];
    } else if (conditionSetup.language == ENGLISH) {
        filepath = [[book mainContentPath] stringByAppendingString:@"tocE.ncx"];
    }
    
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
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"Relationships-MetaData.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    NSError *error;
    //GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    
    
    //break out metadata file into seperate components
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
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Constraints-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in the Constraints
    NSArray* constraintsElements = [metadataDoc nodesForXPath:@"//constraints" error:nil];
    GDataXMLElement *constraintsElement = (GDataXMLElement *) [constraintsElements objectAtIndex:0];

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
    
    //Get combo constraints
    NSArray *comboConstraintsElements = [constraintsElement elementsForName:@"comboConstraints"];
    GDataXMLElement *comboConstraintsElement = (GDataXMLElement *) [comboConstraintsElements objectAtIndex:0];
    
    NSArray *comboConstraints = [comboConstraintsElement elementsForName:@"constraint"];
    
    for (GDataXMLElement *constraint in comboConstraints) {
        //Get the object that this constraint applies to
        NSString* objectId = [[constraint attributeForName:@"objId"] stringValue];
        
        //Create an array to hold all the actions/hotspots that cannot be used at the same time
        NSMutableArray* comboActs = [[NSMutableArray alloc] init];
        
        NSArray *comboActions = [constraint elementsForName:@"comboAction"];
        
        for (GDataXMLElement *comboAction in comboActions) {
            //Get the action
            NSString* action = [[comboAction attributeForName:@"action"] stringValue];
            
            [comboActs addObject:action]; //add the action to the array
        }
        
        [model addComboConstraint:objectId :comboActs];
    }
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Hotspots-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
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
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Locations-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Reading in the location information.
    NSArray* locationElements = [metadataDoc nodesForXPath:@"//locations" error:nil];
    GDataXMLElement* locationElement = (GDataXMLElement*)[locationElements objectAtIndex:0];
    
    NSArray* locations = [locationElement elementsForName:@"location"];
    
    //Read in the location information.
    for (GDataXMLElement* location in locations) {
        NSString* locationId = [[location attributeForName:@"locationId"] stringValue];
        NSString* originX = [[location attributeForName:@"x"] stringValue];
        NSString* originY = [[location attributeForName:@"y"] stringValue];
        NSString* height = [[location attributeForName:@"height"] stringValue];
        NSString* width = [[location attributeForName:@"width"] stringValue];
        
        [model addLocation:locationId :originX :originY :height :width];
    }
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Waypoints-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Reading in the waypoint information.
    NSArray* waypointElements = [metadataDoc nodesForXPath:@"//waypoints" error:nil];
    GDataXMLElement* waypointElement = (GDataXMLElement*)[waypointElements objectAtIndex:0];
    
    NSArray* waypoints = [waypointElement elementsForName:@"waypoint"];
    
    //Read in the waypoint information.
    for (GDataXMLElement* waypoint in waypoints) {
        NSString* waypointId = [[waypoint attributeForName:@"waypointId"] stringValue];
        NSString* locationXString = [[waypoint attributeForName:@"x"] stringValue];
        NSString* locationYString = [[waypoint attributeForName:@"y"] stringValue];
        
        //Find the range of "," in the location string.
        CGFloat locX = [locationXString floatValue];
        CGFloat locY = [locationYString floatValue];
        
        CGPoint location = CGPointMake(locX, locY);

        [model addWaypoint:waypointId :location];
    }
    
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"AlternateImages-MetaData.xml"];
    //NSLog("filepath: %@", filepath);
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    //Read in any alternate image information
    NSArray* altImageElements = [metadataDoc nodesForXPath:@"//alternateImages" error:nil];
    
    if ([altImageElements count] > 0) {
        GDataXMLElement* altImageElement = (GDataXMLElement*)[altImageElements objectAtIndex:0];
        
        NSArray* altImages = [altImageElement elementsForName:@"alternateImage"];
        
        for (GDataXMLElement* altImage in altImages) {
            NSString* objectId = [[altImage attributeForName:@"objId"] stringValue];
            NSString* action = [[altImage attributeForName:@"action"] stringValue];
            NSString* originalSrc = [[altImage attributeForName:@"originalSrc"] stringValue];
            NSString* alternateSrc = [[altImage attributeForName:@"alternateSrc"] stringValue];
            NSString* width = [[altImage attributeForName:@"width"] stringValue];
            NSString* locationXString = [[altImage attributeForName:@"x"] stringValue];
            NSString* locationYString = [[altImage attributeForName:@"y"] stringValue];
            
            //Find the range of "," in the location string.
            CGFloat locX = [locationXString floatValue];
            CGFloat locY = [locationYString floatValue];
            
            CGPoint location = CGPointMake(locX, locY);
            
            [model addAlternateImage:objectId :action :originalSrc :alternateSrc :width :location];
        }
    }
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Setups-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in any setup information.
    NSArray* setupElements = [metadataDoc nodesForXPath:@"//setups" error:nil];
    GDataXMLElement* setupElement = (GDataXMLElement*)[setupElements objectAtIndex:0];
    
    NSArray* storySetupElements = [setupElement elementsForName:@"story"];
    
    for(GDataXMLElement* storySetupElement in storySetupElements) {
        //Get story title
        NSString* storyTitle = [[storySetupElement attributeForName:@"title"] stringValue];
        Chapter* chapter = [book getChapterWithTitle:storyTitle];
        
        //Get page id
        NSString* pageId = [[storySetupElement attributeForName:@"page_id"] stringValue];
        
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
                [PMActivity addSetupStep:setupStep forPageId:pageId];
            }
        }
    }

    //set file path to access introduction metadata
    if (conditionSetup.condition ==CONTROL) {
        filepath = [[book mainContentPath] stringByAppendingString:@"IMSolutions-MetaData.xml"];
    }
    else
    {
        filepath = [[book mainContentPath] stringByAppendingString:@"Solutions-MetaData.xml"];
    }
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in the solutions and add them to the PhysicalManipulationActivity they belong to.
    NSArray* solutionsElements = [metadataDoc nodesForXPath:@"//solutions" error:nil];
    GDataXMLElement* solutionsElement = (GDataXMLElement*)[solutionsElements objectAtIndex:0];
    
    NSArray* storySolutions = [solutionsElement elementsForName:@"story"];
    
    for(GDataXMLElement* solution in storySolutions) {
        //Get story title
        NSString* title = [[solution attributeForName:@"title"] stringValue];
        Chapter* chapter = [book getChapterWithTitle:title];
        
        if (chapter != nil) {
            PhysicalManipulationActivity* PMActivity = (PhysicalManipulationActivity*)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
            PhysicalManipulationSolution* PMSolution = [PMActivity PMSolution]; //get PM solution
            
            NSArray* sentenceSolutions = [solution elementsForName:@"sentence"];
                
            for(GDataXMLElement* sentence in sentenceSolutions) {
                //Get sentence number
                NSUInteger sentenceNum = [[[sentence attributeForName:@"number"] stringValue] integerValue];
                
                NSArray* stepSolutions = [sentence elementsForName:@"step"];
                
                for(GDataXMLElement* stepSolution in stepSolutions) {
                    //Get step number
                    NSUInteger stepNum = [[[stepSolution attributeForName:@"number"] stringValue] integerValue];
                    
                    //Get solution steps for sentence.
                    NSArray* stepsForSentence = [stepSolution children];
                    
                    for(GDataXMLElement* step in stepsForSentence) {
                        NSString* stepType = [step name]; //get step type
                        
                        //All solution step types have at least an obj1Id and action
                        NSString* obj1Id = [[step attributeForName:@"obj1Id"] stringValue];
                        NSString* action = [[step attributeForName:@"action"] stringValue];
                        
                        //TransferAndGroup, transferAndDisappear, group, disappear, and ungroup also have an obj2Id
                        //* TransferAndGroup and transferAndDisappear steps come in pairs. The first is treated as an ungroup step,
                        //while the second may be either group or disappear.
                        //* Group means that two objects should be connected.
                        //* Disappear means that when two objects are close together, one should disappear.
                        //* Ungroup means that two objects that were connected should be separated.
                        if([[step name] isEqualToString:@"transferAndGroup"] || [[step name] isEqualToString:@"transferAndDisappear"] || [[step name] isEqualToString:@"group"] || [[step name] isEqualToString:@"disappear"] ||
                           [[step name] isEqualToString:@"ungroup"]) {
                            NSString* obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
                            
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :obj2Id :nil :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                        //Move also has either an obj2Id or waypointId
                        //* Move is performed automatically and means that an object should be moved to group with another object
                        //or to a waypoint on the background.
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
                        //* Check means that an object should be moved to be inside a location (defined by a bounding box) on
                        //the background.
                        else if([[step name] isEqualToString:@"check"]) {
                            NSString* locationId = [[step attributeForName:@"locationId"] stringValue];
                            
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :nil :locationId :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                        //SwapImage and checkAndSwap only have obj1Id and action
                        //* SwapImage is performed automatically and means that an object's image should be changed to its alternate
                        //image.
                        //* CheckAndSwap means that the correct object must be tapped by the user before changing to its alternate
                        //image.
                        else if([[step name] isEqualToString:@"swapImage"] || [[step name] isEqualToString:@"checkAndSwap"]) {
                            ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :nil :nil :nil :action];
                            [PMSolution addSolutionStep:solutionStep];
                        }
                        
                        else if([[step name] isEqualToString:@"animate"]) {
                            if([step attributeForName:@"waypointId"]) {
                                NSString* waypointId = [[step attributeForName:@"waypointId"] stringValue];
                                
                                ActionStep* solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :stepNum :stepType :obj1Id :nil :nil :waypointId :action];
                                [PMSolution addSolutionStep:solutionStep];
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    //set file path to access introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"Introductions-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in the introduction information
    NSArray* introductionElements = [metadataDoc nodesForXPath:@"//introductions" error:nil];
    
    if ([introductionElements count] > 0)
    {
        GDataXMLElement *introductionElement = (GDataXMLElement *) [introductionElements objectAtIndex:0];

        NSArray* introductions = [introductionElement elementsForName:[NSString stringWithFormat:@"%@%@",[conditionSetup ReturnConditionEnumToString:conditionSetup.condition], @"Introduction"]];
        
        for(GDataXMLElement* introduction in introductions) {
            //Get story title.
            NSString* title = [[introduction attributeForName:@"title"] stringValue];
            NSArray* steps = [introduction elementsForName:@"introductionStep"];
            NSMutableArray* introSteps = [[NSMutableArray alloc] init];
            
            for(GDataXMLElement* step in steps) {
                //Get step number
                int stepNum = [[[step attributeForName:@"number"] stringValue] integerValue];
                
                //Get English audio file name
                NSArray* englishAudioFileNames = [step elementsForName:@"englishAudio"];
                GDataXMLElement *gdataElement = (GDataXMLElement *)[englishAudioFileNames objectAtIndex:0];
                NSString* englishAudioFileName = gdataElement.stringValue;
                
                //Get Spanish audio file name
                NSArray* spanishAudioFileNames = [step elementsForName:@"spanishAudio"];
                gdataElement = (GDataXMLElement *)[spanishAudioFileNames objectAtIndex:0];
                NSString* spanishAudioFileName = gdataElement.stringValue;
                
                //Get English text
                NSArray* englishTexts = [step elementsForName:@"englishText"];
                gdataElement = (GDataXMLElement *)[englishTexts objectAtIndex:0];
                NSString* englishText = gdataElement.stringValue;
                
                //Get Spanish text
                NSArray* spanishTexts = [step elementsForName:@"spanishText"];
                gdataElement = (GDataXMLElement *)[spanishTexts objectAtIndex:0];
                NSString* spanishText = gdataElement.stringValue;
                
                //Each step may or may not have an expected action, input and selection
                //In some cases it could be the three of them e.g. tap farmer word
                //In other cases it would just be two e.g. tap next
                
                //Get the expected selection
                NSArray* expectedSelections = [step elementsForName:@"expectedSelection"];
                gdataElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString* expectedSelection = gdataElement.stringValue;
                
                //Get expected action
                NSArray* expectedActions = [step elementsForName:@"expectedAction"];
                gdataElement = (GDataXMLElement *)[expectedActions objectAtIndex:0];
                NSString* expectedAction = gdataElement.stringValue;
                
                //Get expected input
                NSArray* expectedInputs = [step elementsForName:@"expectedInput"];
                gdataElement = (GDataXMLElement *)[expectedInputs objectAtIndex:0];
                NSString* expectedInput = gdataElement.stringValue;
                
                IntroductionStep* introStep = [[IntroductionStep alloc] initWithValues:stepNum:englishAudioFileName:spanishAudioFileName:englishText:spanishText:expectedSelection:expectedAction: expectedInput];
                [introSteps addObject:introStep];
                
            }
            [model addIntroduction:title:introSteps];
        }
    }
    
    //set file path to access Vocabulary introduction metadata
    filepath = [[book mainContentPath] stringByAppendingString:@"VocabularyIntroductions-MetaData.xml"];
    
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    //break out metadata file into seperate components
    metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in the vocabulary information
    NSArray* vocabIntroductionElements = [metadataDoc nodesForXPath:@"//vocabularyIntroductions" error:nil];
    
    if ([vocabIntroductionElements count] > 0)
    {
        GDataXMLElement *vocabIntroductionElement = (GDataXMLElement *) [vocabIntroductionElements objectAtIndex:0];
        
        NSArray* vocabIntroductions = [vocabIntroductionElement elementsForName:@"vocabularyIntroduction"];
        
        for(GDataXMLElement* vocabIntroduction in vocabIntroductions) {
            //Get story title.
            NSString* storyTitle = [[vocabIntroduction attributeForName:@"story"] stringValue];
            NSArray* words = [vocabIntroduction elementsForName:@"vocabularyIntroductionWord"];
            NSMutableArray* storyWords = [[NSMutableArray alloc] init];
            
            for(GDataXMLElement* word in words) {
                //Get step number
                int wordNum = [[[word attributeForName:@"number"] stringValue] integerValue];
                
                //Get English audio file name
                NSArray* englishAudioFileNames = [word elementsForName:@"englishWordAudio"];
                GDataXMLElement *gdataElement = (GDataXMLElement *)[englishAudioFileNames objectAtIndex:0];
                NSString* englishAudioFileName = gdataElement.stringValue;
                
                //Get Spanish audio file name
                NSArray* spanishAudioFileNames = [word elementsForName:@"spanishWordAudio"];
                gdataElement = (GDataXMLElement *)[spanishAudioFileNames objectAtIndex:0];
                NSString* spanishAudioFileName = gdataElement.stringValue;
                
                //Get English text
                NSArray* englishTexts = [word elementsForName:@"englishWordText"];
                gdataElement = (GDataXMLElement *)[englishTexts objectAtIndex:0];
                NSString* englishText = gdataElement.stringValue;
                
                //Get Spanish text
                NSArray* spanishTexts = [word elementsForName:@"spanishWordText"];
                gdataElement = (GDataXMLElement *)[spanishTexts objectAtIndex:0];
                NSString* spanishText = gdataElement.stringValue;
                
                //Each step may or may not have an expected action, input and selection
                //In some cases it could be the three of them e.g. tap farmer word
                //In other cases it would just be two e.g. tap next
                
                //Get the expected selection
                NSArray* expectedSelections = [word elementsForName:@"expectedSelection"];
                gdataElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString* expectedSelection = gdataElement.stringValue;
                
                //Get expected action
                NSArray* expectedActions = [word elementsForName:@"expectedAction"];
                gdataElement = (GDataXMLElement *)[expectedActions objectAtIndex:0];
                NSString* expectedAction = gdataElement.stringValue;
                
                //Get expected input
                NSArray* expectedInputs = [word elementsForName:@"expectedInput"];
                gdataElement = (GDataXMLElement *)[expectedInputs objectAtIndex:0];
                NSString* expectedInput = gdataElement.stringValue;
                
                VocabularyStep* vocabStep = [[VocabularyStep alloc] initWithValues:wordNum:englishAudioFileName:spanishAudioFileName:englishText:spanishText:expectedSelection:expectedAction: expectedInput];
                [storyWords addObject:vocabStep];
                
            }
            [model addVocabulary:storyTitle:storyWords];
        }
    }
    
    //NSLog(@"at beginning of read metadata for book");
    filepath = [[book mainContentPath] stringByAppendingString:@"AssessmentActivities-MetaData.xml"];
    
    //NSLog(filepath);
    //Get xml data of the metadata file.
    xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    GDataXMLDocument *assessmentMetadataDoc;
    //break out metadata file into seperate components
    assessmentMetadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    //Read in the assessment activity information
    NSArray* AssessmentActivityElements = [assessmentMetadataDoc nodesForXPath:@"//ActivityAssessment" error:nil];
    
    if ([AssessmentActivityElements count] > 0)
    {
        GDataXMLElement *AssessmentActivityElement = (GDataXMLElement *) [AssessmentActivityElements objectAtIndex:0];
        
        NSArray* AssessmentActivities = [AssessmentActivityElement elementsForName:@"Questions"];
        
        for(GDataXMLElement* activity in AssessmentActivities) {
            //Get story title.
            NSString* title = [[activity attributeForName:@"title"] stringValue];
            NSArray* questions = [activity elementsForName:@"Question"];
            NSMutableArray* StoryQuestions = [[NSMutableArray alloc] init];
            
            for(GDataXMLElement* question in questions) {
                
                //Get Answer number
                int QuestionNum = [[[question attributeForName:@"number"] stringValue] integerValue];
                
                //Get Question Text
                NSArray* questionText = [question elementsForName:@"QuestionText"];
                GDataXMLElement *gdataElement = (GDataXMLElement *)[questionText objectAtIndex:0];
                NSString* QuestionText = gdataElement.stringValue;
                
                NSArray* questionAudio = [question elementsForName:@"QuestionAudio"];
                gdataElement = (GDataXMLElement *)[questionAudio objectAtIndex:0];
                NSString* QuestionAudio = gdataElement.stringValue;
                
                //Get 1st Answer
                NSArray* answer1 = [question elementsForName:@"Answer1"];
                gdataElement = (GDataXMLElement *)[answer1 objectAtIndex:0];
                NSString* Answer1 = gdataElement.stringValue;
                
                NSArray* answer1Audio = [question elementsForName:@"Answer1Audio"];
                gdataElement = (GDataXMLElement *)[answer1Audio objectAtIndex:0];
                NSString* Answer1Audio = gdataElement.stringValue;
                
                //Get 2nd Answer
                NSArray* answer2 = [question elementsForName:@"Answer2"];
                gdataElement = (GDataXMLElement *)[answer2 objectAtIndex:0];
                NSString* Answer2 = gdataElement.stringValue;
                
                NSArray* answer2Audio = [question elementsForName:@"Answer2Audio"];
                gdataElement = (GDataXMLElement *)[answer2Audio objectAtIndex:0];
                NSString* Answer2Audio = gdataElement.stringValue;
                
                //Get 3rd Answer
                NSArray* answer3 = [question elementsForName:@"Answer3"];
                gdataElement = (GDataXMLElement *)[answer3 objectAtIndex:0];
                NSString* Answer3 = gdataElement.stringValue;
                
                NSArray* answer3Audio = [question elementsForName:@"Answer3Audio"];
                gdataElement = (GDataXMLElement *)[answer3Audio objectAtIndex:0];
                NSString* Answer3Audio = gdataElement.stringValue;
                
                //Get 4th Answer
                NSArray* answer4 = [question elementsForName:@"Answer4"];
                gdataElement = (GDataXMLElement *)[answer4 objectAtIndex:0];
                NSString* Answer4 = gdataElement.stringValue;
                
                NSArray* answer4Audio = [question elementsForName:@"Answer4Audio"];
                gdataElement = (GDataXMLElement *)[answer4Audio objectAtIndex:0];
                NSString* Answer4Audio = gdataElement.stringValue;
                
                //Get the expected selection
                NSArray* expectedSelections = [question elementsForName:@"expectedSelection"];
                gdataElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString* expectedSelection = gdataElement.stringValue;
                
                AssessmentActivity* storyquestion = [[AssessmentActivity alloc] initWithValues:QuestionNum:QuestionText:QuestionAudio:Answer1:Answer1Audio:Answer2:Answer2Audio:Answer3:Answer3Audio:Answer4:Answer4Audio:expectedSelection];
                [StoryQuestions addObject:storyquestion];
                
            }
            [model addAssessmentActivity:title:StoryQuestions];
        }
    }

    
}

/*
-(void)readAssessmentActivitiesForBook: (Book *) book{
    //NSLog(@"at beginning of read metadata for book");
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"AssessmentActivities-MetaData.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    NSError *error;
    
    //break out metadata file into seperate components
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    InteractionModel *model = [book model];
    
    //Read in the assessment activity information
    NSArray* AssessmentActivityElements = [metadataDoc nodesForXPath:@"//AssessmentActivity" error:nil];
    
    if ([AssessmentActivityElements count] > 0)
    {
        GDataXMLElement *AssessmentActivityElement = (GDataXMLElement *) [AssessmentActivityElements objectAtIndex:0];
        
        NSArray* AssessmentActivities = [AssessmentActivityElement elementsForName:@"Questions"];
        
        for(GDataXMLElement* activity in AssessmentActivities) {
            //Get story title.
            NSString* title = [[activity attributeForName:@"title"] stringValue];
            NSArray* questions = [activity elementsForName:@"Question"];
            NSMutableArray* StoryQuestions = [[NSMutableArray alloc] init];
            
            for(GDataXMLElement* question in questions) {
                
                //Get Answer number
                int QuestionNum = [[[question attributeForName:@"number"] stringValue] integerValue];
                
                //Get Question Text
                NSArray* questionText = [question elementsForName:@"QuestionText"];
                GDataXMLElement *gdataElement = (GDataXMLElement *)[questionText objectAtIndex:0];
                NSString* QuestionText = gdataElement.stringValue;
                
                //Get 1st Answer
                NSArray* answer1 = [question elementsForName:@"Answer1"];
                gdataElement = (GDataXMLElement *)[answer1 objectAtIndex:0];
                NSString* Answer1 = gdataElement.stringValue;
                
                //Get 2nd Answer
                NSArray* answer2 = [question elementsForName:@"Answer2"];
                gdataElement = (GDataXMLElement *)[answer2 objectAtIndex:0];
                NSString* Answer2 = gdataElement.stringValue;
                
                //Get 3rd Answer
                NSArray* answer3 = [question elementsForName:@"Answer3"];
                gdataElement = (GDataXMLElement *)[answer3 objectAtIndex:0];
                NSString* Answer3 = gdataElement.stringValue;
                
                //Get 4th Answer
                NSArray* answer4 = [question elementsForName:@"Answer4"];
                gdataElement = (GDataXMLElement *)[answer4 objectAtIndex:0];
                NSString* Answer4 = gdataElement.stringValue;
                
                //Get the expected selection
                NSArray* expectedSelections = [question elementsForName:@"expectedSelection"];
                gdataElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSInteger expectedSelection = [gdataElement.stringValue integerValue];
        
                AssessmentActivity* storyquestion = [[AssessmentActivity alloc] initWithValues:QuestionNum:QuestionText:Answer1:Answer2:Answer3:Answer4:expectedSelection];
                [StoryQuestions addObject:storyquestion];
                
            }
            [model addAssessmentActivity:title:StoryQuestions];
        }
    }
}
*/
@end
