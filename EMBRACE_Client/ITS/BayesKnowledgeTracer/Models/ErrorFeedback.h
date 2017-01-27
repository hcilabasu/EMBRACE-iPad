//
//  ErrorFeedback.h
//  EMBRACE
//
//  Created by Jithin Roy on 1/27/17.
//  Copyright © 2017 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, EMFeedbackType) {
    EMFeedbackType_None,
    EMFeedbackType_Highlight,
    EMFeedbackType_AutoComplete
};


@interface ErrorFeedback : NSObject

@property (nonatomic, assign) EMFeedbackType feedbackType;

@property (nonatomic, assign) NSInteger skillType;

@end
