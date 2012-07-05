//
//  Book+Addon.m
//  Masha's Books
//
//  Created by Luka Miljak on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Book+Addon.h"

@implementation Book (Addon)

+ (Book *)bookWithAttributes:(NSDictionary *)attributes forContext:(NSManagedObjectContext *)context {
    
    //kreiranje fetch requesta
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Book"]; 
    NSError *error;
    
    request.predicate = [NSPredicate predicateWithFormat:@"bookID = %d", [[attributes objectForKey:@"ID"] integerValue]];
    NSArray *booksWithID = [context executeFetchRequest:request error:&error];
    
    if ([booksWithID count] == 0) {
        //ako knjige nema u bazi onda ovo
        NSLog(@"NEMA JE !!!!!!!!!!!!!!!!!!!!!!");
        
        Book *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:context];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"dd.mm.yyyy"];
        
        book.bookID = [NSNumber numberWithInt:[[attributes objectForKey:@"ID"] integerValue]];
        
        book.type = [NSNumber numberWithInt:[[attributes objectForKey:@"Type"] integerValue]];
        
        book.title = [attributes objectForKey:@"Title"];
        
        book.appStoreID = [NSNumber numberWithInt:[[attributes objectForKey:@"AppleStoreID"] integerValue]];
        
        book.authorID = [NSNumber numberWithInt:[[attributes objectForKey:@"AuthorID"] integerValue]];
        
        book.publishDate = [df dateFromString:[attributes objectForKey:@"PublishDate"]];
        
        book.downloadURL = [attributes objectForKey:@"DownloadURL"];
        
        book.facebookLikeURL = [attributes objectForKey:@"FacebookLikeURL"];
        
        book.youTubeVideoURL = [attributes objectForKey:@"YouTubeVideoURL"];
        
        book.active = [attributes objectForKey:@"Active"];
        
        //book.downloaded = [NSNumber numberWithInt:1];
        
        return book;
    }
    else if ([booksWithID count] == 1)       
    {
        Book *book = [booksWithID lastObject];
         // ovdje treba refreshat postojecu knjigu s novi atributima
        NSLog(@"Book with ID=%d already exists in database. Updating...", [book.bookID intValue]);
        [Book updateBook:book withAttributes:attributes];
        
        return book;
    }
    else {
        NSLog(@"ERROR: More than one book with ID $d exists in database!");
        return nil;
    }   
}

+ (void)pickBookCategoriesFromLinker:(CategoryToBookMap *)categoryToBookMap inContext:(NSManagedObjectContext *)context forBook:(Book *)book {
    
    //kreiranje fetch requesta
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"]; 
    NSError *error;
    NSArray *categoriesForBook = [categoryToBookMap getCategoryIdentifiersForBookIdentifier:[book.bookID intValue]];
    
    for (NSNumber *catID in categoriesForBook) {        
        request.predicate = [NSPredicate predicateWithFormat:@"categoryID = %d", [catID intValue]];
        NSArray *categoriesWithID = [context executeFetchRequest:request error:&error];
        if (categoriesWithID.count == 1) {
            [book addCategoriesObject:(Category *)[categoriesWithID lastObject]];
            NSLog(@"Dodajem kategoriju %@ u knjigu %@", ((Category *)[categoriesWithID lastObject]).name, book.title);
        }
        else if (categoriesWithID.count > 1) {
            NSLog(@"ERROR: Multiple entries for category ID = %d in database!", [catID intValue]);
        }
        else {
            NSLog(@"ERROR: No entries for category ID = %d in database! Linker error.", [catID intValue]);
        }                  
    }
}

+ (void)linkBooksToCategoriesWithLinker:(CategoryToBookMap *)categoryToBookMap inContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Book"]; 
    NSError *error;
    NSArray *books = [context executeFetchRequest:request error:&error];
    
    for (Book *book in books) 
        [self pickBookCategoriesFromLinker:categoryToBookMap inContext:context forBook:book];

}

+ (void)linkBooksToAuthorsInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Book"]; 
    NSError *error;
    NSArray *books = [context executeFetchRequest:request error:&error];
    
    for (Book *book in books) {
        request = [NSFetchRequest fetchRequestWithEntityName:@"Author"]; 
        request.predicate = [NSPredicate predicateWithFormat:@"authorID = %d", [book.authorID intValue]];
        NSArray *author = [context executeFetchRequest:request error:&error];
        
        if (author.count == 1) {
            book.author = [author lastObject];
            NSLog(@"Found autor %@ for book %@ in database!", ((Author *)[author lastObject]).name, book.title);
        }
        else if (author.count > 1)
        {
            NSLog(@"ERROR: Multiple autors for book %@ in database!", book.title);
        }
        else {
            NSLog(@"ERROR: No authors for book %@ in database!", book.title);
        }
    }
}

+ (void)loadCoversFromURL:(NSString *)coverUrlString forBooksInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Book"]; 
    NSError *error;
    NSArray *books = [context executeFetchRequest:request error:&error];
    for (Book *book in books) {
        
            NSURL *coverURL = [[NSURL alloc] initWithString:
                               [NSString stringWithFormat:@"%@%d%@", 
                                coverUrlString, [book.bookID intValue], @".jpg"]]; 
        
            NSURL *coverThumbnailURL = [[NSURL alloc] initWithString:
                                        [NSString stringWithFormat:@"%@%d%@", 
                                         coverUrlString, [book.bookID intValue], @"_t.jpg"]];
        
            NSLog(@"Downloading cover images for book %@", book.title);
            
            // Get an image from the URL below
            dispatch_queue_t downloadQueue = dispatch_queue_create("image download", NULL);
            dispatch_async(downloadQueue, ^{
                
                UIImage *coverUImage = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:coverURL]];
                UIImage *coverThumbnailUImage = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:coverThumbnailURL]];
                
                Image *coverImage = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
                
                dispatch_async(dispatch_get_main_queue(), ^{                    
                    if (coverImage && coverThumbnailUImage) {                                    
                        coverImage.image = coverUImage;                        
                        book.coverThumbnailImage = coverThumbnailUImage;
                        book.coverImage = coverImage;
                    
                        //[self shopDataLoaded];
                        NSLog(@"Images downloaded!!!!!!!!!!!!!!!!!!!!!!!");
                    }
                });                                                 
                
            });
            dispatch_release(downloadQueue);
        
    } 
}

+ (void)updateBook:(Book *)book withAttributes:(NSDictionary *)attributes {
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.mm.yyyy"];
    
    if (book.type != [NSNumber numberWithInt:[[attributes objectForKey:@"Type"] integerValue]]) {
        book.type = [NSNumber numberWithInt:[[attributes objectForKey:@"Type"] integerValue]];
        NSLog(@"New value for book %@ attribute book.type", book.title);
    }
    
    if (book.title != [attributes objectForKey:@"Title"]) {
        book.title = [attributes objectForKey:@"Title"];
        NSLog(@"New value for book %@ attribute book.title", book.title);
    }
    
    if (book.appStoreID != [NSNumber numberWithInt:[[attributes objectForKey:@"AppleStoreID"] integerValue]]) {
        book.appStoreID = [NSNumber numberWithInt:[[attributes objectForKey:@"AppleStoreID"] integerValue]];
        NSLog(@"New value for book %@ attribute book.appstoreID", book.title);
    }
    
    if (book.authorID != [NSNumber numberWithInt:[[attributes objectForKey:@"AuthorID"] integerValue]]) {
        book.authorID = [NSNumber numberWithInt:[[attributes objectForKey:@"AuthorID"] integerValue]];
        NSLog(@"New value for book %@ attribute book.authorID", book.title);
    }  
    
    if (book.publishDate != [df dateFromString:[attributes objectForKey:@"PublishDate"]]) {
        book.publishDate = [df dateFromString:[attributes objectForKey:@"PublishDate"]];
        NSLog(@"New value for book %@ attribute book.publishDate", book.title);
    } 
    
    if (book.downloadURL != [attributes objectForKey:@"DownloadURL"]) {
        book.downloadURL = [attributes objectForKey:@"DownloadURL"];
        NSLog(@"New value for book %@ attribute book.downloadURL", book.title);
    } 
    
    if (book.facebookLikeURL != [attributes objectForKey:@"FacebookLikeURL"]) {
        book.facebookLikeURL = [attributes objectForKey:@"FacebookLikeURL"];
        NSLog(@"New value for book %@ attribute book.facebookLikeURL", book.title);
    }
    
    if (book.youTubeVideoURL != [attributes objectForKey:@"YouTubeVideoURL"]) {
        book.youTubeVideoURL = [attributes objectForKey:@"YouTubeVideoURL"];
        NSLog(@"New value for book %@ attribute book.youTubeVideoURL", book.title);
    }
    
    if (book.active != [attributes objectForKey:@"Active"]) {
        book.active = [attributes objectForKey:@"Active"];
        NSLog(@"New value for book %@ attribute book.active", book.title);
    }    
}

- (void)fillBookElement:(NSString *)element withDescription:(NSString *)description {
    if ([element isEqualToString:@"DescriptionHTML"]) {
        self.descriptionHTML = description;
    }
    else if ([element isEqualToString:@"DescriptionLongHTML"]) {
        self.descriptionLongHTML = description;
    }
}

- (Book *)refreshBook:(Book *)book withNewAttributes:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context {
    return book;
    #warning Implement!
    
}
- (void)refreshBook:(Book *)book withNewDescription:(NSString *)description forElement:(NSString *)element {
    #warning Implement!
}

- (void)pickYourCategoriesFromLinker:(CategoryToBookMap *)categoryToBookMap inContext:(NSManagedObjectContext *)context {
    
    //kreiranje fetch requesta
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"]; 
    NSError *error;
    NSArray *categoriesForBook = [categoryToBookMap getCategoryIdentifiersForBookIdentifier:[self.bookID intValue]];
    
    for (NSNumber *catID in categoriesForBook) {        
        request.predicate = [NSPredicate predicateWithFormat:@"categoryID = %d", [catID intValue]];
        NSArray *categoriesWithID = [context executeFetchRequest:request error:&error];
        if (categoriesWithID.count == 1) {
            [self addCategoriesObject:(Category *)[categoriesWithID lastObject]];
            NSLog(@"Dodajem kategoriju %@ u knjigu %@", ((Category *)[categoriesWithID lastObject]).name, self.title);
        }
        else if (categoriesWithID.count > 1) {
            NSLog(@"ERROR: Multiple entries for category ID = %d in database!", [catID intValue]);
        }
        else {
            NSLog(@"ERROR: No entries for category ID = %d in database! Linker error.", [catID intValue]);
        }                  
    }
}



- (void)pickYourCoversFromURL:(NSURL *)coverUrl; {
    #warning Implement!    
}




@end
