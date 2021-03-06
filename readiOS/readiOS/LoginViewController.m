//
//  LoginViewController.m
//  readiOS
//
//  Created by Ingrid Funie on 06/08/2014.
//  Copyright (c) 2014 colibri. All rights reserved.
//

#import "LoginViewController.h"
#import "TutorialOptionViewController.h"
#import "ViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.wrongLoginMessage.hidden = YES;
    self.username.delegate = self;
    self.password.delegate = self;
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestDataAndShowMainView {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        
        
        @try {
            
            
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                
                [self.appDelegate requestBooksAndCreateDatabaseEntries];
                
                UIStoryboard *mainStoryboard;
                
                mainStoryboard = [self.appDelegate setStoryboard];
                
                
                ViewController *mainViewController = (ViewController*)[mainStoryboard
                                                                       instantiateViewControllerWithIdentifier: @"MainViewController"];
                
                [self.appDelegate setupMenu:mainViewController];

            });
            
            
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            [self showWithCustomView:@"No Internet Connection"];
        }
        
    });
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)login:(id)sender {
    
    NSString* responseMessage;
    
    self.wrongLoginMessage.hidden = YES;
    
    if ([self.appDelegate connectedToInternet]) {
        NSLog(@"loging in");
        responseMessage = [self.appDelegate login:self.username.text password:self.password.text];
         NSLog(@"response: %@", responseMessage);
    } else {
        [self showWithCustomView:@"No Internet Connection"];
    }
    
    if ([responseMessage isEqualToString:@"Invalid username or password"]) {
        NSLog(@"can t login");
        self.wrongLoginMessage.hidden = NO;
    } else if ([responseMessage isEqualToString: @"Server Down"]){
        [self showWithCustomView:@"Something went wrong."];
    } else {
    
         NSLog(@"response: %@", responseMessage);
        
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSeenTutorial"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self showSimple];
        [self requestDataAndShowMainView];
        
    }
    
    [self.view endEditing:YES];
    
}

- (IBAction)cancel:(id)sender {
    TutorialOptionViewController *tutorial = [self.storyboard instantiateViewControllerWithIdentifier:@"TutorialOptionViewController"];
    
    [self addChildViewController:tutorial];
    [self.view addSubview:tutorial.view];
    [tutorial didMoveToParentViewController:self];
}

-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.username isFirstResponder] && [touch view] != self.username) {
        [self.username resignFirstResponder];
    }
    
    if ([self.password isFirstResponder] && [touch view] != self.password) {
        [self.password resignFirstResponder];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldDidBeginEditing");
    self.wrongLoginMessage.hidden = YES;
}


- (void)showSimple {
	// The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	// Regiser for HUD callbacks so we can remove it from the window at the right time
	HUD.delegate = self;
	
	// Show the HUD while the provided method executes in a new thread
	[HUD showWhileExecuting:@selector(requestDataAndShowMainView) onTarget:self withObject:nil animated:YES];
}

- (void)showWithCustomView:(NSString*)message {
	
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	// The sample image is based on the work by http://www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
	// Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
	HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark@2x.png"]];
	
	// Set custom view mode
	HUD.mode = MBProgressHUDModeCustomView;
	
	HUD.delegate = self;
    //modify this according to the needs
	HUD.labelText = message;
	
	[HUD show:YES];
	[HUD hide:YES afterDelay:1.5];
}

@end
