//
//  PieContextualMenuDataSource.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

@protocol PieContextualMenuDataSource <NSObject>

- (int)numberOfMenuItems;
- (id)dataObjectAtIndex:(NSInteger)itemIndex;

@end
