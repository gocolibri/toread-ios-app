//
//  ViewController.m
//  readiOS
//
//  Created by Ingrid Funie on 04/01/2014.
//  Copyright (c) 2014 colibri. All rights reserved.
//

#import "ViewController.h"
#import "BookCollectionViewCell.h"
#import "BookDetailsViewController.h"
#import "BooksDatabase.h"
#import "MFSideMenu.h"
#import "SearchResultsController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)initializeCollectionViewData
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self initiatePickerViewWithTableNames];
    self.suggestedBooksView.bookImages = [@[] mutableCopy];
    [self.customListButton setTitle:[self.pickerViewData objectAtIndex:1] forState:UIControlStateNormal];
    
    self.retrieveBooks = [[RetrieveBooks alloc] init];
    
    self.uniqueID = [self.appDelegate getNumberOfReadBooksFromDB];
    NSLog(@"read Books count %i", self.uniqueID);
    
}

- (void) initiatePickerViewWithTableNames {
    [self.appDelegate getAllDatabaseTableNames];
    self.tableNames = [self.appDelegate.tableNames mutableCopy];
    
    [self.tableNames insertObject:@"" atIndex:0];
    [self.tableNames insertObject:@"Create New List" atIndex:self.tableNames.count];
    
    NSMutableArray *newTable = [NSMutableArray array];
    
    for (NSString* name in self.tableNames) {
        if ([name rangeOfString:@"suggested"].location != NSNotFound || [name rangeOfString:@"read"].location != NSNotFound || [name rangeOfString:@"favourite"].location != NSNotFound ) {
            continue;
        } else{
            [newTable addObject:[[name stringByReplacingOccurrencesOfString:@"Books" withString:@""] capitalizedString]];
        }
    }
    
    self.pickerViewData = [newTable mutableCopy];
    
}

- (void)loadCustomListDatabase:(NSString *)customListButtonTitle
{
    self.tableName = [customListButtonTitle lowercaseString];
    NSLog(@"the tile is %@", self.tableName);
    [self.appDelegate initiateCustomBooksListFromTheDatabase:[NSString stringWithFormat:@"%@Books",self.tableName]];
}

- (void)loadCustomListDatabaseAndRefreshView:(NSString *)customListButtonTitle {
    [self loadCustomListDatabase:customListButtonTitle];
    [self.customCollectionView reloadData];
    NSLog(@"books images count %lu", self.customCollectionView.bookImages.count);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"load view");
    
    [self.favouriteCollectionView registerNibAndCell];
    [self.customCollectionView registerNibAndCell];
    [self.suggestedBooksView registerNibAndCell];
    
    [self initializeCollectionViewData];
    
    [self loadCustomListDatabase:self.customListButton.titleLabel.text];
    [self.appDelegate loadFavouriteDatabase];
    
    [self.customCollectionView reloadData];
    [self.favouriteCollectionView reloadData];
    
    [self addGestureRecognizer:self.suggestedBooksView ];
    [self addGestureRecognizer:self.favouriteCollectionView];
    [self addGestureRecognizer:self.customCollectionView];
    
    self.searchBar.delegate = self;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    NSLog(@"show view");
    
    [self initiatePickerViewWithTableNames];
   [self loadCustomListDatabaseAndRefreshView:self.customListButton.titleLabel.text];
   [self.appDelegate loadFavouriteDatabase];
    [self.favouriteCollectionView reloadData];
}



-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    NSString* searchBarText = self.searchBar.text;
    NSString* urlString = [searchBarText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
    NSData* dataFromURL = [self.retrieveBooks getDataFromURLAsData:
                           [NSString stringWithFormat:@"https://www.googleapis.com/books/v1/volumes?q=%@&maxResults=20", urlString]];
    
    SearchResultsController *searchResController = [[SearchResultsController alloc]initWithNibName:@"SearchResultsController" bundle:nil];
    
    [searchResController setTableData:[self.retrieveBooks parseJson:[self.retrieveBooks getJsonFromData:dataFromURL]]];
    
    NSLog(@" THE ALLOCATED ONE %@", searchResController.tableData);
    
    [self presentViewController:searchResController animated:NO completion:nil];
    
    
    [self.searchBar resignFirstResponder];
    self.searchBar.text = nil;
}


- (void)addGestureRecognizer:(BookCollectionView *)collView{
    UILongPressGestureRecognizer *lpgr
    = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //seconds
    lpgr.delaysTouchesBegan = YES;
    lpgr.delegate = self;
    [collView addGestureRecognizer:lpgr];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tgr.delegate = self;
    [collView addGestureRecognizer:tgr];
}

-(void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    NSLog(@"in tap gesture");
    self.isEditMode = NO;
    
    CGPoint p = [gestureRecognizer locationInView:gestureRecognizer.view];
    
    BookDetailsViewController *bookDetails = [[BookDetailsViewController alloc] initWithNibName:@"BookDetailsViewController" bundle:nil];
    
    
    NSLog(@"handling tap gesture");
    
    if ([gestureRecognizer.view isEqual:self.favouriteCollectionView]) {
        bookDetails.indexPath = [self.favouriteCollectionView indexPathForItemAtPoint:p];
        BookCollectionViewCell* cell = (BookCollectionViewCell *)[self.favouriteCollectionView cellForItemAtIndexPath:bookDetails.indexPath];
        
        bookDetails.tableName = @"favouriteBooks";
        bookDetails.cellID = cell.ID;
    } else if ([gestureRecognizer.view isEqual:self.customCollectionView]) {
        NSLog(@"in tap for custom");
        bookDetails.indexPath = [self.customCollectionView indexPathForItemAtPoint:p];
        BookCollectionViewCell* cell = (BookCollectionViewCell *)[self.customCollectionView cellForItemAtIndexPath:bookDetails.indexPath];
        
        bookDetails.tableName = [NSString stringWithFormat:@"%@Books",self.tableName];
        NSLog(@"count:%lu", (unsigned long)self.customCollectionView.bookImages.count);
        bookDetails.cellID = cell.ID;
    } else if ([gestureRecognizer.view isEqual:self.suggestedBooksView]) {
        bookDetails.indexPath = [self.suggestedBooksView indexPathForItemAtPoint:p];
        BookCollectionViewCell* cell = (BookCollectionViewCell *)[self.customCollectionView cellForItemAtIndexPath:bookDetails.indexPath];
        
        bookDetails.tableName = @"suggestedBooks";
        bookDetails.cellID = cell.ID;
    }
    
    [self presentViewController:bookDetails animated:YES completion:nil];
    
    if (self.collView != nil)
        [self.collView reloadData];
    
    [self.pickerView removeFromSuperview];
    [self.searchBar resignFirstResponder];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    NSLog(@"in here");
    
    CGPoint p = [gestureRecognizer locationInView:gestureRecognizer.view];
    NSIndexPath *indexPath ;
    BookCollectionViewCell* cell ;
    
    
    if (self.collView != nil)
        [self.collView reloadData];
    
    if ([gestureRecognizer.view isEqual:self.favouriteCollectionView]) {
        indexPath = [self.favouriteCollectionView indexPathForItemAtPoint:p];
        if (indexPath != nil) {
            cell =[self.favouriteCollectionView dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
            [self setDataToDelete:self.favouriteCollectionView indexPath:indexPath tableName:@"favouriteBooks"];
            self.isEditMode = YES;
            [self.favouriteCollectionView reloadData];
        }
    } else if ([gestureRecognizer.view isEqual:self.customCollectionView]) {
        indexPath = [self.customCollectionView indexPathForItemAtPoint:p];
        if (indexPath != nil) {
            cell =[self.customCollectionView dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
            [self setDataToDelete:self.customCollectionView indexPath:indexPath tableName:[NSString stringWithFormat:@"%@Books", self.tableName]];
            self.isEditMode = YES;
            [self.customCollectionView reloadData];
        }
    }
    NSLog(@"getting cell %@", indexPath);
    
    
}

-(void)setDataToDelete:(BookCollectionView *)collView indexPath:(NSIndexPath *)indexPath tableName:(NSString *)tableName{
    
    self.collView = collView;
    self.indexPath = indexPath;
    self.collName = tableName;
  
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Collection View Data Sources

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.suggestedBooksView) {
        return self.appDelegate.suggestedBooks.count;
    } else if (collectionView == self.favouriteCollectionView) {
            return self.appDelegate.favouriteBooks.count;
    } else if (collectionView == self.customCollectionView) {
            return self.appDelegate.customListBooks.count;
    }
    
    else return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BookCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
    
    if ([indexPath isEqual:self.indexPath] && self.isEditMode && [collectionView isEqual:self.collView]) {
        cell.deleteButton.hidden = NO;
        cell.readButton.hidden = NO;
        [cell.readButton addTarget:self action:@selector(markBookAsRead:) forControlEvents:UIControlEventTouchUpInside];
        [cell.deleteButton addTarget:self action:@selector(deleteCell:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        cell.deleteButton.hidden = YES;
        cell.readButton.hidden = YES;
        [cell.readButton addTarget:self action:@selector(markBookAsRead:) forControlEvents:UIControlEventTouchUpInside];
        [cell.deleteButton addTarget:self action:@selector(deleteCell:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    
    NSLog(@"showing book");
    
    if (collectionView == self.suggestedBooksView) {
        
        BooksDatabase *bDB = [self.appDelegate.suggestedBooks objectAtIndex:indexPath.row];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *imageName = [NSString stringWithFormat:@"suggestedBooks%ld.png",(long)bDB.ID];
        NSString* pngFilePath = [docDir stringByAppendingPathComponent:imageName];
        
        if ([fileManager fileExistsAtPath:pngFilePath])
        {
            UIImage *bookImage = [[UIImage alloc] initWithContentsOfFile:pngFilePath];
            cell.bookImage.image = bookImage;
            cell.ID = bDB.ID;
            NSLog(@"loading from memory");
            if (![self.suggestedBooksView.bookImages containsObject:pngFilePath])
                [self.suggestedBooksView.bookImages addObject:pngFilePath];
        } else {
            
            
            NSURL *url = [NSURL URLWithString:bDB.coverLink];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *bookImage = [[UIImage alloc] initWithData:data]; //i can add this image to an array so i have it in memory all the time; or I can add it to the same book once downloaded and keep it there
            cell.bookImage.image = bookImage;
            
            cell.ID = bDB.ID;
            
            if (![self.suggestedBooksView.bookImages containsObject:pngFilePath] && data!=NULL) {
                [self.suggestedBooksView.bookImages addObject:pngFilePath];
                
                NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                
                // If you go to the folder below, you will find those pictures
                NSLog(@"%@",docDir);
                
                NSLog(@"saving png");
                NSString *imageName = [NSString stringWithFormat:@"suggestedBooks%ld.png",(long)cell.ID];
                NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",docDir, imageName];
                NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(bookImage)];
                [data1 writeToFile:pngFilePath atomically:YES];
            }
            
        }
        
    } else if (collectionView == self.favouriteCollectionView) {
        
        NSLog(@"favourite count %lu", self.appDelegate.favouriteBooks.count);
        
        BooksDatabase *bDB = [self.appDelegate.favouriteBooks objectAtIndex:indexPath.row];
        
        //if image is stored then show it if not and there is internet connection load it and store it
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *imageName = [NSString stringWithFormat:@"favouriteBooks%ld.png",(long)bDB.ID];
        NSString* pngFilePath = [docDir stringByAppendingPathComponent:imageName];
        
        NSLog(@"%@", imageName);
        
         NSLog(@"%@", pngFilePath);
        
        if ([fileManager fileExistsAtPath:pngFilePath])
        {
            UIImage *bookImage = [[UIImage alloc] initWithContentsOfFile:pngFilePath];
            cell.bookImage.image = bookImage;
            cell.ID = bDB.ID;
            NSLog(@"loading from memory");
            
        } else {
            NSLog(@"need to save new book");
            NSURL *url = [NSURL URLWithString:bDB.coverLink];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *bookImage = [[UIImage alloc] initWithData:data]; //i can add this image to an array so i have it in memory all the time; or I can add it to the same book once downloaded and keep it there
            cell.bookImage.image = bookImage;
            
            cell.ID = bDB.ID;
            
                NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                
                // If you go to the folder below, you will find those pictures
                NSLog(@"%@",docDir);
                
                NSLog(@"saving png");
                NSString *imageName = [NSString stringWithFormat:@"favouriteBooks%ld.png",(long)cell.ID];
                NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",docDir, imageName];
                NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(bookImage)];
                [data1 writeToFile:pngFilePath atomically:YES];
           
        }
        
        NSLog(@"favourite collection view book images %lu", self.favouriteCollectionView.bookImages.count);
        
        //make this customizable pls
    } else if (collectionView == self.customCollectionView) {
        BooksDatabase *bDB = [self.appDelegate.customListBooks objectAtIndex:indexPath.row];
        
        //if image is stored then show it if not and there is internet connection load it and store it
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *imageName = [NSString stringWithFormat:@"%@Books%ld.png",self.tableName,(long)bDB.ID];
        
        NSString* pngFilePath = [docDir stringByAppendingPathComponent:imageName];
        
        NSLog(@"%@", pngFilePath);
        
        
        if ([fileManager fileExistsAtPath:pngFilePath])
        {
            UIImage *bookImage = [[UIImage alloc] initWithContentsOfFile:pngFilePath];
            cell.bookImage.image = bookImage;
            cell.ID = bDB.ID;
            NSLog(@"loading from memory custom");
        } else {
            
            NSURL *url = [NSURL URLWithString:bDB.coverLink];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *bookImage = [[UIImage alloc] initWithData:data]; //i can add this image to an array so i have it in memory all the time; or I can add it to the same book once downloaded and keep it there
            cell.bookImage.image = bookImage;
            
            cell.ID = bDB.ID;
            
            NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            
            // If you go to the folder below, you will find those pictures
            NSLog(@"%@",docDir);
            
            NSLog(@"saving png");
            NSString *imageName = [NSString stringWithFormat:@"%@Books%ld.png",self.tableName, (long)cell.ID];
            NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",docDir, imageName];
            NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(bookImage)];
            [data1 writeToFile:pngFilePath atomically:YES];
            
            
        }
        
    }
    return cell;
}

- (void)removeImage:(NSString *)filePath
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:&error];
    if (error){
        NSLog(@"%@", error);
    }
}

- (void)markBookAsRead:(UIButton *)sender {
    
    NSLog(@"marked as read");
    if (self.indexPath != nil) {
        
        BookCollectionViewCell *cell;
        if ([self.collName rangeOfString:@"favourite" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            
            cell = (BookCollectionViewCell*)[self.favouriteCollectionView cellForItemAtIndexPath:self.indexPath];
            
        } else {
            cell = (BookCollectionViewCell*)[self.customCollectionView cellForItemAtIndexPath:self.indexPath];
        }
        //then remove it from the orifinal book list and from the specific view
        
        NSLog(@"saving png from indexPath: %lu", self.indexPath.row);
        
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        self.uniqueID  = self.uniqueID + 1;
        NSString *imageName = [NSString stringWithFormat:@"readBooks%ld.png", (long)self.uniqueID];;
        NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",docDir, imageName];
        NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(cell.bookImage.image)];
        
        [data1 writeToFile:pngFilePath atomically:YES];
        
        NSString *imageN = [NSString stringWithFormat:@"%@%ld.png",self.collName,(long)self.indexPath.row];
        
        NSLog(@"imageNAme %@", imageN);
        
        NSString* pngFilePathh = [docDir stringByAppendingPathComponent:imageN];
        NSLog(@"%@", pngFilePathh);
        [self.appDelegate moveBooksToReadInTheDatabase:self.collName ID:cell.ID indexPath:self.indexPath.row];
        [self.appDelegate deleteBooksToReadFromOriginalTableWithoutDeletingFromTable:self.collName ID:cell.ID indexPath:self.indexPath.row];

        [self removeImage:pngFilePathh];
    }
    
    [self.collView reloadData];
    
    self.indexPath = nil;
    self.collView = nil;
    self.bookImages = nil;
    self.collName = nil;
    
}


-(void)deleteCell:(UIButton *)sender {
    
    NSLog(@"here to delete");
    
    if (self.indexPath != nil) {
        BookCollectionViewCell *cell;
        if ([self.collName rangeOfString:@"favourite" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            
            cell = (BookCollectionViewCell*)[self.favouriteCollectionView cellForItemAtIndexPath:self.indexPath];
            
        } else {
            cell = (BookCollectionViewCell*)[self.customCollectionView cellForItemAtIndexPath:self.indexPath];
        }
        
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

        
        NSString *imageN = [NSString stringWithFormat:@"%@%ld.png",self.collName,(long)self.indexPath.row];
        
        NSLog(@"imageNAme %@", imageN);
        
        NSString* pngFilePathh = [docDir stringByAppendingPathComponent:imageN];
        NSLog(@"%@", pngFilePathh);
        [self.appDelegate deleteBooksToReadFromOriginalTable:self.collName ID:cell.ID indexPath:self.indexPath.row];
        [self removeImage:pngFilePathh];
      }
    
    
    [self.collView reloadData];
    
    self.indexPath = nil;
    self.collView = nil;
    self.bookImages = nil;
    self.collName = nil;
    
}




// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.pickerViewData count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [self.pickerViewData objectAtIndex: row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSLog(@"You selected this: %@", [self.pickerViewData objectAtIndex: row]);
    
    if ([[self.pickerViewData objectAtIndex:row] isEqualToString:@"Create New List"]) {
        
        NSLog(@"here");
        
        self.av = [[UIAlertView alloc] initWithTitle:@"Create New List" message:@"Would you like to create a new list called?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        
        [self.av setAlertViewStyle:UIAlertViewStylePlainTextInput];
        
        [self.av show];
        
    } else {
        [self.customListButton setTitle:[self.pickerViewData objectAtIndex:row] forState:UIControlStateNormal];
        
        [self loadCustomListDatabaseAndRefreshView:[self.pickerViewData objectAtIndex:row]];
        
        NSLog(@"changed to %@", [self.pickerViewData objectAtIndex:row]);
        
          }
    
    [self.customCollectionView reloadData];
    
    [self.pickerView removeFromSuperview];
    
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)
    {
        NSLog(@"You have clicked No");
    }
    else if(buttonIndex == 1)
    {
        NSLog(@"You have clicked Yes with listName %@", [[self.av textFieldAtIndex:0] text]);
        self.customListTitle = [[self.av textFieldAtIndex:0] text];
        NSLog(@"%@", self.customListTitle);
        
        [self.appDelegate createNewCustomListInTheDatabase:[[self.av textFieldAtIndex:0] text]];
        [self.customListButton setTitle:[self.customListTitle capitalizedString] forState:UIControlStateNormal];
        [self loadCustomListDatabaseAndRefreshView:self.customListTitle];
        [self initiatePickerViewWithTableNames];
    }
}


- (IBAction)customListSelector:(id)sender {
    
    
    self.pickerView = [[UIPickerView alloc] init];
    
    // Calculate the screen's width.
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    float pickerWidth = screenWidth * 3 / 4;
    
    // Calculate the starting x coordinate.
    float xPoint = screenWidth / 2 - pickerWidth / 2;
    
    // Set the picker's frame. We set the y coordinate to 50px.
    [self.pickerView setFrame: CGRectMake(xPoint, 245.0f, pickerWidth, 130.0f)];
    
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.backgroundColor = [UIColor whiteColor];
    
    [self.pickerView selectRow:0 inComponent:0 animated:NO];
    
    [self.view addSubview:self.pickerView];
    
}

- (IBAction)showQRReader:(id)sender {
}

- (IBAction)showMenu:(id)sender {
    
    NSLog(@"in side menu here");
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{}];
    
}


@end
