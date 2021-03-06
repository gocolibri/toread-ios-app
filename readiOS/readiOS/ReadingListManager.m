//
//  ReadingListManager.m
//  readiOS
//
//  Created by Ingrid Funie on 23/07/2014.
//  Copyright (c) 2014 colibri. All rights reserved.
//

#import "ReadingListManager.h"
#import "ReadingListDetail.h"

@interface ReadingListManager ()

@end

@implementation ReadingListManager
@synthesize tableNames;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [self.appDelegate getAllDatabaseTableNames];
    self.tableNames = [[NSMutableArray alloc] initWithArray:self.appDelegate.tableNames];
    
    NSMutableArray *newTable = [[NSMutableArray alloc] init];
    
    for (NSString* name in self.tableNames) {
        if ([name rangeOfString:@"suggested"].location != NSNotFound || [name rangeOfString:@"read"].location != NSNotFound) {
            continue;
        } else{
            [newTable addObject:[[name stringByReplacingOccurrencesOfString:@"Books" withString:@""] capitalizedString]];
        }
    }
    
    self.tableNames = [newTable mutableCopy];
}

- (IBAction)dismissView:(id)sender {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog (@"number of tables %li", (unsigned long)self.tableNames.count);
    return self.tableNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    cell.textLabel.text = [self.tableNames objectAtIndex:indexPath.row];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault; //hmm
    
    cell.backgroundColor = [UIColor blackColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    
    NSLog (@"selected ");
    ReadingListDetail *readingListDetail = [[ReadingListDetail alloc] initWithNibName:@"ReadingListDetail" bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    readingListDetail.tableName = [[[self.tableNames objectAtIndex:indexPath.row] lowercaseString] stringByAppendingString:@"Books"];
    
    [self presentViewController:readingListDetail animated:NO completion:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Button Index =%ld",(long)buttonIndex);
    
    if (self.av.tag == 0) {
        if (buttonIndex == 0)
        {
            NSLog(@"You have clicked NO");
        }
        else if(buttonIndex == 1)
        {
            NSLog(@"You have clicked Yes to delete %li", (long)self.indexPath.row);
            //delete from database
            [self.appDelegate deleteTableFromDatabase:[[self.tableNames objectAtIndex:self.indexPath.row] lowercaseString]];
            NSLog(@"deleted tables %@", [[self.tableNames objectAtIndex:self.indexPath.row] lowercaseString]);
            [self.tableNames removeObjectAtIndex:self.indexPath.row];
            NSLog(@"count: %lu",(unsigned long)self.tableNames.count);
            [self.tableView deleteRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            NSLog(@"should work now");

        }
        
    }
    
    
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //the user can delete everything but the favourite one
    if (editingStyle == UITableViewCellEditingStyleDelete && ![[self.tableNames objectAtIndex:indexPath.row] isEqualToString:@"Favourite"]) {
        
        self.av = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Do you really want to delete this?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        self.av.tag = 0;
        
        [self.av show];
        
        self.indexPath = indexPath;
        
        NSLog(@"indexPath %li", (long)self.indexPath.row);
        
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

/*- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView setEditing:YES animated:YES];
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView setEditing:NO animated:YES];
}*/


@end
