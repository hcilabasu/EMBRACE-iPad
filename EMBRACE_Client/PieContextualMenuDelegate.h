//
//  PieContextualMenuDelegate.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

@protocol PieContextualMenuDelegate <NSObject>

-(void) expandMenu:(CGPoint)location :(CGRect) boundingBox;

@end
