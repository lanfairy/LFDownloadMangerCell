//
//  LFCell.h
//  LFDownloadMangerCell
//
//  Created by 张俊伟 on 16/3/13.
//  Copyright © 2016年 lanfairy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFCell : UITableViewCell
@property (copy, nonatomic) NSString *url;

+(instancetype)fileCellWithTableView:(UITableView *)tableView;

- (void)download:(UIButton *)sender;
@end
