//
//  BookCollectionViewCell.h
//  readiOS
//
//  Created by Ingrid Funie on 04/01/2014.
//  Copyright (c) 2014 colibri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface BookCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *bookLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bookImage;

@property (assign, nonatomic) NSInteger ID;

@end
