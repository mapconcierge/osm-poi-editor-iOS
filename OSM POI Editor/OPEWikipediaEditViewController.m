//
//  OPEWikipediaEditViewController.m
//  OSM POI Editor
//
//  Created by David on 6/11/13.
//
//

#import "OPEWikipediaEditViewController.h"
#import "OPEWikipediaWebViewController.h"


@interface OPEWikipediaEditViewController ()

@end

@implementation OPEWikipediaEditViewController

@synthesize languageButton,locale;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    wikipediaManager = [[OPEWikipediaManager alloc] init];
    wikipediaResultsArray = [NSArray array];
    
    NSArray * array = [wikipediaManager seperateRawWikipediaValue:self.currentOsmValue];
    self.textField.text = array[1];
    self.locale = array[0];
    languageButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypePrimary];
    [languageButton setTitle:self.locale forState:UIControlStateNormal];
    [languageButton addTarget:self action:@selector(languageButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
     __block NSMutableArray * languages = [[wikipediaManager mostPopularLanguages]mutableCopy];
    supportedWikipedialanguges = languages;
    [wikipediaManager fetchAllWikipediaLanguagesSucess:^(NSArray *results) {
        NSPredicate *relativeComplementPredicate = [NSPredicate predicateWithFormat:@"NOT SELF.code IN %@", [languages valueForKey:@"code"]];
        NSArray *relativeComplement = [results filteredArrayUsingPredicate:relativeComplementPredicate];
        [languages addObjectsFromArray:relativeComplement];
    } failure:^(NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error");
    }];
}

-(void)languageButtonSelected:(id)sender
{
    [self.view resignFirstResponder];
    UIPickerView * pickerView = [[UIPickerView alloc] init];
    pickerView.delegate = self;
    
    [self.view addSubview:pickerView];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [wikipediaManager fetchSuggesionsWithLanguage:self.locale query:newString success:^(NSArray *results) {
        [self updateResults:results];
    } failure:^(NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error");
    }];
    
    return YES;
}

-(void)updateResults:(NSArray *)resultsArray;
{
    UITableView * tableView = (UITableView *)[self.view viewWithTag:kTableViewTag];
    [tableView beginUpdates];
    
    NSMutableArray* rowsToDelete = [NSMutableArray array];
    NSMutableArray* rowsToInsert = [NSMutableArray array];
    
    if ([resultsArray count] && ![wikipediaResultsArray count]) {
        [tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (![resultsArray count] && [wikipediaResultsArray count])
    {
        [tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    for (NSInteger index = 0; index < [resultsArray count]; index++)
    {
        NSString * result = [resultsArray objectAtIndex:index];
        NSUInteger indexInOldArray = [wikipediaResultsArray indexOfObject:result];
        if (indexInOldArray == NSNotFound) {
            [rowsToInsert addObject:[NSIndexPath indexPathForRow:index inSection:1]];
        }
        else{
            [tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:indexInOldArray inSection:1] toIndexPath:[NSIndexPath indexPathForRow:index inSection:1]];
        }
    }
    
    for (NSInteger index = 0; index < [wikipediaResultsArray count]; index++)
    {
        NSString * oldResult = [wikipediaResultsArray objectAtIndex:index];
        NSUInteger objectIndex = [resultsArray indexOfObject:oldResult];
        if (objectIndex == NSNotFound) {
            [rowsToDelete addObject:[NSIndexPath indexPathForRow:index inSection:1]];
        }
    }
    
    [tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView insertRowsAtIndexPaths:rowsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    wikipediaResultsArray = resultsArray;
    [tableView endUpdates];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([wikipediaResultsArray count]) {
        return 2;
    }
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return [wikipediaResultsArray count];
    }
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    NSString * cellIdentifierConstant = @"wikipediaCellConstant";
    if (indexPath.section == 0) {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        CGRect contentViewFrame = cell.contentView.frame;
        CGRect textFieldFrame = self.textField.frame;
        self.textField.frame = CGRectMake(textFieldFrame.origin.x + 54, textFieldFrame.origin.y, textFieldFrame.size.width -54, textFieldFrame.size.height);
        [self.languageButton removeFromSuperview];
        self.languageButton.frame = CGRectMake(0, 0, 50, contentViewFrame.size.height);
        [cell.contentView addSubview:languageButton];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierConstant];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierConstant];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        cell.textLabel.text = [wikipediaResultsArray objectAtIndex:indexPath.row];
        
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    OPEWikipediaWebViewController * webView = [[OPEWikipediaWebViewController alloc] initWithWikipediaArticaleTitle:[wikipediaResultsArray objectAtIndex:indexPath.row] withLocale:@"en"];
    [self.navigationController pushViewController:webView animated:YES];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==1) {
        self.textField.text = [wikipediaResultsArray objectAtIndex:indexPath.row];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
