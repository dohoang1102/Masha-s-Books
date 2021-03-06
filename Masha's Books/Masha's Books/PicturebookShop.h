//
//  PicturebookShop.h
//  PicturebookShop
//
//  Created by Luka Miljak on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PicturebookInfo.h"
#import "PicturebookCategory.h"
#import "PicturebookAuthor.h"

#define PICTUREBOOK_SHOP_DEBUG_LOGS 1

#ifdef PICTUREBOOK_SHOP_DEBUG_LOGS

#define PBDLOG(msg) NSLog(msg);
#define PBDLOG_ARG(msg, arg) NSLog(msg, arg);

#else

#define PBDLOG(msg) 
#define PBDLOG_ARG(msg, arg)

#endif

@interface PicturebookShop : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSURL *urlBase;
@property (nonatomic, strong) NSMutableOrderedSet *books;
@property (nonatomic, strong) NSMutableOrderedSet *categories;
@property (nonatomic, strong) NSMutableOrderedSet *authors;
@property (readwrite) BOOL isShopLoaded;

@property (nonatomic, strong) UIManagedDocument *libraryDatabase;

- (PicturebookShop *)initShop;
- (void)refreshShop;    
- (NSOrderedSet *)getBooksForCategory:(PicturebookCategory *)pbCategory;


@end
