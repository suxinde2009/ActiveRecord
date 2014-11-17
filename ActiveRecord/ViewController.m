//
//  ViewController.m
//  ActiveRecord
//
//  Created by kenny on 5/17/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "ViewController.h"
#import "ActiveRecordBase.h"
#import "User.h"
@interface ViewController(){
    __weak IBOutlet UITableView *_userTable;
    __weak IBOutlet UITextField *_searchTextField;
    NSMutableArray *_users;
    NSInteger _page;
}
- (IBAction)prePage:(id)sender;
- (IBAction)nextPage:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)insert:(UIButton *)sender;
@end
@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _page = 0;
    _users = [NSMutableArray arrayWithArray: [[User perPage:3] result]];
}

- (IBAction)prePage:(id)sender {
    _page--;
    _users = [NSMutableArray arrayWithArray: [[[User perPage:3] page:_page] result]];
    [_userTable reloadData];
}

- (IBAction)nextPage:(id)sender {
    _page++;
    _users = [NSMutableArray arrayWithArray: [[[User perPage:3] page:_page] result]];
    [_userTable reloadData];
}

- (IBAction)search:(id)sender {
    NSString *keywords = _searchTextField.text;
    NSArray *users  = [[User where:[NSString stringWithFormat:@"name LIKE '%%%@%%' ", keywords]] result];
    _users = [NSMutableArray arrayWithArray:users];
    [_userTable reloadData];
    [_searchTextField resignFirstResponder];
}

- (IBAction)insert:(UIButton *)sender {
    User *user = [User create:@{@"name":[NSString stringWithFormat:@"%@", [NSDate date]]}];
    [_users addObject:user];
    NSArray *paths = @[[NSIndexPath indexPathForRow:([_users indexOfObject:user] - 0) inSection:0]];
    [_userTable insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    User *user = [_users objectAtIndex:indexPath.row];
    cell.textLabel.text = [user attribute:@"name"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        User *user = [_users objectAtIndex:indexPath.row];
        [user destory];
        [_users removeObject:user];
        [_userTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    }
}
@end
