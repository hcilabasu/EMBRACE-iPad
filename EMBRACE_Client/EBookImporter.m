//
//  Readebook.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "EBookImporter.h"

@interface EBookImporter() {
    NSArray *dirPaths;
    NSString *docsDir;
    NSMutableArray *library;
    
    ConditionSetup *conditionSetup;
}

@end

@implementation EBookImporter

- (id)init {
    if (self = [super init]) {
        library = [[NSMutableArray alloc] init];
        
        conditionSetup = [ConditionSetup sharedInstance];
        
        [self findDocDir];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

/*
 * Finds the documents directory for the application
 */
- (void)findDocDir {
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
}

/*
 * Looks through the documents directory of the app to find all the books in the library
 */
- (NSMutableArray *)importLibrary {
    NSFileManager *filemgr;
    NSArray *docFileList;
    
    //Starting from the documents directory of the app
    filemgr =[NSFileManager defaultManager];
    docFileList = [filemgr contentsOfDirectoryAtPath:docsDir error:NULL];
    
    //Find all the authors directories
    for (NSString *item in docFileList) {
        NSString *authorPath = [docsDir stringByAppendingString:@"/"];
        authorPath = [authorPath stringByAppendingString:item];
        
        NSDictionary *attribs = [filemgr attributesOfItemAtPath:authorPath error: NULL];
        
        if ([attribs objectForKey:NSFileType] == NSFileTypeDirectory) {
            NSArray *authorBookList = [filemgr contentsOfDirectoryAtPath:authorPath error:NULL];
            
            //Find all the book directories for this author
            for (NSString *bookDir in authorBookList) {
                NSString *bookPath = [authorPath stringByAppendingString:@"/"];
                bookPath = [bookPath stringByAppendingString:bookDir];
                
                NSDictionary *attribsBook = [filemgr attributesOfItemAtPath:bookPath error: NULL];
                
                if ([attribsBook objectForKey:NSFileType] == NSFileTypeDirectory) {
                    if (![[(NSString *)bookDir substringToIndex:1] isEqualToString:@"."]) {
                        
                        //Find all the files for this book
                        NSArray *fileList = [filemgr contentsOfDirectoryAtPath:bookPath error:NULL];
                        
                        for (NSString *file in fileList) {
                            NSString *filePath = [bookPath stringByAppendingString:@"/"];
                            filePath = [filePath stringByAppendingString:file];
                            
                            NSDictionary *attribsFile = [filemgr attributesOfItemAtPath:filePath error: NULL];
                            
                            //Make sure we're looking at a file and not a directory
                            if ([attribsFile objectForKey:NSFileType] != NSFileTypeDirectory) {
                                NSRange fileExtensionLoc = [file rangeOfString:@"."];
                                NSString *fileExtension = [file substringFromIndex:fileExtensionLoc.location];
                                
                                //Find the epub file and unzip it
                                if ([fileExtension isEqualToString:@".epub"]) {
                                    [self unzipEpub:bookPath :file];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return library;
}

/*
 * Unzips the epub file
 */
- (void)unzipEpub:(NSString *)filepath :(NSString *)filename {
    NSString *epubFilePath = [filepath stringByAppendingString:@"/"];
    epubFilePath = [epubFilePath stringByAppendingString:filename];
    
    NSString *epubDirectoryPath = [filepath stringByAppendingString:@"/epub/"];
    
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    
    [zipArchive UnzipOpenFile:epubFilePath];
    [zipArchive UnzipFileTo:epubDirectoryPath overWrite:YES];
    [zipArchive UnzipCloseFile];
    
    [zipArchive release];
    
    //Read the container to find the path for the opf
    [self readContainerForBook:filepath];
}

/*
 * Returns the Book with the specified title
 */
- (Book *)getBookWithTitle:(NSString *)bookTitle {
    
    for (Book *book in library) {
        if (([book.title compare:bookTitle] == NSOrderedSame)) {
            return book;
            break;
        }
    }
    
    return nil;
}

/*
 * Reads the container for the book to get the filepath for the content.opf file
 */
- (void)readContainerForBook:(NSString *)filepath {
    NSString *containerPath = [filepath stringByAppendingString:@"/epub/META-INF/container.xml"];
    
    //Get xml data of the container file
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:containerPath];
    
    NSError *error;
    GDataXMLDocument *containerDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Find the name of the opf file for the book
    NSArray *rootFiles = [containerDoc.rootElement elementsForName:@"rootfiles"];
    GDataXMLElement *rootFilesElement = (GDataXMLElement *)[rootFiles objectAtIndex:0];
    
    NSArray *rootFileItem = [rootFilesElement elementsForName:@"rootfile"];
    GDataXMLElement *rootFileItemElement = (GDataXMLElement *)[rootFileItem objectAtIndex:0];
    
    NSString *mediaType = [[rootFileItemElement attributeForName:@"media-type"] stringValue];
    
    if ([mediaType isEqualToString:@"application/oebps-package+xml"]) {
        NSString *opfBookFile = [[rootFileItemElement attributeForName:@"full-path"] stringValue];
        
        //Once opf file has been found, read the opf file for the book
        [self readOpfForBook:opfBookFile :filepath];
    }
    [xmlData release];
    [containerDoc release];
}

/*
 * Reads the opf file for the book. This file provides information about the title and author of the book,
 * as well as a list of all the files associated with this book. The spine provides an order for which pages
 * should be displayed. For the purposes of this application, the program will instead use the TOC to identify
 * which pages belong to which part of the book.
 */
- (void)readOpfForBook:(NSString *)filename :(NSString *)filepath {
    //Get the filepath of the opf book file
    NSString *opfFilePath = [filepath stringByAppendingString:@"/epub/"];
    opfFilePath = [opfFilePath stringByAppendingString:filename];
    
    //Get xml data of the opf file
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:opfFilePath];
    
    NSError *error;
    GDataXMLDocument *opfDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Extract metadata, which includes author and title information
    NSArray *metadataElement = [opfDoc.rootElement elementsForName:@"metadata"];
    GDataXMLElement *metadata = (GDataXMLElement *)[metadataElement objectAtIndex:0];
    Book *book;
    
    //Extract title
    NSArray *titleElement = [metadata elementsForName:@"dc:title"];
    GDataXMLElement *titleData = (GDataXMLElement *)[titleElement objectAtIndex:0];
    NSString *title = titleData.stringValue;
    
    //Extract author
    /*NSArray *authorElement = [metadata elementsForName:@"dc:creator"];
    GDataXMLElement *authorData = (GDataXMLElement *)[authorElement objectAtIndex:0];
    NSString *author = authorData.stringValue;*/
    
    //If there is no title and author information, go ahead and just list it as Unknown
    if (title == nil)
        title = @"Unknown";
    /*if (author == nil)
        author = @"Unknown";*/
    
    //Create Book with author and title
    book = [[Book alloc] initWithTitleAndAuthor:filepath :title :@""];
    
    //Set the mainContentPath so we can access the cover image and all other files of the book
    NSRange rangeOfContentFile = [opfFilePath rangeOfString:@"content.opf"];
    [book setMainContentPath:[opfFilePath substringToIndex:rangeOfContentFile.location]];
    
    //Extract the cover if it has one.
    //cover image is in <meta content=<> name<>/> inside of metadata.
    //content is the id of the jpg that can be found in the manifest.
    //name is always cover for the cover page.
    //can also be found in the guide as an html, but I'm not sure that will work in this instance.
    NSString *coverFilePath = nil;
    NSString *coverId = nil;
    
    NSArray *metaElement = [metadata elementsForName:@"meta"];
    
    for (GDataXMLElement *element in metaElement) {
        NSString *name = [[element attributeForName:@"name"] stringValue];
        
        if ([name compare:@"cover"] == NSOrderedSame) {
            coverId = [[element attributeForName:@"content"] stringValue];
        }
    }
    
    //Read manifest items and store them in an NSDictionary for easy access
    NSArray *manifest = [opfDoc.rootElement elementsForName:@"manifest"];
    GDataXMLElement *manifestElement = (GDataXMLElement *)[manifest objectAtIndex:0];
    
    NSArray *items = [manifestElement elementsForName:@"item"];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    NSMutableArray *hrefs = [[NSMutableArray alloc] init];
    
    for (GDataXMLElement *item in items) {
        NSString *itemId = [[item attributeForName:@"id"] stringValue];
        NSString *itemHref = [[item attributeForName:@"href"] stringValue];
        
        [ids addObject:itemId];
        [hrefs addObject:itemHref];
    }
    
    NSDictionary *bookItems = [[NSDictionary alloc] initWithObjects:hrefs forKeys:ids];
    [book setBookItems:bookItems];
    
    //Read spine and store that for the time being. See comment above re: bookItems.
    NSArray *spine = [opfDoc.rootElement elementsForName:@"spine"];
    GDataXMLElement *spineElement = (GDataXMLElement *)[spine objectAtIndex:0];
    
    NSArray *itemOrderElement = [spineElement elementsForName:@"itemref"];
    NSMutableArray *itemOrder = [[NSMutableArray alloc] init];
    
    for (GDataXMLElement *itemRef in itemOrderElement) {
        NSString *itemId = [[itemRef attributeForName:@"idref"] stringValue];
        [itemOrder addObject:itemId];
    }
    
    [book setItemOrder:itemOrder];
    
    if (coverId != nil) {
        NSString *coverFilename = [bookItems objectForKey:coverId];
        coverFilePath = [[book mainContentPath] stringByAppendingString:coverFilename];
        [book setCoverImagePath:coverFilePath];
    }
    
    //Read the TOC for the book and create any Chapters and Activities as necessary
    [self readTOCForBook:book: ENGLISH];
    [self readTOCForBook:book: BILINGUAL];
    
    
    //Read the metadata for the book
    [self readMetadataForBook:book];
    
    [library addObject:book];
    [book release];
    [ids release];
    [hrefs release];
    [bookItems release];
    [itemOrder release];
    [xmlData release];
    [opfDoc release];
}


/*
 * TOC is in the same location as the .opf file. That means that we can use the mainContentPath to find it.
 * TOC file is always named toc.ncx
 */
- (void)readTOCForBook:(Book *)book : (Language) language {
    NSString *filepath = nil;
    
    //Separate TOC files depending on language
    
    if ( [[[NSUserDefaults standardUserDefaults] stringForKey:@"004"] isEqualToString:@"YES"]){
          filepath = [[book mainContentPath] stringByAppendingString:@"toc.ncx"];
       }else if (language == BILINGUAL) {
           filepath = [[book mainContentPath] stringByAppendingString:@"toc.ncx"];
       }
       else if( language == ENGLISH) {
           filepath = [[book mainContentPath] stringByAppendingString:@"tocE.ncx"];
       }
    filepath = [[book mainContentPath] stringByAppendingString:@"toc.ncx"];
    //Get xml data of the toc file
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    
    NSError *error;
    GDataXMLDocument *tocDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Get the list of chapters from the NavMap first
    //_def_ns is the default namespace for GDataXML. Must use that or register our own namespace
    NSArray *chapterList = [tocDoc nodesForXPath:@"//_def_ns:navPoint[@class='ChapterTitle']" error:nil];
    
    for (GDataXMLElement *chapterNode in chapterList) {
        Chapter *currChapter = [[Chapter alloc] init]; //Create a new chapter.
        
        //Get the chapter id
        NSString *chapterId = [[chapterNode attributeForName:@"id"] stringValue];
        [currChapter setChapterId:chapterId];
        
        //Get the chapter title from the navLabel text
        GDataXMLElement *navLabelElement = [[chapterNode elementsForName:@"navLabel"] objectAtIndex:0];
        GDataXMLElement *navLabelTextElement =  [[navLabelElement elementsForName:@"text"] objectAtIndex:0];
        [currChapter setTitle:[navLabelTextElement stringValue]];
        
        //Get the title page and the image for the chapter
        GDataXMLElement *contentElement = [[chapterNode elementsForName:@"content"] objectAtIndex:0];
        NSString *chapterFilename = [[contentElement attributeForName:@"src"] stringValue];
        [currChapter setChapterTitlePage:[[book mainContentPath] stringByAppendingString:chapterFilename]];
        
        //Extract the image from the chapter title page
        [self extractCoverForChapter:book :currChapter];
        
        //Read in all pages associated with this chapter
        NSArray *pageElements = [chapterNode elementsForName:@"navPoint"];
        
        //For each page, we'll have to create an Activity if it belongs to a specific type of activity. Otherwise, we just add it as a page. If an Activity contains additional pages, we'll have to ensure that we add it to the existing activity, instead of creating a new one.
        for (GDataXMLElement *element in pageElements){
            NSString *pageId = [[element attributeForName:@"id"] stringValue]; //Get the ID
            
            Page *currPage = [[Page alloc] init];
            [currPage setPageId:pageId];
            
            GDataXMLElement *pagePathElement = [[element elementsForName:@"content"] objectAtIndex:0];
            NSString *pagePathFilename = [[pagePathElement attributeForName:@"src"] stringValue];
            [currPage setPagePath:[[book mainContentPath] stringByAppendingString:pagePathFilename]];
            
            //NOTE: Previously, we used the navPoint class in the TOC file to determine which type of Activity to create. However, the class is irrelevant now because pages don't differ between PM_MODE and IM_MODE. (Only their solutions differ.) Instead, we go ahead and create a PhysicalManipulationActivity and an ImagineManipulationActivity for every chapter. Code below is not the most elegant solution, so we'll need to refactor things later.
            bool newActivity = FALSE;
            PhysicalManipulationActivity *currPMActivity = (PhysicalManipulationActivity *)[currChapter getActivityOfType:PM_MODE];
            ITSPhysicalManipulationActivity *currITSPMActivity = (ITSPhysicalManipulationActivity *)[currChapter getActivityOfType:ITSPM_MODE];
            ImagineManipulationActivity *currIMActivity = (ImagineManipulationActivity *)[currChapter getActivityOfType:IM_MODE];
            ITSImagineManipulationActivity *currITSIMActivity = (ITSImagineManipulationActivity *)[currChapter getActivityOfType:ITSIM_MODE];
            
            //Chapter doesn't have a PMActivity or IMActivity, so we'll create them
            if (currPMActivity == nil || currIMActivity == nil || currITSPMActivity == nil || currITSIMActivity == nil) {
                currPMActivity = [[PhysicalManipulationActivity alloc] init];
                currITSPMActivity = [[ITSPhysicalManipulationActivity alloc] init];
                currIMActivity = [[ImagineManipulationActivity alloc] init];
                currITSIMActivity = [[ITSImagineManipulationActivity alloc] init];
                newActivity = TRUE;
            }
            
            [currPMActivity setActivityId:pageId];
            [currITSPMActivity setActivityId:pageId];
            [currIMActivity setActivityId:pageId];
            [currITSIMActivity setActivityId:pageId];
            [currPMActivity addPage:currPage];
            [currITSPMActivity addPage:currPage];
            [currIMActivity addPage:currPage];
            [currITSIMActivity addPage:currPage];
            [currPage release];
            //Get the title of the activity. Don't care about this right now.
            GDataXMLElement *activityTitleElement = [[element elementsForName:@"navLabel"] objectAtIndex:0];
            NSString *activityTitle = [activityTitleElement stringValue];
            [currPMActivity setActivityTitle:activityTitle];
            [currITSPMActivity setActivityTitle:activityTitle];
            [currIMActivity setActivityTitle:activityTitle];
            [currITSIMActivity setActivityTitle:activityTitle];
            
            //If we had to create an activity that doesn't exist in the chapter..add the activity.
            if (newActivity) {
                [currChapter addActivity:currPMActivity];
                [currChapter addActivity:currITSPMActivity];
                [currChapter addActivity:currIMActivity];
                [currChapter addActivity:currITSIMActivity];
                
                [currITSIMActivity release];
                currITSIMActivity =  nil;
                
                [currIMActivity release];
                currIMActivity =  nil;
                
                [currITSPMActivity release];
                currITSPMActivity =  nil;
                
                [currPMActivity release];
                currPMActivity =  nil;
            }
            

        }
        
        //Separate chapter files depending on language
        if (language == BILINGUAL) {
            //Add chapter to book
            [book addSpanishChapter:currChapter];
        }
        else if(language == ENGLISH) {
            //Add chapter to book
            [book addEnglishChapter:currChapter];
        }
        [currChapter release];
    }
    [xmlData release];
    [tocDoc release];
}

/*
 * Finds the cover image for the chapter in the book
 */
- (void)extractCoverForChapter:(Book *)book :(Chapter *)chapter {
    NSData *htmlData = [[NSMutableData alloc] initWithContentsOfFile:[chapter chapterTitlePage]];
    
    NSError *error;
    
    //Get the html data of the chapter title page
    GDataXMLDocument *chapterTitlePage = [[GDataXMLDocument alloc] initWithHTMLData:htmlData error:&error];
    
    //Find the cover image and extract the path to the image
    NSArray *coverImageDivElements = [chapterTitlePage nodesForXPath:@"//div[@class='cover']" error:nil];
    
    GDataXMLElement *coverImageDivElement = [coverImageDivElements objectAtIndex:0];
    
    GDataXMLElement *coverImageElement = [[coverImageDivElement elementsForName:@"img"] objectAtIndex:0];
    
    NSString *chapterFilename = [[coverImageElement attributeForName:@"src"] stringValue];
    
    NSRange filenameRange = [chapterFilename rangeOfString:@".."];
    chapterFilename = [chapterFilename substringFromIndex:filenameRange.location + filenameRange.length];
    
    NSString *chapterFilePath = [[book mainContentPath] stringByAppendingString:chapterFilename];
    
    [chapter setChapterImagePath:chapterFilePath];
    
    [chapterTitlePage release];
    [htmlData release];
}

/*
 * Calls the individual functions responsible for reading each type of metadata file
 */
- (void)readMetadataForBook:(Book *)book {
    InteractionModel *model = [book model];
    
    [self readRelationshipMetadata:model :[[book mainContentPath] stringByAppendingString:@"Relationships-MetaData.xml"]];
    [self readConstraintMetadata:model :[[book mainContentPath] stringByAppendingString:@"Constraints-MetaData.xml"]];
    [self readHotspotMetadata:model :[[book mainContentPath] stringByAppendingString:@"Hotspots-MetaData.xml"]];
    [self readLocationMetadata:model :[[book mainContentPath] stringByAppendingString:@"Locations-MetaData.xml"]];
    [self readAreaMetadata:model :[[book mainContentPath] stringByAppendingString:@"Areas-MetaData.xml"]];
    [self readWaypointMetadata:model :[[book mainContentPath] stringByAppendingString:@"Waypoints-MetaData.xml"]];
    [self readAlternateImageMetadata:model :[[book mainContentPath] stringByAppendingString:@"AlternateImages-MetaData.xml"]];
    [self readSetupMetadata:book :[[book mainContentPath] stringByAppendingString:@"Setups-MetaData.xml"]:ENGLISH];
    [self readSetupMetadata:book :[[book mainContentPath] stringByAppendingString:@"Setups-MetaData.xml"]:BILINGUAL];
    
    //Read PM, IM, or ITSPM solutions
    [self readSolutionMetadata:book :ITSPM_MODE :[[book mainContentPath] stringByAppendingString:@"Solutions-MetaData-ITS.xml"]:ENGLISH];
    [self readSolutionMetadata:book :PM_MODE :[[book mainContentPath] stringByAppendingString:@"Solutions-MetaData.xml"]:ENGLISH];
    [self readSolutionMetadata:book :IM_MODE :[[book mainContentPath] stringByAppendingString:@"IMSolutions-MetaData.xml"]:ENGLISH];
    [self readSolutionMetadata:book :ITSIM_MODE :[[book mainContentPath] stringByAppendingString:@"IMSolutions-MetaData-ITS.xml"]:ENGLISH];
    [self readSolutionMetadata:book :ITSPM_MODE :[[book mainContentPath] stringByAppendingString:@"Solutions-MetaData-ITS.xml"]:BILINGUAL];
    [self readSolutionMetadata:book :PM_MODE :[[book mainContentPath] stringByAppendingString:@"Solutions-MetaData.xml"]:BILINGUAL];
    [self readSolutionMetadata:book :IM_MODE :[[book mainContentPath] stringByAppendingString:@"IMSolutions-MetaData.xml"]:BILINGUAL];
    [self readSolutionMetadata:book :ITSIM_MODE :[[book mainContentPath] stringByAppendingString:@"IMSolutions-MetaData-ITS.xml"]:BILINGUAL];
    
    
    
    [self readAlternateSentenceMetadata:book :[[book mainContentPath] stringByAppendingString:@"AlternateSentences-MetaData.xml"]:ENGLISH:ITSPM_MODE];
    [self readAlternateSentenceMetadata:book :[[book mainContentPath] stringByAppendingString:@"AlternateSentences-MetaData-IM.xml"]:ENGLISH:ITSIM_MODE];
    //[self readAlternateSentenceMetadata:book :[[book mainContentPath] stringByAppendingString:@"AlternateSentences-MetaData.xml"]:BILINGUAL];
    [self readIntroductionMetadata:model :[[book mainContentPath] stringByAppendingString:@"Introductions-MetaData.xml"]];
    [self readVocabularyIntroductionMetadata:model :[[book mainContentPath] stringByAppendingString:@"VocabularyIntroductions-MetaData.xml"]];
    [self readVocabularyMetadata:book :[[book mainContentPath] stringByAppendingString:@"Vocabulary-MetaData.xml"]:ENGLISH];
    [self readVocabularyMetadata:book :[[book mainContentPath] stringByAppendingString:@"Vocabulary-MetaData.xml"]:BILINGUAL];
    
    //Separate Assessment metadata files depending on language
    [self readAssessmentMetadata:model :[[book mainContentPath] stringByAppendingString:@"AssessmentActivities-MetaData.xml"]: ENGLISH:ENDOFCHAPTER];
    [self readAssessmentMetadata:model :[[book mainContentPath] stringByAppendingString:@"AssessmentActivitiesSpanish-MetaData.xml"]:BILINGUAL:ENDOFCHAPTER];
    [self readAssessmentMetadata:model :[[book mainContentPath] stringByAppendingString:@"AssessmentActivitiesEOB-MetaData.xml"]:ENGLISH:ENDOFBOOK];
    [self readAssessmentMetadata:model :[[book mainContentPath] stringByAppendingString:@"AssessmentActivitiesEOBSpanish-MetaData.xml"]:BILINGUAL:ENDOFBOOK];
    
    [self readScriptMetadata:book filePath:[[book mainContentPath] stringByAppendingString:@"Script-Metadata.xml"]:ENGLISH];
    [self readScriptMetadata:book filePath:[[book mainContentPath] stringByAppendingString:@"Script-Metadata.xml"]:BILINGUAL];
    [self readWordMappingMetadata:model :[[book mainContentPath] stringByAppendingString:@"WordMapping.xml"]];
    
}

- (void)readRelationshipMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *relationshipsElements = [metadataDoc nodesForXPath:@"//relationships" error:nil];
    GDataXMLElement *relationshipsElement = (GDataXMLElement *)[relationshipsElements objectAtIndex:0];
    
    NSArray *relationships = [relationshipsElement elementsForName:@"relationship"];
    
    for (GDataXMLElement *relationship in relationships){
        NSString *obj1Id = [[relationship attributeForName:@"obj1Id"] stringValue];
        NSString *can = [[relationship attributeForName:@"can"] stringValue];
        NSString *type = [[relationship attributeForName:@"action"] stringValue];
        NSString *obj2Id = [[relationship attributeForName:@"obj2Id"] stringValue];
        
        [model addRelationship:obj1Id :can :type :obj2Id];
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readConstraintMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *constraintsElements = [metadataDoc nodesForXPath:@"//constraints" error:nil];
    GDataXMLElement *constraintsElement = (GDataXMLElement *)[constraintsElements objectAtIndex:0];
    
    //Movement constraints
    NSArray *movementConstraintsElements = [constraintsElement elementsForName:@"movementConstraints"];
    GDataXMLElement *movementConstraintsElement = (GDataXMLElement *)[movementConstraintsElements objectAtIndex:0];
    
    NSArray *movementConstraints = [movementConstraintsElement elementsForName:@"constraint"];
    
    for(GDataXMLElement *constraint in movementConstraints) {
        NSString *objectId = [[constraint attributeForName:@"objId"] stringValue];
        NSString *action = [[constraint attributeForName:@"action"] stringValue];
        NSString *originX = [[constraint attributeForName:@"x"] stringValue];
        NSString *originY = [[constraint attributeForName:@"y"] stringValue];
        NSString *width = [[constraint attributeForName:@"width"] stringValue];
        NSString *height = [[constraint attributeForName:@"height"] stringValue];
        
        [model addMovementConstraint:objectId :action :originX :originY :width :height];
    }
    
    //Order constraints
    NSArray *orderConstraintsElements = [constraintsElement elementsForName:@"orderConstraints"];
    GDataXMLElement *orderConstraintsElement = (GDataXMLElement *)[orderConstraintsElements objectAtIndex:0];
    
    NSArray *orderConstraints = [orderConstraintsElement elementsForName:@"constraint"];
    
    for(GDataXMLElement *constraint in orderConstraints) {
        NSString *action1 = [[constraint attributeForName:@"action1"] stringValue];
        NSString *rule = [[constraint attributeForName:@"rule"] stringValue];
        NSString *action2 = [[constraint attributeForName:@"action2"] stringValue];
        
        [model addOrderConstraint:action1 :action2 :rule];
    }
    
    //Combo constraints
    NSArray *comboConstraintsElements = [constraintsElement elementsForName:@"comboConstraints"];
    GDataXMLElement *comboConstraintsElement = (GDataXMLElement *)[comboConstraintsElements objectAtIndex:0];
    
    NSArray *comboConstraints = [comboConstraintsElement elementsForName:@"constraint"];
    
    for (GDataXMLElement *constraint in comboConstraints) {
        //Get the object that this constraint applies to
        NSString *objectId = [[constraint attributeForName:@"objId"] stringValue];
        
        //Create an array to hold all the actions/hotspots that cannot be used at the same time
        NSMutableArray *comboActs = [[NSMutableArray alloc] init];
        
        NSArray *comboActions = [constraint elementsForName:@"comboAction"];
        
        for (GDataXMLElement *comboAction in comboActions) {
            //Get the action
            NSString *action = [[comboAction attributeForName:@"action"] stringValue];
            
            [comboActs addObject:action]; //Add the action to the array
        }
        
        [model addComboConstraint:objectId :comboActs];
        [comboActs release];
    }
    
    [metadataDoc release];
    [xmlData release];
}

- (void)readHotspotMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *hotspotsElements = [metadataDoc nodesForXPath:@"//hotspots" error:nil];
    GDataXMLElement *hotspotsElement = (GDataXMLElement *)[hotspotsElements objectAtIndex:0];
    
    NSArray *hotspots = [hotspotsElement elementsForName:@"hotspot"];
    
    for(GDataXMLElement *hotspot in hotspots) {
        NSString *objectId = [[hotspot attributeForName:@"objId"] stringValue];
        NSString *action = [[hotspot attributeForName:@"action"] stringValue];
        NSString *role = [[hotspot attributeForName:@"role" ] stringValue];
        NSString *locationXString = [[hotspot attributeForName:@"x"] stringValue];
        NSString *locationYString = [[hotspot attributeForName:@"y"] stringValue];
        
        //Find the range of "," in the location string.
        CGFloat locX = [locationXString floatValue];
        CGFloat locY = [locationYString floatValue];
        
        CGPoint location = CGPointMake(locX, locY);
        
        [model addHotspot:objectId :action :role :location];
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readLocationMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *locationElements = [metadataDoc nodesForXPath:@"//locations" error:nil];
    GDataXMLElement* locationElement = (GDataXMLElement *)[locationElements objectAtIndex:0];
    
    NSArray *locations = [locationElement elementsForName:@"location"];
    
    for (GDataXMLElement *location in locations) {
        NSString *locationId = [[location attributeForName:@"locationId"] stringValue];
        NSString *originX = [[location attributeForName:@"x"] stringValue];
        NSString *originY = [[location attributeForName:@"y"] stringValue];
        NSString *height = [[location attributeForName:@"height"] stringValue];
        NSString *width = [[location attributeForName:@"width"] stringValue];
        
        [model addLocation:locationId :originX :originY :height :width];
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readAreaMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *areaElements = [metadataDoc nodesForXPath:@"//areas" error:nil];
    GDataXMLElement *areaElement = (GDataXMLElement *)[areaElements objectAtIndex:0];
    
    NSArray *areas = [areaElement elementsForName:@"area"];
    bool isFirstPoint = true;
    bool isSecondPoint = false;
    bool isThirdPoint = false;
    
    for (GDataXMLElement *area in areas) {
        UIBezierPath *aPath = [UIBezierPath bezierPath];
        NSMutableDictionary *areaDictionary = [[NSMutableDictionary alloc] init];
        NSString *areaId = [[area attributeForName:@"areaId"] stringValue];
        NSArray *points = [area elementsForName:@"point"];
        isFirstPoint = true;
        isSecondPoint = false;
        NSString *pageId = [[area attributeForName:@"pageId"] stringValue];
        
        int pointID = 0;
        
        float firstpointX = 0.0f;
        float firstpointY = 0.0f;
        float secondpointX = 0.0f;
        float secondpointY = 0.0f;
        float thirdpointX = 0.0f;
        float thirdpointY = 0.0f;
        
        for (GDataXMLElement *point in points) {
            NSString *pointX = [[point attributeForName:@"x"] stringValue];
            NSString *pointY = [[point attributeForName:@"y"] stringValue];
            
            float locationX = [pointX floatValue] / 100.0 * 1024;
            float locationY = [pointY floatValue] / 100.0 * 704;
            
            areaDictionary[[NSString stringWithFormat:@"x%d", pointID]] = [NSString stringWithFormat:@"%f", locationX];
            areaDictionary[[NSString stringWithFormat:@"y%d", pointID]] = [NSString stringWithFormat:@"%f", locationY];
            pointID++;
            
            if (isFirstPoint) {
                // Set the starting point of the shape
                [aPath moveToPoint:CGPointMake(locationX, locationY)];
                firstpointX = locationX;
                firstpointY = locationY;
                isSecondPoint = true;
                isFirstPoint = false;
            }
            else if (isSecondPoint) {
                secondpointX = locationX;
                secondpointY = locationY;
                isSecondPoint = false;
                isThirdPoint = true;
                [aPath addLineToPoint:CGPointMake(locationX, locationY)];
            }
            else if (isThirdPoint) {
                thirdpointX = locationX;
                thirdpointY = locationY;
                isThirdPoint = false;
                [aPath addLineToPoint:CGPointMake(locationX, locationY)];
            }
            else {
                [aPath addLineToPoint:CGPointMake(locationX, locationY)];
            }
        }
        
        if ([areaId rangeOfString:@"Path"].location == NSNotFound) {
            [aPath closePath];
            areaDictionary[[NSString stringWithFormat:@"x%d", pointID]] = [NSString stringWithFormat:@"%f", firstpointX];
            areaDictionary[[NSString stringWithFormat:@"y%d", pointID]] = [NSString stringWithFormat:@"%f", firstpointY];
            pointID++;
            [aPath addLineToPoint:CGPointMake(firstpointX, firstpointY)];
            areaDictionary[[NSString stringWithFormat:@"x%d", pointID]] = [NSString stringWithFormat:@"%f", secondpointX];
            areaDictionary[[NSString stringWithFormat:@"y%d", pointID]] = [NSString stringWithFormat:@"%f", secondpointY];
            pointID++;
            [aPath addLineToPoint:CGPointMake(secondpointX, secondpointY)];
            areaDictionary[[NSString stringWithFormat:@"x%d", pointID]] = [NSString stringWithFormat:@"%f", thirdpointX];
            areaDictionary[[NSString stringWithFormat:@"y%d", pointID]] = [NSString stringWithFormat:@"%f", thirdpointY];
            pointID++;
            [aPath addLineToPoint:CGPointMake(thirdpointX, thirdpointY)];
        }
        
        [model addArea:areaId :aPath :areaDictionary :pageId];
        [areaDictionary release];
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readWaypointMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *waypointElements = [metadataDoc nodesForXPath:@"//waypoints" error:nil];
    GDataXMLElement *waypointElement = (GDataXMLElement *)[waypointElements objectAtIndex:0];
    
    NSArray *waypoints = [waypointElement elementsForName:@"waypoint"];
    
    for (GDataXMLElement *waypoint in waypoints) {
        NSString *waypointId = [[waypoint attributeForName:@"waypointId"] stringValue];
        NSString *locationXString = [[waypoint attributeForName:@"x"] stringValue];
        NSString *locationYString = [[waypoint attributeForName:@"y"] stringValue];
        
        //Find the range of "," in the location string
        CGFloat locX = [locationXString floatValue];
        CGFloat locY = [locationYString floatValue];
        
        CGPoint location = CGPointMake(locX, locY);
        
        [model addWaypoint:waypointId :location];
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readAlternateImageMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *altImageElements = [metadataDoc nodesForXPath:@"//alternateImages" error:nil];
    
    if ([altImageElements count] > 0) {
        GDataXMLElement *altImageElement = (GDataXMLElement *)[altImageElements objectAtIndex:0];
        
        NSArray *altImages = [altImageElement elementsForName:@"alternateImage"];
        
        for (GDataXMLElement* altImage in altImages) {
            NSString* objectId = [[altImage attributeForName:@"objId"] stringValue];
            NSString* action = [[altImage attributeForName:@"action"] stringValue];
            NSString* originalSrc = [[altImage attributeForName:@"originalSrc"] stringValue];
            NSString* alternateSrc = [[altImage attributeForName:@"alternateSrc"] stringValue];
            NSString* width = [[altImage attributeForName:@"width"] stringValue];
            NSString* height = [[altImage attributeForName:@"height"] stringValue];
            NSString* locationXString = [[altImage attributeForName:@"x"] stringValue];
            NSString* locationYString = [[altImage attributeForName:@"y"] stringValue];
            NSString* className = [[altImage attributeForName:@"class"] stringValue];
            NSString* locationZString = [[altImage attributeForName:@"z"] stringValue];
            
            //Find the range of "," in the location string
            CGFloat locX = [locationXString floatValue];
            CGFloat locY = [locationYString floatValue];
            
            CGPoint location = CGPointMake(locX, locY);
            
            [model addAlternateImage:objectId :action :originalSrc :alternateSrc :width : height :location :className :locationZString];
        }
    }
    [metadataDoc release];
    [xmlData release];
}

- (void)readSetupMetadata:(Book *)book :(NSString *)filepath :(Language) language {
    
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != language) {
        tempLang = conditionSetup.language;
        conditionSetup.language = language;
    }
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *setupElements = [metadataDoc nodesForXPath:@"//setups" error:nil];
    GDataXMLElement *setupElement = (GDataXMLElement *)[setupElements objectAtIndex:0];
    
    NSArray *storySetupElements = [setupElement elementsForName:@"story"];
    
    for (GDataXMLElement *storySetupElement in storySetupElements) {
        //Get story title
        NSString *storyTitle = [[storySetupElement attributeForName:@"title"] stringValue];
        Chapter *chapter = [book getChapterWithTitle:storyTitle];
        
        //Get page id
        NSString *pageId = [[storySetupElement attributeForName:@"page_id"] stringValue];
        
        if (chapter != nil) {
            PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
            ITSPhysicalManipulationActivity *ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE]; //get ITSPM Activity only
            //PhysicalManipulationActivity *IMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:IM_MODE]; //get IM Activity only
            
            NSArray *storySetupSteps = [storySetupElement children];
            
            for (GDataXMLElement *storySetupStep in storySetupSteps) {
                //Get setup step information
                NSString *stepType = [storySetupStep name];
                NSString *obj1Id = [[storySetupStep attributeForName:@"obj1Id"] stringValue];
                NSString *action = [[storySetupStep attributeForName:@"action"] stringValue];
                NSString *obj2Id = [[storySetupStep attributeForName:@"obj2Id"] stringValue];
                
                ActionStep *setupStep = [[ActionStep alloc] initAsSetupStep:stepType :obj1Id :obj2Id :action];
                [PMActivity addSetupStep:setupStep forPageId:pageId];
                [ITSPMActivity addSetupStep:setupStep forPageId:pageId];
                //[IMActivity addSetupStep:setupStep forPageId:pageId];
                [setupStep release];
            }
        }
    }
    [metadataDoc release];
    [xmlData release];
    conditionSetup.language = tempLang;
}

/*
 * Reads solution metadata based on the mode--PM_MODE or IM_MODE or ITSPM_MODE or ITSIM_MODE
 */
- (void)readSolutionMetadata:(Book *)book :(Mode)mode :(NSString *)filepath :(Language) language {
    
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != language) {
        tempLang = conditionSetup.language;
        conditionSetup.language = language;
    }
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    //Read in the solutions and add them to the ManipulationActivity they belong to
    NSArray *solutionsElements = [metadataDoc nodesForXPath:@"//solutions" error:nil];
    GDataXMLElement *solutionsElement = (GDataXMLElement *)[solutionsElements objectAtIndex:0];
    
    NSArray *storySolutions = [solutionsElement elementsForName:@"story"];
    
    for (GDataXMLElement *solution in storySolutions) {
        //Get story title
        NSString *title = [[solution attributeForName:@"title"] stringValue];
        Chapter *chapter = [book getChapterWithTitle:title];

        //Get activity id
        NSString *activityId = [[solution attributeForName:@"activity_id"] stringValue];
        
        if (chapter != nil) {
            PhysicalManipulationSolution *PMSolution;
            ImagineManipulationSolution *IMSolution;
            ITSPhysicalManipulationSolution *ITSPMSolution;
            ITSImagineManipulationSolution *ITSIMSolution;
            
            if (mode == PM_MODE) {
                PMSolution = [[PhysicalManipulationSolution alloc] init];
            }
            else if(mode == ITSPM_MODE){
                ITSPMSolution = [[ITSPhysicalManipulationSolution alloc] init];
            }
            else if (mode == IM_MODE) {
                IMSolution = [[ImagineManipulationSolution alloc] init];
            }
            else if (mode == ITSIM_MODE) {
                ITSIMSolution = [[ITSImagineManipulationSolution alloc] init];
            }
            
            //Solution metadata will change to include "idea" instead of "sentence" but some epubs may still be using "sentence"
            NSArray *sentenceSolutions = [solution elementsForName:@"idea"];
            
            if ([sentenceSolutions count] == 0) {
                sentenceSolutions = [solution elementsForName:@"sentence"];
            }
            
            for (GDataXMLElement *sentence in sentenceSolutions) {
                //Get sentence number
                NSUInteger sentenceNum = [[[sentence attributeForName:@"number"] stringValue] integerValue];
                
                NSArray *stepSolutions = [sentence elementsForName:@"step"];
                
                //Add idea without any steps (used for non-manipulation sentences)
                if ([stepSolutions count] == 0) {
                    ActionStep *solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum : nil :0 : nil : nil : nil : nil: nil : nil : nil : nil];
                    
                    if (mode == PM_MODE) {
                        [PMSolution addSolutionStep:solutionStep];
                    }
                    else if (mode == ITSPM_MODE){
                        [ITSPMSolution addSolutionStep:solutionStep];
                    }
                    else if (mode == IM_MODE) {
                        [IMSolution addSolutionStep:solutionStep];
                    }
                    else if (mode == ITSIM_MODE) {
                        [ITSIMSolution addSolutionStep:solutionStep];
                    }
                    [solutionStep release];
                }
                
                for (GDataXMLElement *stepSolution in stepSolutions) {
                    //Get step number
                    NSUInteger stepNum = [[[stepSolution attributeForName:@"number"] stringValue] integerValue];
                    
                    //Get solution steps for sentence
                    NSArray *stepsForSentence = [stepSolution children];
                    
                    for (GDataXMLElement *step in stepsForSentence) {
                        ActionStep *solutionStep = [self readSolutionStep:step :sentenceNum :stepNum];
                        
                        if (solutionStep != nil) {
                            if (mode == PM_MODE) {
                                [PMSolution addSolutionStep:solutionStep];
                            }
                            else if(mode == ITSPM_MODE){
                                [ITSPMSolution addSolutionStep:solutionStep];
                            }
                            else if (mode == IM_MODE) {
                                [IMSolution addSolutionStep:solutionStep];
                            }
                            else if (mode == ITSIM_MODE) {
                                [ITSIMSolution addSolutionStep:solutionStep];
                            }
                        }
                    }
                }
            }
            
            //Add PMSolution to page
            if (mode == PM_MODE) {
                PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity only
                [PMActivity addPMSolution:PMSolution forActivityId:activityId];
                [PMSolution release];
            }
            //Add ITSPMSolution to page
            else if (mode == ITSPM_MODE) {
                ITSPhysicalManipulationActivity *ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE]; //get ITSPM Activity only
                [ITSPMActivity addITSPMSolution:ITSPMSolution forActivityId:activityId];
                [ITSPMSolution release];
            }
            //Add IMSolution to page
            else if (mode == IM_MODE) {
                ImagineManipulationActivity *IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE]; //get IM Activity only
                [IMActivity addIMSolution:IMSolution forActivityId:activityId];
                [IMSolution release];
            }
            //Add ITSIMSolution to page
            else if (mode == ITSIM_MODE) {
                ITSImagineManipulationActivity *ITSIMActivity = (ITSImagineManipulationActivity *)[chapter getActivityOfType:ITSIM_MODE]; //get ITSIM Activity only
                [ITSIMActivity addITSIMSolution:ITSIMSolution forActivityId:activityId];
                [ITSIMSolution release];
            }
        }
    }
    
    conditionSetup.language = tempLang;
    [metadataDoc release];
    [xmlData release];
}

/*
 * Reads and returns a single solution step
 */
- (ActionStep *)readSolutionStep:(GDataXMLElement *)step :(NSUInteger)sentenceNum : (NSUInteger)stepNum {
    ActionStep *solutionStep = nil;
    
    NSString *stepType = [step name]; //get step type
    
    //All solution step types have at least an obj1Id and action
    NSString *obj1Id = [[step attributeForName:@"obj1Id"] stringValue];
    NSString *action = [[step attributeForName:@"action"] stringValue];
    NSString *menuType = ([[step attributeForName:@"menuType"] stringValue] != nil) ? [[step attributeForName:@"menuType"] stringValue] : nil;
    
    //* TransferAndGroup and transferAndDisappear steps come in pairs. The first is treated as an ungroup step, while the second may be either group or disappear.
    //* Group means that two objects should be connected.
    //* Disappear means that when two objects are close together, one should disappear.
    //* Ungroup means that two objects that were connected should be separated.
    if ([[step name] isEqualToString:@"transferAndGroup"] ||
        [[step name] isEqualToString:@"transferAndDisappear"] ||
        [[step name] isEqualToString:@"group"] ||
        [[step name] isEqualToString:@"groupAuto"] ||
        [[step name] isEqualToString:@"disappear"] ||
        [[step name] isEqualToString:@"disappearAuto"] ||
        [[step name] isEqualToString:@"disappearAutoWithDelay"] ||
        [[step name] isEqualToString:@"ungroup"] ||
        [[step name] isEqualToString:@"ungroupAndStay"] ||
        [[step name] isEqualToString:@"appearAutoWithDelay"]
        ) {
        if ([step attributeForName:@"obj2Id"]) {
            NSString *obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
            
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum  :stepType :obj1Id :obj2Id :nil :nil :action :nil :nil];
        }
        else {
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :action :nil :nil];
        }
    }
    //* Move is performed automatically and means that an object should be moved to group with another object or to a waypoint on the background.
    else if ([[step name] isEqualToString:@"move"] ||
             [[step name] isEqualToString:@"appear"]) {
        if ([step attributeForName:@"obj2Id"]) {
            NSString *obj2Id = [[step attributeForName:@"obj2Id"] stringValue];
            
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :obj2Id :nil :nil :action :nil :nil];
        }
        else if ([step attributeForName:@"waypointId"]) {
            NSString *waypointId = [[step attributeForName:@"waypointId"] stringValue];
            
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :waypointId :action :nil :nil];
        }
        else {
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :action :nil :nil];
        }
    }
    //* Check means that an object should be moved to be inside a location (defined by a bounding box) on the background.
    else if ([[step name] isEqualToString:@"check"]){
        NSString *locationId = [[step attributeForName:@"locationId"] stringValue];
        NSString *areaId = [[step attributeForName:@"areaId"] stringValue];
        
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :locationId :nil :action :areaId :nil];
    }
    //* CheckLeft, Right, Top, Down means that an object should be moved anywhere in the direction of the check step.
    else if([[step name] isEqualToString:@"checkLeft"] ||
            [[step name] isEqualToString:@"checkRight"] ||
            [[step name] isEqualToString:@"checkUp"] ||
            [[step name] isEqualToString:@"checkDown"]) {
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :action :nil :nil];
    }
    //* SwapImage is performed automatically and means that an object's image should be changed to its alternate image.
    //* CheckAndSwap means that the correct object must be tapped by the user before changing to its alternate image.
    else if ([[step name] isEqualToString:@"swapImage"] ||
             [[step name] isEqualToString:@"checkAndSwap"]) {
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum  :menuType:stepNum :stepType :obj1Id :nil :nil :nil :action :nil :nil];
    }
    else if ([[step name] isEqualToString:@"animate"]) {
        if ([step attributeForName:@"waypointId"]) {
            NSString *locationId = [[step attributeForName:@"locationId"] stringValue];
            NSString *waypointId = [[step attributeForName:@"waypointId"] stringValue];
            NSString *areaId = [[step attributeForName:@"areaId"] stringValue];
            
            solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :locationId :waypointId :action :areaId :nil];
        }
    }
    else if ([[step name] isEqualToString:@"tapToAnimate"]) {
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :action :nil :nil];
    }
    else if ([[step name] isEqualToString:@"playSound"]) {
        NSString *fileName = [[step attributeForName:@"fileName"] stringValue];
        
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :action :nil :fileName];
    }
    else if ([[step name] isEqualToString:@"shakeOrTap"]) {
        NSString *areaId = [[step attributeForName:@"areaId"] stringValue];
        NSString *locationId = [[step attributeForName:@"locationId"] stringValue];
        
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :locationId :nil :action :areaId :nil];
    }
    else if ([[step name] isEqualToString:@"checkPath"]) {
        NSString *locationId = [[step attributeForName:@"locationId"] stringValue];
        NSString *areaId = [[step attributeForName:@"areaId"] stringValue];
        
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :locationId :nil :action :areaId :nil];
    }
    else if([[step name] isEqualToString:@"tapWord"])
    {
        solutionStep = [[ActionStep alloc] initAsSolutionStep:sentenceNum :menuType :stepNum :stepType :obj1Id :nil :nil :nil :nil :nil :nil];
    }
    else
    {
        //error unknown step name
        //TODO: add default solutionStep
    }
    
    if (solutionStep) {
        return [solutionStep autorelease];
    }
    return solutionStep;
}

- (void)readAlternateSentenceMetadata:(Book *)book :(NSString *)filepath :(Language) language :(Mode) mode {
    
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != language) {
        tempLang = conditionSetup.language;
        conditionSetup.language = language;
    }
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    

    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    NSArray *alternateSentenceElements = [metadataDoc nodesForXPath:@"//alternateSentences" error:nil];
    
    
    if ([alternateSentenceElements count] > 0) {
        GDataXMLElement *alternateSentenceElement = (GDataXMLElement *)[alternateSentenceElements objectAtIndex:0];
        
        NSArray *storyAlternateSentenceElements = [alternateSentenceElement elementsForName:@"story"];
        for (GDataXMLElement *storyAlternateSentenceElement in storyAlternateSentenceElements) {
             NSString *pageId = [[storyAlternateSentenceElement attributeForName:@"page_id"] stringValue];
            NSLog(pageId);
        }
        for (GDataXMLElement *storyAlternateSentenceElement in storyAlternateSentenceElements) {
            //Get story title
            NSString *storyTitle = [[storyAlternateSentenceElement attributeForName:@"title"] stringValue];
            Chapter *chapter = [book getChapterWithTitle:storyTitle];
            
            //Get page id
            NSString *pageId = [[storyAlternateSentenceElement attributeForName:@"page_id"] stringValue];
            
            if (chapter != nil) {
                ITSPhysicalManipulationActivity *ITSPMActivity;
                ITSPhysicalManipulationSolution *ITSPMSolution;
                ITSImagineManipulationActivity *ITSIMActivity;
                ITSImagineManipulationSolution *ITSIMSolution;
                if (mode == ITSPM_MODE) {
                    ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE]; //get PM Activity only
                    ITSPMSolution = [[[ITSPMActivity ITSPMSolutions] objectForKey:pageId] objectAtIndex:0]; //get PMSolution
                }else if(mode == ITSIM_MODE){
                    ITSIMActivity = (ITSImagineManipulationActivity *)[chapter getActivityOfType:ITSIM_MODE]; //get PM Activity only
                    ITSIMSolution = [[[ITSIMActivity ITSIMSolutions] objectForKey:pageId] objectAtIndex:0]; //get PMSolution
                }
                
                
                NSArray *storyAlternateSentences = [storyAlternateSentenceElement elementsForName:@"sentence"];
                
                for (GDataXMLElement *storyAlternateSentence in storyAlternateSentences) {
                    //Get sentence number
                    NSUInteger sentenceNum = [[[storyAlternateSentence attributeForName:@"number"] stringValue] intValue];
                    
                    //Get sentence action (i.e., whether sentence requires manipulation)
                    NSString *actionString = [[storyAlternateSentence attributeForName:@"action"] stringValue];
                    
                    BOOL action = TRUE; //initially assume sentence requires manipulation
                    
                    if ([actionString isEqualToString:@"no"]) {
                        action = FALSE;
                    }
                    
                    //Get sentence attributes
                    NSArray *storyAlternateSentenceAttributes = [storyAlternateSentence elementsForName:@"attributes"];
                    GDataXMLElement *alternateSentenceAttributes = [storyAlternateSentenceAttributes objectAtIndex:0];
                    
                    //Get sentence complexity
                    NSUInteger complexity = [[[alternateSentenceAttributes attributeForName:@"complexity"] stringValue] intValue];
                    
                    //Get sentence text
                    NSArray *storyAlternateSentenceText = [storyAlternateSentence elementsForName:@"text"];
                    GDataXMLElement *alternateSentenceText = [storyAlternateSentenceText objectAtIndex:0];
                    NSString *text = alternateSentenceText.stringValue;
                    
                    //Get sentence ideas
                    GDataXMLElement *storyAlternateSentenceIdeas = [[storyAlternateSentence elementsForName:@"ideas"] objectAtIndex:0];
                    NSArray *alternateSentenceIdeas = [storyAlternateSentenceIdeas elementsForName:@"idea"];
                    
                    //Create array to store idea numbers
                    NSMutableArray *ideaNums = [[NSMutableArray alloc] init];
                    
                    for (GDataXMLElement *alternateSentenceIdea in alternateSentenceIdeas) {
                        //Get idea number
                        NSUInteger ideaNum = [[[alternateSentenceIdea attributeForName:@"number"] stringValue] intValue];
                        [ideaNums addObject:[NSNumber numberWithInteger:ideaNum]];
                    }
                    
                    //Get sentence solution (if it exists)
                    NSArray *storyAlternateSentenceSolution = [storyAlternateSentence elementsForName:@"solution"];
                    
                    //Create array to store solution step numbers
                    NSMutableArray *solutionSteps = [[NSMutableArray alloc] init];
                    
                    if ([storyAlternateSentenceSolution count] > 0) {
                        GDataXMLElement *alternateSentenceSolution = [storyAlternateSentenceSolution objectAtIndex:0];
                        
                        NSArray *alternateSentenceSteps = [alternateSentenceSolution elementsForName:@"step"];
                        
                        for (GDataXMLElement *alternateSentenceStep in alternateSentenceSteps) {
                            //Get step number
                            NSUInteger stepNum = [[[alternateSentenceStep attributeForName:@"number"] stringValue] intValue];
                            
                            //Get associated ActionStep
                            NSMutableArray *step = nil;
                            if(mode == ITSPM_MODE){
                                step = [ITSPMSolution getStepsWithNumber:stepNum];
                            }
                            else if(mode == ITSIM_MODE){
                                step = [ITSIMSolution getStepsWithNumber:stepNum];
                            }
                            if (step) {
                                for (ActionStep *as in step) {
                                    [solutionSteps addObject:as];
                                }
                            }
                            
                        }
                    }
                    
                    //Create alternate sentence and add to PMActivity
                    AlternateSentence *altSent = [[AlternateSentence alloc] initWithValues:sentenceNum :action :complexity :text :ideaNums :solutionSteps];
                    if(mode == ITSPM_MODE){
                        [ITSPMActivity addAlternateSentence:altSent forPageId:pageId];
                    }
                    else if(mode == ITSIM_MODE){
                        [ITSIMActivity addAlternateSentence:altSent forPageId:pageId];
                    }
                    [solutionSteps release];
                    [ideaNums release];
                    [altSent release];
                }
            }
        }
    }
    [xmlData release];
    [metadataDoc release];
    conditionSetup.language = tempLang;
}

- (void)readIntroductionMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *introductionElements = [metadataDoc nodesForXPath:@"//introductions" error:nil];
    
    if ([introductionElements count] > 0) {
        GDataXMLElement *introductionElement = (GDataXMLElement *) [introductionElements objectAtIndex:0];
        
        NSArray *introductions = [introductionElement elementsForName:[NSString stringWithFormat:@"%@%@",[conditionSetup returnConditionEnumToString:conditionSetup.condition], @"Introduction"]];
        
        for (GDataXMLElement *introduction in introductions) {
            //Get story title
            NSString *title = [[introduction attributeForName:@"title"] stringValue];
            NSArray *steps = [introduction elementsForName:@"introductionStep"];
            NSMutableArray *introSteps = [[NSMutableArray alloc] init];
            
            for (GDataXMLElement *step in steps) {
                //Get step number
                int stepNum = [[[step attributeForName:@"number"] stringValue] integerValue];
                
                //Get English audio file name
                NSArray *englishAudioFileNames = [step elementsForName:@"englishAudio"];
                GDataXMLElement *gDataXMLElement = (GDataXMLElement *)[englishAudioFileNames objectAtIndex:0];
                NSString *englishAudioFileName = gDataXMLElement.stringValue;
                
                //Get Spanish audio file name
                NSArray *spanishAudioFileNames = [step elementsForName:@"spanishAudio"];
                gDataXMLElement = (GDataXMLElement *)[spanishAudioFileNames objectAtIndex:0];
                NSString *spanishAudioFileName = gDataXMLElement.stringValue;
                
                //Get English text
                NSArray *englishTexts = [step elementsForName:@"englishText"];
                gDataXMLElement = (GDataXMLElement *)[englishTexts objectAtIndex:0];
                NSString *englishText = gDataXMLElement.stringValue;
                
                //Get Spanish text
                NSArray *spanishTexts = [step elementsForName:@"spanishText"];
                gDataXMLElement = (GDataXMLElement *)[spanishTexts objectAtIndex:0];
                NSString *spanishText = gDataXMLElement.stringValue;
                
                //Each step may or may not have an expected action, input and selection
                //In some cases it could be the three of them e.g. tap farmer word
                //In other cases it would just be two e.g. tap next
                
                //Get the expected selection
                NSArray *expectedSelections = [step elementsForName:@"expectedSelection"];
                gDataXMLElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString *expectedSelection = gDataXMLElement.stringValue;
                
                //Get expected action
                NSArray *expectedActions = [step elementsForName:@"expectedAction"];
                gDataXMLElement = (GDataXMLElement *)[expectedActions objectAtIndex:0];
                NSString *expectedAction = gDataXMLElement.stringValue;
                
                //Get expected input
                NSArray *expectedInputs = [step elementsForName:@"expectedInput"];
                gDataXMLElement = (GDataXMLElement *)[expectedInputs objectAtIndex:0];
                NSString *expectedInput = gDataXMLElement.stringValue;
                
                IntroductionStep *introStep = [[IntroductionStep alloc] initWithValues:stepNum:englishAudioFileName:spanishAudioFileName:englishText:spanishText:expectedSelection:expectedAction: expectedInput];
                [introSteps addObject:introStep];
                [introStep release];
                
            }
            
            [model addIntroduction:title :introSteps];
            [introSteps release];
        }
    }
    [xmlData release];
    [metadataDoc release];
}

- (void)readVocabularyIntroductionMetadata:(InteractionModel *)model :(NSString *)filepath {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *vocabIntroductionElements = [metadataDoc nodesForXPath:@"//vocabularyIntroductions" error:nil];
    
    if ([vocabIntroductionElements count] > 0) {
        GDataXMLElement *vocabIntroductionElement = (GDataXMLElement *)[vocabIntroductionElements objectAtIndex:0];
        
        NSArray *vocabIntroductions = [vocabIntroductionElement elementsForName:@"vocabularyIntroduction"];
        
        for (GDataXMLElement *vocabIntroduction in vocabIntroductions) {
            NSString *storyTitle = [[vocabIntroduction attributeForName:@"story"] stringValue];
            NSArray *words = [vocabIntroduction elementsForName:@"vocabularyIntroductionWord"];
            NSMutableArray *storyWords = [[NSMutableArray alloc] init];
            
            for (GDataXMLElement *word in words) {
                //Get word number
                int wordNum = [[[word attributeForName:@"number"] stringValue] integerValue];
                
                //Get English audio file name
                NSArray *englishAudioFileNames = [word elementsForName:@"englishWordAudio"];
                GDataXMLElement *gDataXMLElement = (GDataXMLElement *)[englishAudioFileNames objectAtIndex:0];
                NSString *englishAudioFileName = gDataXMLElement.stringValue;
                
                //Get Spanish audio file name
                NSArray *spanishAudioFileNames = [word elementsForName:@"spanishWordAudio"];
                gDataXMLElement = (GDataXMLElement *)[spanishAudioFileNames objectAtIndex:0];
                NSString *spanishAudioFileName = gDataXMLElement.stringValue;
                
                //Get English text
                NSArray *englishTexts = [word elementsForName:@"englishWordText"];
                gDataXMLElement = (GDataXMLElement *)[englishTexts objectAtIndex:0];
                NSString *englishText = gDataXMLElement.stringValue;
                
                //Get Spanish text
                NSArray *spanishTexts = [word elementsForName:@"spanishWordText"];
                gDataXMLElement = (GDataXMLElement *)[spanishTexts objectAtIndex:0];
                NSString *spanishText = gDataXMLElement.stringValue;
                
                //Each step may or may not have an expected action, input and selection
                //In some cases it could be the three of them e.g. tap farmer word
                //In other cases it would just be two e.g. tap next
                
                //Get the expected selection
                NSArray *expectedSelections = [word elementsForName:@"expectedSelection"];
                gDataXMLElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString *expectedSelection = gDataXMLElement.stringValue;
                
                //Get expected action
                NSArray *expectedActions = [word elementsForName:@"expectedAction"];
                gDataXMLElement = (GDataXMLElement *)[expectedActions objectAtIndex:0];
                NSString *expectedAction = gDataXMLElement.stringValue;
                
                //Get expected input
                NSArray *expectedInputs = [word elementsForName:@"expectedInput"];
                gDataXMLElement = (GDataXMLElement *)[expectedInputs objectAtIndex:0];
                NSString *expectedInput = gDataXMLElement.stringValue;
                
                VocabularyStep *vocabStep = [[VocabularyStep alloc] initWithValues:wordNum:englishAudioFileName:spanishAudioFileName:englishText:spanishText:expectedSelection:expectedAction: expectedInput];
                [storyWords addObject:vocabStep];
                [vocabStep release];
                
            }
            
            [model addVocabulary:storyTitle :storyWords];
            [storyWords release];
        }
    }
    [xmlData release];
    [metadataDoc release];
}

- (void)readVocabularyMetadata:(Book *)book :(NSString *)filepath :(Language) language {
    
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != language) {
        tempLang = conditionSetup.language;
        conditionSetup.language = language;
    }
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *vocabularyElements = [metadataDoc nodesForXPath:@"//vocabulary" error:nil];
    
    if ([vocabularyElements count] > 0) {
        GDataXMLElement *vocabularyElement = (GDataXMLElement *)[vocabularyElements objectAtIndex:0];
        
        NSArray *storyElements = [vocabularyElement elementsForName:@"story"];
        
        for (GDataXMLElement *storyElement in storyElements) {
            NSString *storyTitle = [[storyElement attributeForName:@"title"] stringValue];
            
            NSArray *vocabElements = [storyElement elementsForName:@"vocabulary"];
            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            
            for (GDataXMLElement *vocabElement in vocabElements) {
                BOOL introWord = false;
                
                if ([[[vocabElement attributeForName:@"introWord"] stringValue] isEqualToString:@"true"]) {
                    introWord = true;
                }
                
                NSString *word = vocabElement.stringValue;
                
                [dictionary setValue:@(introWord) forKey:word];
            }
            
            Chapter *chapter = [book getChapterWithTitle:storyTitle];
            chapter.vocabulary = dictionary;
            [dictionary release];
        }
    }
    [xmlData release];
    [metadataDoc release];
    conditionSetup.language = tempLang;
}

- (void)readAssessmentMetadata:(InteractionModel *)model :(NSString *)filepath :(Language) language :(Assessment) assessmentMode {
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    NSArray *assessmentActivityElements = [metadataDoc nodesForXPath:@"//ActivityAssessment" error:nil];
    
    if ([assessmentActivityElements count] > 0){
        GDataXMLElement *assessmentActivityElement = (GDataXMLElement *)[assessmentActivityElements objectAtIndex:0];
        
        NSArray *assessmentActivities = [assessmentActivityElement elementsForName:@"Questions"];
        
        for (GDataXMLElement *activity in assessmentActivities) {
            NSString *title = [[activity attributeForName:@"title"] stringValue];
            NSArray *questions = [activity elementsForName:@"Question"];
            NSMutableArray *storyQuestions = [[NSMutableArray alloc] init];
            
            for (GDataXMLElement *question in questions) {
                //Get question number
                int questionNum = [[[question attributeForName:@"number"] stringValue] integerValue];
                
                //Get question text
                NSArray *questionText = [question elementsForName:@"QuestionText"];
                GDataXMLElement *gDataXMLElement = (GDataXMLElement *)[questionText objectAtIndex:0];
                NSString *QuestionText = gDataXMLElement.stringValue;
                
                NSArray *questionAudio = [question elementsForName:@"QuestionAudio"];
                gDataXMLElement = (GDataXMLElement *)[questionAudio objectAtIndex:0];
                NSString *QuestionAudio = gDataXMLElement.stringValue;
                
                //Get 1st answer
                NSArray *answer1 = [question elementsForName:@"Answer1"];
                gDataXMLElement = (GDataXMLElement *)[answer1 objectAtIndex:0];
                NSString *Answer1 = gDataXMLElement.stringValue;
                
                NSArray *answer1Audio = [question elementsForName:@"Answer1Audio"];
                gDataXMLElement = (GDataXMLElement *)[answer1Audio objectAtIndex:0];
                NSString *Answer1Audio = gDataXMLElement.stringValue;
                
                //Get 2nd Answer
                NSArray *answer2 = [question elementsForName:@"Answer2"];
                gDataXMLElement = (GDataXMLElement *)[answer2 objectAtIndex:0];
                NSString *Answer2 = gDataXMLElement.stringValue;
                
                NSArray *answer2Audio = [question elementsForName:@"Answer2Audio"];
                gDataXMLElement = (GDataXMLElement *)[answer2Audio objectAtIndex:0];
                NSString *Answer2Audio = gDataXMLElement.stringValue;
                
                //Get 3rd Answer
                NSArray *answer3 = [question elementsForName:@"Answer3"];
                gDataXMLElement = (GDataXMLElement *)[answer3 objectAtIndex:0];
                NSString *Answer3 = gDataXMLElement.stringValue;
                
                NSArray *answer3Audio = [question elementsForName:@"Answer3Audio"];
                gDataXMLElement = (GDataXMLElement *)[answer3Audio objectAtIndex:0];
                NSString *Answer3Audio = gDataXMLElement.stringValue;
                
                //Get 4th Answer
                NSArray *answer4 = [question elementsForName:@"Answer4"];
                gDataXMLElement = (GDataXMLElement *)[answer4 objectAtIndex:0];
                NSString *Answer4 = gDataXMLElement.stringValue;
                
                NSArray *answer4Audio = [question elementsForName:@"Answer4Audio"];
                gDataXMLElement = (GDataXMLElement *)[answer4Audio objectAtIndex:0];
                NSString *Answer4Audio = gDataXMLElement.stringValue;
                
                //Get the expected selection
                NSArray *expectedSelections = [question elementsForName:@"expectedSelection"];
                gDataXMLElement = (GDataXMLElement *)[expectedSelections objectAtIndex:0];
                NSString *expectedSelection = gDataXMLElement.stringValue;
                
                AssessmentActivity *storyQuestion = [[AssessmentActivity alloc] initWithValues:questionNum :QuestionText :QuestionAudio :Answer1 :Answer1Audio :Answer2 :Answer2Audio :Answer3 :Answer3Audio :Answer4 :Answer4Audio :expectedSelection];
                [storyQuestions addObject:storyQuestion];
                [storyQuestion release];
                
            }
            
            [model addAssessmentActivity:title :storyQuestions :language :assessmentMode];
            [storyQuestions release];
        }
    }
    [xmlData release];
    [metadataDoc release];
    
}

- (void)readWordMappingMetadata:(InteractionModel *)model :(NSString *)filepath {
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    if (xmlData) {
        NSArray *words = [metadataDoc nodesForXPath:@"//word" error:nil];
        
        for (GDataXMLElement *wordElement in words) {
            NSString *title = [[wordElement attributeForName:@"keyWord"] stringValue];
            NSArray *mappedWords = [wordElement elementsForName:@"mappedWords"];
            for (GDataXMLElement *mpWord in mappedWords) {
                NSArray *subWords = [mpWord elementsForName:@"subWord"];
                
                for (GDataXMLElement *subw in subWords) {
                    NSString *subWord = subw.stringValue;
                    
                    [model addWordMapping:subWord andKey:title];
                }
            }
        }
        
    }
    [xmlData release];
    [metadataDoc release];
    
}

- (void)readScriptMetadata:(Book *)book filePath:(NSString *)filepath :(Language) language {
    
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != language) {
        tempLang = conditionSetup.language;
        conditionSetup.language = language;
    }
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    NSError *error;
    NSLog(@"Start for - %@",book.title);
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    if (metadataDoc !=nil) {
        
        
        NSArray *scriptAudioElems = [metadataDoc nodesForXPath:@"//scriptAudio" error:nil];
        GDataXMLElement *solutionsElement = (GDataXMLElement *)[scriptAudioElems objectAtIndex:0];
        
        NSArray *storyScripts = [solutionsElement elementsForName:@"story"];
        
        for (GDataXMLElement *solution in storyScripts) {
            //Get story title
            NSString *title = [[solution attributeForName:@"title"] stringValue];
            Chapter *chapter = [book getChapterWithTitle:title];
            
            NSArray *sentenceArray = [solution nodesForXPath:@"sentence" error:nil];
            for (GDataXMLElement *sentence in sentenceArray) {
                
                NSString *sentNo = [[sentence attributeForName:@"number"] stringValue];
                
                NSArray *elems = [sentence nodesForXPath:@"embrace" error:nil];
                if ([elems count] > 0) {
                    GDataXMLElement *embrace = [elems objectAtIndex:0];
                    ScriptAudio *script = [self parseScriptAudio:embrace
                                                    forCondition:EMBRACE];
                    if (script) {
                        [chapter addEmbraceScript:script forSentence:sentNo];
                    }
                }
                
                elems = [sentence nodesForXPath:@"control" error:nil];
                if ([elems count] > 0) {
                    GDataXMLElement *control = [elems objectAtIndex:0];
                    ScriptAudio *script = [self parseScriptAudio:control
                                                    forCondition:CONTROL];
                    if (script) {
                        [chapter addControlScript:script forSentence:sentNo];
                    }
                }
            }
            
            
        }
        
    }
    [xmlData release];
    [metadataDoc release];
    conditionSetup.language = tempLang;
}

- (ScriptAudio *)parseScriptAudio:(GDataXMLElement  *)elem
                     forCondition:(Condition)condition {
    
    ScriptAudio *script = nil;
    NSArray *preEnglish = nil;
    NSArray *postEnglish = nil;
    
    NSArray *preBilingual = nil;
    NSArray *postBilingual = nil;
    
    NSArray *preAudios = [elem nodesForXPath:@"preAudio" error:nil];
    if ([preAudios count]>0) {
        GDataXMLElement *preAudio = [preAudios objectAtIndex:0];
        
        NSArray *englishArrayElem = [preAudio nodesForXPath:@"english" error:nil];
        if ([englishArrayElem count]>0) {
            GDataXMLElement *eng = [englishArrayElem objectAtIndex:0];
            preEnglish = [[eng elementsForName:@"audio"]valueForKey:@"stringValue"];
            
            
        }
        
        NSArray *bilinArrayElem = [preAudio nodesForXPath:@"bilingual" error:nil];
        if ([bilinArrayElem count] > 0) {
            GDataXMLElement *bilingual = [bilinArrayElem objectAtIndex:0];
            preBilingual = [[bilingual elementsForName:@"audio"]valueForKey:@"stringValue"];
            
        }
        
    }
    
    NSArray *postAudios = [elem nodesForXPath:@"postAudio" error:nil];
    if ([postAudios count] >0) {
        GDataXMLElement *postAudio = [postAudios objectAtIndex:0];
        
        NSArray *englishArrayElem = [postAudio nodesForXPath:@"english" error:nil];
        if ([englishArrayElem count] > 0) {
            GDataXMLElement *eng = [englishArrayElem objectAtIndex:0];
            postEnglish = [[eng elementsForName:@"audio"]valueForKey:@"stringValue"];
        }
        
        NSArray *bilinArrayElem = [postAudio nodesForXPath:@"bilingual" error:nil];
        if ([bilinArrayElem count] > 0) {
            GDataXMLElement *bilingual = [bilinArrayElem objectAtIndex:0];
            postBilingual = [[bilingual elementsForName:@"audio"]valueForKey:@"stringValue"];
        }
        
        
        
    }
    
    if (preBilingual || preEnglish || postEnglish || postBilingual) {
        
        script = [[ScriptAudio alloc] initWithCondition:condition
                                        englishPreAudio:preEnglish
                                       englishPostAudio:postEnglish
                                      bilingualPreAudio:preBilingual
                                    bilingualaPostAudio:postBilingual];
    }
    
    return [script autorelease];
    
}

@end
