//
//  SparkSetupManager.m
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/15/14.
//  Copyright (c) 2014-2015 Spark. All rights reserved.
//

#import "SparkSetupMainController.h"
#import "SparkUserSignupViewController.h"
#import "SparkSetupCommManager.h"
#import "SparkSetupConnection.h"
#import "SparkCloud.h"
#import "SparkSetupCustomization.h"
#import "SparkUserLoginViewController.h"

NSString *const kSparkSetupDidFinishNotification = @"kSparkSetupDidFinishNotification";
NSString *const kSparkSetupDidFinishStateKey = @"kSparkSetupDidFinishStateKey";
NSString *const kSparkSetupDidFinishDeviceKey = @"kSparkSetupDidFinishDeviceKey";
NSString *const kSparkSetupDidLogoutNotification = @"kSparkSetupDidLogoutNotification";


@interface SparkSetupMainController() <SparkUserLoginDelegate>

//@property (nonatomic, strong) UINavigationController *setupNavController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) UIViewController *currentVC;

@end

@implementation SparkSetupMainController

+(SparkSetupMainController *)new //instanciateSparkSetupMainController
{
    SparkSetupMainController* mainVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"root"];
    return mainVC;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDidFinishObserver:) name:kSparkSetupDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDidLogoutObserver:) name:kSparkSetupDidLogoutNotification object:nil];
    
    if ([SparkCloud sharedInstance].loggedInUsername)
    {
        // start from discover screen if user is already logged in
        [self runSetup];
    }
    else
    {
        // else login
        [self showSignup];
    }


}

-(void)runSetup
{
    UINavigationController* setupVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"setup"];
    [self showViewController:setupVC];
}

-(void)showSignup
{
    [self showSignupWithPredefinedActivationCode:nil];
}

-(void)showSignupWithPredefinedActivationCode:(NSString *)activationCode;
{
    SparkUserSignupViewController *signupVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"signup"];
    signupVC.predefinedActivationCode = activationCode;
    signupVC.delegate = self;
    [self showViewController:signupVC];
}


-(void)showLogin
{
    SparkUserLoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"login"];
    loginVC.delegate = self;
    [self showViewController:loginVC];
}

-(void)showPasswordReset
{
    SparkUserLoginViewController *pwdrstVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"password_reset"];
    pwdrstVC.delegate = self;
    [self showViewController:pwdrstVC];
}


-(void)setupDidLogoutObserver:(NSNotification *)note
{
    // User intentionally logged out so display the login/signup screens
    [self showLogin];
}

#pragma mark SparkUserLoginDelegate methods
-(void)didFinishUserLogin:(id)sender
{
    [self runSetup];
}


-(void)didRequestPasswordReset:(id)sender
{
    [self showPasswordReset];
}

-(void)didRequestUserSignup:(id)sender
{
    [self showSignup];
}

-(void)didRequestUserLogin:(id)sender
{
    [self showLogin];
}

#pragma mark Observer for setup end notifications
-(void)setupDidFinishObserver:(NSNotification *)note
{
    // Setup finished so dismiss modal main controller and call delegate with state
    
    NSDictionary *finishStateDict = note.userInfo;
    NSNumber* state = finishStateDict[kSparkSetupDidFinishStateKey];
    SparkDevice *device = finishStateDict[kSparkSetupDidFinishDeviceKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkSetupDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkSetupDidLogoutNotification object:nil];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate sparkSetupViewController:self didFinishWithResult:[state integerValue] device:device]; // TODO: add NSError reporting?
    }];
}

// viewcontroller container behaviour code
- (void)showViewController:(UIViewController *)viewController
{
    if (self.currentVC)
    {
        [self addChildViewController:viewController];
        [self transitionFromViewController:self.currentVC toViewController:viewController duration:0.5f options:UIViewAnimationOptionTransitionFlipFromTop animations:nil completion:nil];
        [self hideViewController:self.currentVC];
    }
    self.currentVC = viewController;
    [self.containerView endEditing:YES];
    [self addChildViewController:viewController];
    viewController.view.frame = self.containerView.frame; 
    [self.containerView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)hideViewController:(UIViewController *)viewController;
{
    [self.containerView endEditing:YES];
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}


-(void)dealloc
{
    // check
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkSetupDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkSetupDidLogoutNotification object:nil];

}


@end
