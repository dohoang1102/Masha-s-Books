//
//  PicturebookCategory.m
//  PicturebookShop
//
//  Created by Luka Miljak on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PicturebookCategory.h"

@implementation PicturebookCategory

@synthesize iD = _iD;
@synthesize name = _name;
@synthesize booksInCategory = _booksInCategory;

- (PicturebookCategory *)initWithName:(NSString *)name AndID:(NSInteger)iD {
    self = [super init];
    self.name = name;
    self.iD = iD;
    self.booksInCategory = [[NSMutableArray alloc] init];
    return self;
}
@end
