//
//  GestureHandler.h
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerCommunicationController.h"
@class ManipulationViewController;
@interface GestureHandler : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) ManipulationViewController* parentManipulaitonCtr;


@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;


- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer;
- (void)tapGestureOnMenu:(CGPoint)location;
- (void)tapGestureOnVocabWord:(NSString *)englishSentenceText :(NSString *)sentenceText :(NSInteger)sentenceIDNum;
-(void)tapGestureOnObject:(CGPoint)location ;
- (void)tapGestureOnStoryWord:(NSString *)englishSentenceText :(NSInteger)sentenceIDNum :(NSString *)spanishExt :(NSString *)sentenceText;
- (IBAction)longPressGesturePerformed:(UILongPressGestureRecognizer *)recognize;
- (IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer;
- (void)panGestureBegan:(CGPoint)location;
- (void)panGestureEnded:(CGPoint)location;
- (void)panGestureInProgress:(UIPanGestureRecognizer *)recognizer :(CGPoint)location;
- (IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer;


+(void)printTT;
@end
