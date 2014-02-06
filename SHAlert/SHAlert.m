//
//  SHAlert.m
//  SHAlertExample
//
//  Created by Seivan Heidari on 3/11/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHAlert.h"

@interface SHViewControllerAlert ()
typedef void(^SHAlertReadyBlock)();
@property(nonatomic,strong) IBOutletCollection(UIView) NSArray * setOfOutlets;

@property(nonatomic,strong) IBOutlet UIButton * btnDestructive;
@property(nonatomic,strong) IBOutlet UIButton * btnCancel;
@property(nonatomic,strong) IBOutletCollection(UIView) NSArray * actionOutlets;
@property(nonatomic,strong) IBOutlet NSSet    * setOfActionButtons;

@property(nonatomic,strong) IBOutlet UILabel  * lblTitle;
@property(nonatomic,strong) IBOutlet UILabel  * lblMessage;

@property(nonatomic,strong) IBOutlet UIView   * viewAlertBackground;
@property(nonatomic,strong) NSDictionary      * buttonsWithBlocks;

@property(nonatomic,setter=setTitleText:)   NSString * titleText;
@property(nonatomic,setter=setMessageText:) NSString * messageText;

-(void)setButtonTitleForButton:(UIButton *)theButton withTitle:(NSString *)theTitle
                     withBlock:(SHAlertButtonTappedBlock)theBlock;

-(void)setup;
-(void)setupDefaultAlert;
-(BOOL)isStyle:(NSString *)theStyle onView:(UIView *)theView;

@end

@implementation SHViewControllerAlert

-(void)setup; {
    self.setOfActionButtons = [NSSet setWithArray:self.actionOutlets];
}

-(void)setButtonTitleForCancel:(NSString *)theTitle withBlock:(SHAlertButtonTappedBlock)theBlock; {
  [self setButtonTitleForButton:self.btnCancel withTitle:theTitle withBlock:theBlock];

}

-(void)setButtonTitleForDestructive:(NSString *)theTitle withBlock:(SHAlertButtonTappedBlock)theBlock; {
  [self setButtonTitleForButton:self.btnDestructive withTitle:theTitle withBlock:theBlock];

}

-(void)setButtonTitleForAction:(NSString *)theTitle withBlock:(SHAlertButtonTappedBlock)theBlock; {
  NSMutableSet * set = self.setOfActionButtons.mutableCopy;
  UIButton * button = self.setOfActionButtons.anyObject;
  [self setButtonTitleForButton:button withTitle:theTitle withBlock:theBlock];
  [set removeObject:button];
  self.setOfActionButtons = set.copy;
}

-(void)setButtonTitleForButton:(UIButton *)theButton withTitle:(NSString *)theTitle
                     withBlock:(SHAlertButtonTappedBlock)theBlock; {

  if(theTitle == nil) {
    theTitle = [theButton titleForState:UIControlStateNormal];
  }

  NSAssert(theTitle, @"Must pass a title");
  NSAssert1(theButton, @"Must pass a button for title %@", theTitle);
  NSMutableDictionary * buttonsWithBlocks =  self.buttonsWithBlocks.mutableCopy;
  if(theBlock) buttonsWithBlocks[theTitle] = theBlock ;
  self.buttonsWithBlocks = buttonsWithBlocks.copy;
  [theButton setTitle:theTitle forState:UIControlStateNormal];
  [theButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)viewDidLoad; {
  [super viewDidLoad];
  self.buttonsWithBlocks = @{};

  if(self.view.subviews.count < 1) {
    [self setupDefaultAlert];
  } else {
    [self setup];
  }
}



-(void)buttonTapped:(id)sender; {
  UIButton * theTappedButton = (UIButton *)sender;
  NSString * buttonTitle =  [theTappedButton titleForState:UIControlStateNormal];
  SHAlertButtonTappedBlock block = self.buttonsWithBlocks[buttonTitle];
  if(block) block(theTappedButton);
  [self dismiss];
}


-(void)show; {
  [self.delegate willShowAlert:self];
  UIWindow * window = [[UIApplication sharedApplication] keyWindow];
  self.view.alpha = 0.f;
  [window addSubview:self.view];
  [UIView animateWithDuration:0.2 animations:^{
    self.view.alpha = 1.f;
  } completion:^(BOOL finished) {
    [self.delegate didShowAlert:self];
  }];
}

-(void)dismiss; {
  [self.delegate willDismissAlert:self];
  [UIView animateWithDuration:0.2 animations:^{
    self.view.alpha = 0.f;
  } completion:^(BOOL finished) {
    [self.view removeFromSuperview];
    [self.delegate didDismissAlert:self];
  }];
}


-(void)setTitleText:(NSString *)textTitle; {
  self.lblTitle.text = textTitle;
}

-(void)setMessageText:(NSString *)textMessage; {
  self.lblMessage.text = textMessage;
}
@end


@interface SHAlert()
<SHViewControllerAlertDelegate>
@property(nonatomic,strong) NSOrderedSet * setOfOrderedAlerts;
@property(nonatomic,weak)   SHViewControllerAlert * currentAlertVc;
@property(nonatomic,strong) UIStoryboard * currentStoryboard;

+(SHAlert *)sharedManager;
-(void)addAlert:(SHViewControllerAlert *)theAlertVc;

@end

@implementation SHAlert

-(void)addAlert:(SHViewControllerAlert *)theAlertVc; {
  NSAssert(theAlertVc, @"Must have an alert");
  NSMutableOrderedSet * set = self.setOfOrderedAlerts.mutableCopy;
  [set addObject:theAlertVc];
  self.setOfOrderedAlerts = set.copy;
}

-(void)popAlert:(SHViewControllerAlert *)theAlertVc; {
  NSAssert(theAlertVc, @"Must have an alert");
  NSMutableOrderedSet * set =  self.setOfOrderedAlerts.mutableCopy;
  [set removeObject:theAlertVc];
  self.setOfOrderedAlerts = set.copy;

}

#pragma mark -
#pragma mark Initialize
-(id)init {
  self = [super init];
  if (self) {
    self.setOfOrderedAlerts = [NSOrderedSet orderedSet];
  }

  return self;
}

+(SHAlert *)sharedManager; {
  static dispatch_once_t once;
  static SHAlert * sharedManager;
  dispatch_once(&once, ^ { sharedManager = [[self alloc] init]; });
  return sharedManager;
}

+(void)registerStoryBoard:(UIStoryboard *)theStoryBoard; {
  SHAlert.sharedManager.currentStoryboard = theStoryBoard;
}

+(SHViewControllerAlert *)alertControllerWithStoryboardId:(NSString *)storyboardId withTitle:(NSString *)theTitle andMessage:(NSString *)theMessage; {

  UIStoryboard * storyboard =  SHAlert.sharedManager.currentStoryboard;

  NSAssert(storyboardId, @"Must specify storyboard id");
  NSAssert(storyboard, @"Must specify storyboard");

  UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    vc.view;
  SHViewControllerAlert * vcAlert = (SHViewControllerAlert *)vc;

  [vcAlert setTitleText:theTitle];
  [vcAlert setMessageText:theMessage];
  vcAlert.delegate = SHAlert.sharedManager;
  [SHAlert.sharedManager addAlert:vcAlert];

  return vcAlert;
}

+(SHViewControllerAlert *)alertName:(NSString *)alertName withTitle:(NSString *)theTitle
                         andMessage:(NSString *)theMessage; {
  NSAssert(alertName, @"Must specify alert name");
  SHViewControllerAlert * vcAlert = [[SHViewControllerAlert alloc] init];

  [vcAlert setTitleText:theTitle];
  [vcAlert setMessageText:theMessage];
  vcAlert.delegate = SHAlert.sharedManager;
  [SHAlert.sharedManager addAlert:vcAlert];


  return vcAlert;
}

-(void)willShowAlert:(SHViewControllerAlert *)theAlert; {
  NSAssert(theAlert, @"Must have an alert");
  self.currentAlertVc.view.alpha = 0.f;
}

-(void)didShowAlert:(SHViewControllerAlert *)theAlert; {
  NSAssert(theAlert, @"Must have an alert");
  self.currentAlertVc = theAlert;
}

-(void)willDismissAlert:(SHViewControllerAlert *)theAlert; {
  NSAssert(theAlert, @"Must have an alert");
  self.currentAlertVc.view.alpha = 1.f;
}

-(void)didDismissAlert:(SHViewControllerAlert *)theAlert; {
  NSAssert(theAlert, @"Must have an alert");
  [self popAlert:theAlert];
  self.currentAlertVc = self.setOfOrderedAlerts.lastObject;

}

@end

