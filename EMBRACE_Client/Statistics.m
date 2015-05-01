//
//  Statistics.m
//  EMBRACE
//
//  Created by Administrator on 4/30/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "Statistics.h"

@implementation Statistics

@synthesize pageSentences;

- (id) init {
    pageSentences = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 3; i++) {
        numStepsPerComplexity[i] = 0;
        numErrorsPerComplexity[i] = 0;
        timePerComplexity[i] = 0;
        
        numNonActSentsPerComplexity[i] = 0;
        timeForNonActSentsPerComplexity[i] = 0;
        
        numVocabTapsPerComplexity[i] = 0;
    }
    
    return self;
}

/*
 * Getter methods
 */
- (int) getNumStepsForComplexity:(int)complexity {
    return numStepsPerComplexity[complexity];
}

- (int) getNumErrorsForComplexity:(int)complexity {
    return numErrorsPerComplexity[complexity];
}

- (double) getTimeForComplexity:(int)complexity {
    return timePerComplexity[complexity];
}

- (int) getNumNonActSentsForComplexity:(int)complexity {
    return numNonActSentsPerComplexity[complexity];
}

- (double) getTimeForNonActSentsForComplexity:(int)complexity {
    return timeForNonActSentsPerComplexity[complexity];
}

- (int) getNumVocabTapsForComplexity:(int)complexity {
    return numVocabTapsPerComplexity[complexity];
}


- (double) calculateAverageTimePerStepForComplexity:(int)complexity {
    return (timePerComplexity[complexity] / numStepsPerComplexity[complexity]);
}

- (double) calculateAverageTimePerNonActSentForComplexity:(int)complexity {
    return (timeForNonActSentsPerComplexity[complexity] / numNonActSentsPerComplexity[complexity]);
}

/*
 * Setter methods
 */
- (void) addStepForComplexity:(int)complexity {
    numStepsPerComplexity[complexity]++;
}

- (void) addErrorForComplexity:(int)complexity {
    numErrorsPerComplexity[complexity]++;
}

- (void) addTime:(double)time ForComplexity:(int)complexity {
    timePerComplexity[complexity] += time;
}

- (void) addNonActSentForComplexity:(int)complexity {
    numNonActSentsPerComplexity[complexity]++;
}

- (void) addTimeForNonActSents:(double)time ForComplexity:(int)complexity {
    timeForNonActSentsPerComplexity[complexity] += time;
}

- (void) addVocabTapForComplexity:(int)complexity {
    numVocabTapsPerComplexity[complexity]++;
}

@end
