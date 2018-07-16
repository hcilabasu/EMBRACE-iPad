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
    self = [super init];
    sequences = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSString *)getAdjustedParticipantCode:(NSString *)participantCode {
    //TEST: Match test ID to ITSP participant code
    participantCode = [[participantCode uppercaseString] stringByReplacingOccurrencesOfString:@"TEST" withString:@"ITSP"];
    
    int numSequences = 0;
    NSString *adjustedParticipantCode;
    
    // EEG sequence
    if ([participantCode rangeOfString:@"EEG"].location != NSNotFound) {
        numSequences = 4;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"EEG"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"EEG04"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"EEG0%d", sequenceNumber];
        }
    }
    // MCD1 sequence
    else if ([participantCode rangeOfString:@"MCD"].location != NSNotFound && [[participantCode componentsSeparatedByString:@"MCD"][1] length] == 2) {
        numSequences = 10;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"MCD"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"MCD10"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"MCD0%d", sequenceNumber];
        }
    }
    // MCD2 sequence
    else if ([participantCode rangeOfString:@"MCD2"].location != NSNotFound && [[participantCode componentsSeparatedByString:@"MCD2"][1] length] == 2) {
        numSequences = 10;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"MCD2"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"MCD210"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"MCD20%d", sequenceNumber];
        }
    }
    // ITSP sequence
    else if ([participantCode rangeOfString:@"ITSP"].location != NSNotFound && [[participantCode componentsSeparatedByString:@"ITSP"][1] length] == 2) {
        numSequences = 4;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"ITSP"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"ITSP04"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"ITSP0%d", sequenceNumber];
        }
    }
    // ITS sequence
    else if ([participantCode rangeOfString:@"ITS"].location != NSNotFound && [[participantCode componentsSeparatedByString:@"ITS"][1] length] == 3) {
        numSequences = 4;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"ITS"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"ITS004"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"ITS00%d", sequenceNumber];
        }
    }
    
    else if ([participantCode rangeOfString:@"BKB"].location != NSNotFound && [[participantCode componentsSeparatedByString:@"BKB"][1] length] == 3) {
        numSequences = 4;
        
        //Get number at end of participant code and match it to appropriate sequence
        NSInteger sequenceNumber = [[participantCode componentsSeparatedByString:@"BKB"][1] integerValue] % numSequences;
        
        if (sequenceNumber == 0) {
            adjustedParticipantCode = [NSString stringWithFormat:@"BKB004"];
        }
        else {
            adjustedParticipantCode = [NSString stringWithFormat:@"BKB00%d", sequenceNumber];
        }
    }
    
    return adjustedParticipantCode;
}

/*
 * Loads a particular set of activity sequences from file for the current user
 */
- (BOOL)loadSequences:(NSString *)participantCode {
    participantCode = [self getAdjustedParticipantCode:participantCode];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    //Get path to correct sequences file based on participant code
    NSString *sequencesFilePath = [mainBundle pathForResource:[NSString stringWithFormat:@"sequences_%@", participantCode] ofType:@"xml"];
    
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
                
                //Get new instructions flag
                NSString *newInstructionsString = [[modeElement attributeForName:@"newInstructions"] stringValue];
                BOOL newInstructions = [newInstructionsString isEqualToString:@"true"] ? true : false;
                
                //Get reader
                GDataXMLElement *readerElement = [[modeElement elementsForName:@"reader"] objectAtIndex:0];
                NSString *readerString = readerElement.stringValue;
                
                Actor reader;
                
                if ([readerString isEqualToString:@"System"]) {
                    reader = SYSTEM;
                }
                else if ([readerString isEqualToString:@"User"]) {
                    reader = USER;
                }
                else {
                    reader = SYSTEM; //default reader
                }
                
                //Get language
                GDataXMLElement *languageElement = [[modeElement elementsForName:@"language"] objectAtIndex:0];
                NSString *languageString = languageElement.stringValue;
                
                Language language;
                //shang language
                if ([languageString isEqualToString:@"English"]) {
                    language = ENGLISH;
                }
                else if ([languageString isEqualToString:@"Spanish"]) {
                    language = BILINGUAL;
                }
                else {
                    language = ENGLISH; //default language
                }
                //language = BILINGUAL;//Spanish version
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
                else if ([interventionString isEqualToString:@"ITSPM"]) {
                    intervention = ITSPM_INTERVENTION;
                }
                else if ([interventionString isEqualToString:@"ITSIM"]) {
                    intervention = ITSIM_INTERVENTION;
                }
                else {
                    intervention = R_INTERVENTION; //default intervention
                }
                
                //Get vocab page flag
                NSString *vocabPageString = [[modeElement attributeForName:@"vocabPage"] stringValue];
                BOOL vocabPage = [vocabPageString isEqualToString:@"true"] ? true : false;
                
                //Get assessment page flag
                NSString *assessmentPageString = [[modeElement attributeForName:@"assessmentPage"] stringValue];
                BOOL assesssmentPage = [assessmentPageString isEqualToString:@"true"] ? true : false;
                
                //Get onDemandVocab flag
                NSString *onDemandVocabString = [[modeElement attributeForName:@"vocabOnDemand"] stringValue];
                BOOL onDemandVocab = (onDemandVocabString && ![onDemandVocabString isEqualToString:@""]) ?[onDemandVocabString boolValue] : true;
                
                //Create mode for chapter and add to array of modes
                ActivityMode *mode = [[ActivityMode alloc] initWithValues:chapterTitle :newInstructions :reader :language :intervention:vocabPage:onDemandVocab:assesssmentPage];
                [modes addObject:mode];
            }
            
            //Create sequence to hold modes and add to array of sequences
            ActivitySequence *sequence = [[ActivitySequence alloc] initWithValues:bookTitle :modes];
            [sequences addObject:sequence];
        }
        sequencesXMLDocument = nil;
        
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
