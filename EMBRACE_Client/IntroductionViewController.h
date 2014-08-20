//
//  IntroductionController.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/18/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PieContextualMenuDelegate.h"

@interface IntroductionViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, PieContextualMenuDelegate>{}

-(void) startIntroduction;

@end
