//
//  VocabularyStep.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 7/16/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VocabularyStep : NSObject

@property (nonatomic, assign) NSInteger wordNumber;
@property (nonatomic, assign) NSString * englishAudioFileName;
@property (nonatomic, assign) NSString * spanishAudioFileName;
@property (nonatomic, assign) NSString * englishText;
@property (nonatomic, assign) NSString * spanishText;
@property (nonatomic, assign) NSString * expectedSelection;
@property (nonatomic, assign) NSString * expectedAction;
@property (nonatomic, assign) NSString * expectedInput;

- (id) initWithValues:(NSInteger)word :(NSString*)englishAudioFile :(NSString*)spanishAudioFile :(NSString*)english :(NSString*)spanish :(NSString*)selection :(NSString*)action :(NSString*)input;

@end
