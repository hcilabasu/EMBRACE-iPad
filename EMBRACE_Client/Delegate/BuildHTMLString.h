//
//  BuildHTMLString.h
//  EMBRACE
//
//  Created by James Rodriguez on 10/21/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BuildHTMLString : NSObject

-(NSString*) buildHTMLString:(NSString*)htmlText :(NSString*)selectionType :(NSString*)clickableWord :(NSString*) sentenceType;

@end
