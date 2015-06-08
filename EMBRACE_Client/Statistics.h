//
//  Statistics.h
//  EMBRACE
//
//  Created by Administrator on 4/30/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Statistics : NSObject {
    NSMutableArray* pageSentences; //sentences on the page
    
    int numStepsPerComplexity[3]; //number of user steps per complexity level
    int numErrorsPerComplexity[3]; //number of errors per complexity level
    double timePerComplexity[3]; //time spent per complexity level
    
    int numNonActSentsPerComplexity[3]; //number of non-action sentences per complexity level
    double timeForNonActSentsPerComplexity[3]; //time spent on non-action sentences per complexity level
    
    int numVocabTapsPerComplexity[3]; //number of vocabulary requests per complexity level
}

@property (nonatomic, strong) NSMutableArray* pageSentences;

- (id) init;

/*
 * Getter methods
 */
- (int) getNumStepsForComplexity:(int)complexity;
- (int) getNumErrorsForComplexity:(int)complexity;
- (double) getTimeForComplexity:(int)complexity;
- (int) getNumNonActSentsForComplexity:(int)complexity;
- (double) getTimeForNonActSentsForComplexity:(int)complexity;
- (int) getNumVocabTapsForComplexity:(int)complexity;

- (double) calculateAverageTimePerStepForComplexity:(int)complexity;
- (double) calculateAverageTimePerNonActSentForComplexity:(int)complexity;

/*
 * Setter methods
 */
- (void) addStepForComplexity:(int)complexity;
- (void) addErrorForComplexity:(int)complexity;
- (void) addTime:(double)time ForComplexity:(int)complexity;
- (void) addNonActSentForComplexity:(int)complexity;
- (void) addTimeForNonActSents:(double)time ForComplexity:(int)complexity;
- (void) addVocabTapForComplexity:(int)complexity;

@end
