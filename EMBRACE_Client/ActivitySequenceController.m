//
//  ActivitySequenceController.m
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ActivitySequenceController.h"

@implementation ActivitySequenceController

@synthesize sequences;

- (id)init {
    sequences = [[NSMutableArray alloc] init];
    
    return self;
}

/*
 * Loads a particular set of activity sequences from file for the current user
 */
- (BOOL)loadSequences:(NSString *)participantCode {
    //TEST: Match test ID to MCD participant code
    participantCode = [[participantCode uppercaseString] stringByReplacingOccurrencesOfString:@"TEST" withString:@"MCD"];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    //Get path to correct sequences file based on participant code
    NSString *sequencesFilePath = [mainBundle pathForResource:[NSString stringWithFormat:@"sequences_%@", [participantCode uppercaseString]] ofType:@"xml"];
    
    //Try to load sequences data
    NSData *sequencesData = [[NSMutableData alloc] initWithContentsOfFile:sequencesFilePath];
    
    //Sequences data loaded successfully
    if (sequencesData != nil) {
        NSError *error;
        GDataXMLDocument *sequencesXMLDocument = [[GDataXMLDocument alloc] initWithData:sequencesData error:&error];
        
        GDataXMLElement *sequencesElement = (GDataXMLElement *)[[sequencesXMLDocument nodesForXPath:@"//sequences" error:nil] objectAtIndex:0];
        
        //Read sequences
        NSArray *sequenceElements = [sequencesElement elementsForName:@"sequence"];
        
        for (GDataXMLElement *sequenceElement in sequenceElements) {
            //Get book title
            NSString *bookTitle = [[sequenceElement attributeForName:@"bookTitle"] stringValue];
            
            NSMutableArray *modes = [[NSMutableArray alloc] init]; //contains modes for each chapter
            
            //Read modes
            NSArray *modeElements = [sequenceElement elementsForName:@"mode"];
            
            for (GDataXMLElement *modeElement in modeElements) {
                //Get chapter title
                NSString *chapterTitle = [[modeElement attributeForName:@"chapterTitle"] stringValue];
                
                //Get reader
                GDataXMLElement *readerElement = [[modeElement elementsForName:@"reader"] objectAtIndex:0];
                NSString *readerString = readerElement.stringValue;
                
                Reader reader;
                
                if ([readerString isEqualToString:@"System"]) {
                    reader = SYSTEM_READER;
                }
                else if ([readerString isEqualToString:@"User"]) {
                    reader = USER_READER;
                }
                else {
                    reader = SYSTEM_READER; //default reader
                }
                
                //Get language
                GDataXMLElement *languageElement = [[modeElement elementsForName:@"language"] objectAtIndex:0];
                NSString *languageString = languageElement.stringValue;
                
                Language language;
                
                if ([languageString isEqualToString:@"English"]) {
                    language = ENGLISH;
                }
                else if ([languageString isEqualToString:@"Spanish"]) {
                    language = BILINGUAL;
                }
                else {
                    language = ENGLISH; //default language
                }
                
                //Get intervention
                GDataXMLElement *interventionElement = [[modeElement elementsForName:@"intervention"] objectAtIndex:0];
                NSString *interventionString = interventionElement.stringValue;
                
                InterventionType intervention;
                
                if ([interventionString isEqualToString:@"PM"]) {
                    intervention = PM_INTERVENTION;
                }
                else if ([interventionString isEqualToString:@"IM"]) {
                    intervention = IM_INTERVENTION;
                }
                else if ([interventionString isEqualToString:@"R"]) {
                    intervention = R_INTERVENTION;
                }
                else {
                    intervention = R_INTERVENTION; //default intervention
                }
                
                //Create mode for chapter and add to array of modes
                ActivityMode *mode = [[ActivityMode alloc] initWithValues:chapterTitle :reader :language :intervention];
                [modes addObject:mode];
            }
            
            //Create sequence to hold modes and add to array of sequences
            ActivitySequence *sequence = [[ActivitySequence alloc] initWithValues:bookTitle :modes];
            [sequences addObject:sequence];
        }
        
        return true;
    }
    //Sequence data failed to load
    else {
        return false;
    }
}

/*
 * Returns ActivitySequence for book with the specified title
 */
- (ActivitySequence *)getSequenceForBook:(NSString *)title {
    for (ActivitySequence *sequence in sequences) {
        if ([[sequence bookTitle] isEqualToString:title]) {
            return sequence;
        }
    }
    
    return nil;
}

@end
