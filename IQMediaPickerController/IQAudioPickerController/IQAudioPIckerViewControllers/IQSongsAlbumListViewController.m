//
//  IQSongsAlbumListViewController.m
//  https://github.com/hackiftekhar/IQMediaPickerController
//  Copyright (c) 2013-17 Iftekhar Qurashi.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


@import MediaPlayer;

#import "IQSongsAlbumListViewController.h"
#import "IQAudioPickerUtility.h"
#import "IQSongsListViewController.h"
#import "IQSongsAlbumViewCell.h"
#import "IQAudioPickerController.h"
#import "IQMediaPickerControllerConstants.h"

@interface IQSongsAlbumListViewController ()

@property UIBarButtonItem *doneBarButton;
@property UIBarButtonItem *selectedMediaCountItem;

@end

@implementation IQSongsAlbumListViewController
{
    NSArray *collections;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Albums";
        self.tabBarItem.image = [UIImage imageNamed:@"albums" inBundle:[NSBundle bundleWithIdentifier:BundleIdentifier] compatibleWithTraitCollection:nil];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 80;
    [self.tableView registerClass:[IQSongsAlbumViewCell class] forCellReuseIdentifier:NSStringFromClass([IQSongsAlbumViewCell class])];

    MPMediaQuery *query = [MPMediaQuery albumsQuery];
    collections = [query collections];

    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelItem;

    self.doneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];

    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.selectedMediaCountItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.selectedMediaCountItem.possibleTitles = [NSSet setWithObject:@"999 media selected"];
    self.selectedMediaCountItem.enabled = NO;
    
    self.toolbarItems = @[flexItem,self.selectedMediaCountItem,flexItem];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateSelectedCount];
}

-(void)updateSelectedCount
{
    if ([self.audioPickerController.selectedItems count])
    {
        [self.navigationItem setRightBarButtonItem:self.doneBarButton animated:YES];
        
        [self.navigationController setToolbarHidden:NO animated:YES];
        
        NSString *finalText = [NSString stringWithFormat:@"%lu Media selected",(unsigned long)[self.audioPickerController.selectedItems count]];
        
        if (self.audioPickerController.maximumItemCount > 0)
        {
            finalText = [finalText stringByAppendingFormat:@" (%lu maximum) ",(unsigned long)self.audioPickerController.maximumItemCount];
        }
        
        self.selectedMediaCountItem.title = finalText;
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
        self.selectedMediaCountItem.title = nil;
    }
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.audioPickerController.delegate respondsToSelector:@selector(audioPickerController:didPickMediaItems:)])
    {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        for (MPMediaItem *item in self.audioPickerController.selectedItems)
        {
            NSDictionary *dict = [NSDictionary dictionaryWithObject:item forKey:IQMediaItem];
            
            [items addObject:dict];
        }
        
        [self.audioPickerController.delegate audioPickerController:self.audioPickerController didPickMediaItems:items];
    }
    
    [self.audioPickerController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.audioPickerController.delegate respondsToSelector:@selector(audioPickerControllerDidCancel:)])
    {
        [self.audioPickerController.delegate audioPickerControllerDidCancel:self.audioPickerController];
    }
    
    [self.audioPickerController dismissViewControllerAnimated:YES completion:nil];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return collections.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IQSongsAlbumViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([IQSongsAlbumViewCell class]) forIndexPath:indexPath];
    
    MPMediaItemCollection *item = [collections objectAtIndex:indexPath.row];
    
    MPMediaItemArtwork *artwork = [item.representativeItem valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:artwork.bounds.size];
    cell.imageViewAlbum.image = image;
    cell.labelTitle.text = [item.representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle];
    cell.labelSubTitle.text = [item.representativeItem valueForProperty:MPMediaItemPropertyAlbumArtist];
    
    if (item.items.count == 0)
    {
        cell.labelSubSubTitle.text = [NSString stringWithFormat:@"no songs"];
    }
    else
    {
        NSUInteger totalMinutes = [IQAudioPickerUtility mediaCollectionDuration:item];
        cell.labelSubSubTitle.text = [NSString stringWithFormat:@"%lu %@, %lu %@",(unsigned long)item.count,(item.count>1?@"songs":@"song"),(unsigned long)totalMinutes,(totalMinutes>1?@"mins":@"min")];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IQSongsListViewController *controller = [[IQSongsListViewController alloc] init];
    controller.audioPickerController = self.audioPickerController;
    controller.collections = @[[collections objectAtIndex:indexPath.row]];
    
    [self.navigationController pushViewController:controller animated:YES];
}


@end
