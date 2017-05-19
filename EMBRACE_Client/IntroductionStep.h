//
//  IntroductionStep.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/17/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntroductionStep : NSObject {
}

@property (nonatomic, assign) NSInteger stepNumber;
@property (nonatomic, copy) NSString * englishAudioFileName;
@property (nonatomic, copy) NSString * spanishAudioFileName;
@property (nonatomic, copy) NSString * englishText;
@property (nonatomic, copy) NSString * spanishText;
@property (nonatomic, copy) NSString * expectedSelection;
@property (nonatomic, copy) NSString * expectedAction;
@property (nonatomic, copy) NSString * expectedInput;


- (id) initWithValues:(NSInteger)stepNum :(NSString*)englishAudioFile :(NSString*)spanishAudioFile :(NSString*)english :(NSString*)spanish :(NSString*)selection :(NSString*)action :(NSString*)input;

@end


