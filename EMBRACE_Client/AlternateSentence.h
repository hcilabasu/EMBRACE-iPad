//
//  AlternateSentence.h
//  EMBRACE
//
//  Created by Administrator on 2/11/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlternateSentence : NSObject {
    NSUInteger sentenceNumber;
    BOOL actionSentence; //TRUE if sentence requires manipulation; FALSE otherwise
    NSUInteger complexity; //value from 1 (simplest) to 3 (most complex)
    NSString* text; //sentence text
    NSMutableArray* solutionSteps; //contains step numbers that are part of solution
}

@property (nonatomic, assign) NSUInteger sentenceNumber;
@property (nonatomic, assign) BOOL actionSentence;
@property (nonatomic, assign) NSUInteger complexity;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSMutableArray* solutionSteps;

- (id) initWithValues:(NSUInteger)sentNum :(BOOL)action :(NSUInteger)complex :(NSString*)txt :(NSMutableArray*)solSteps;

@end
