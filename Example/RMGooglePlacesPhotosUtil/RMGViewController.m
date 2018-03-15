//
//  RMGViewController.m
//  RMGooglePlacesPhotosUtil
//
//  Created by rjmiller2543 on 03/14/2018.
//  Copyright (c) 2018 rjmiller2543. All rights reserved.
//

#import "RMGViewController.h"
#import <RMGooglePlacesPhotosUtil/RMGooglePlacesPhotosUtil.h>

@interface RMGViewController ()

@end

@implementation RMGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    RMGooglePlacesPhotosUtil *util = [[RMGooglePlacesPhotosUtil alloc] initWithApiKey:@"AIzaSyAAc3iUQR2KTQg8_nnRCNs2DXkJen2siVE"];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.7414382, -119.6022289);
    [util getImageWithLocation:coordinate type:@"park" name:@"Yosemite Falls Trailhead" callback:^(NSError *error, UIImage *image) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [self.imageView setImage:image];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
