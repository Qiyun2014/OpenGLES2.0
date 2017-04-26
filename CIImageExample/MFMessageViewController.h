//
//  MFMessageViewController.h
//  CIImageExample
//
//  Created by IYNMac on 14/4/17.
//  Copyright © 2017年 IYNMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>

@interface MFMessageViewController : UIViewController

@property (strong, nonatomic) MFMessageComposeViewController    *messageComposeViewController;

@end
