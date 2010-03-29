/*  
 * TNMapView.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "MapKit/MKMapView.j"
@import "TNDatasourceMigrationVMs.j"


TNArchipelTypeHypervisorControl            = @"archipel:hypervisor:control";

TNArchipelTypeHypervisorControlAlloc       = @"alloc";
TNArchipelTypeHypervisorControlFree        = @"free";
TNArchipelTypeHypervisorControlRosterVM    = @"rostervm";

@implementation TNMapView : TNModule 
{
    @outlet CPView          mapViewContainer            @accessors;
    @outlet CPTextField     textFieldOriginName         @accessors;
    @outlet CPTextField     textFieldDestinationName    @accessors;
    @outlet CPSplitView     splitViewVertical           @accessors;
    @outlet CPSplitView     splitViewHorizontal         @accessors;
    
    @outlet CPScrollView    scrollViewOrigin            @accessors;
    @outlet CPScrollView    scrollViewDestination       @accessors;
    
    CPTableView             tableOriginVMs                  @accessors;
    CPTableView             tableDestinationVMs             @accessors;
    
    TNDatasourceMigrationVMs     vmOrginDatasource          @accessors;
    TNDatasourceMigrationVMs     vmDestinationDatasource    @accessors;
    
    TNStropheContact            originHypervisor            @accessors;
    TNStropheContact            destinationHypervisor       @accessors;
    
    id  _currentItem;
    
    MKMapView   _mapView;
}

- (id)awakeFromCib
{
    _mapView = [[MKMapView alloc] initWithFrame:[[self mapViewContainer] bounds] apiKey:''];

    [_mapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mapView setDelegate:self];
    
    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [mapViewContainer addSubview:_mapView];
    
    [[self splitViewVertical] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self splitViewVertical] setIsPaneSplitter:YES];
    
    
    // VM origin table view
    vmOrginDatasource       = [[TNDatasourceMigrationVMs alloc] init];
    tableOriginVMs          = [[CPTableView alloc] initWithFrame:[[self scrollViewOrigin] bounds]];
    
    [[self scrollViewOrigin] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewOrigin] setAutohidesScrollers:YES];
    [[self scrollViewOrigin] setDocumentView:[self tableOriginVMs]];
    [[self scrollViewOrigin] setBorderedWithHexColor:@"#9e9e9e"];
    
    [[self tableOriginVMs] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableOriginVMs] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableOriginVMs] setAllowsColumnReordering:YES];
    [[self tableOriginVMs] setAllowsColumnResizing:YES];
    [[self tableOriginVMs] setAllowsEmptySelection:YES];
    
    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    //[vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];
    
    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"jid"];
    //[vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];
    
    var vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];
    
    [[self tableOriginVMs] addTableColumn:vmColumStatusIcon];
    [[self tableOriginVMs] addTableColumn:vmColumNickname];
    [[self tableOriginVMs] addTableColumn:vmColumJID];
    
    [[self tableOriginVMs] setDataSource:[self vmOrginDatasource]];
    
    // VM Destination table view
    vmDestinationDatasource     = [[TNDatasourceMigrationVMs alloc] init];
    tableDestinationVMs         = [[CPTableView alloc] initWithFrame:[[self scrollViewDestination] bounds]];
    
    [[self scrollViewDestination] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewDestination] setAutohidesScrollers:YES];
    [[self scrollViewDestination] setDocumentView:[self tableDestinationVMs]];
    [[self scrollViewDestination] setBorderedWithHexColor:@"#9e9e9e"];
    
    [[self tableDestinationVMs] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableDestinationVMs] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableDestinationVMs] setAllowsColumnReordering:YES];
    [[self tableDestinationVMs] setAllowsColumnResizing:YES];
    [[self tableDestinationVMs] setAllowsEmptySelection:YES];
    
    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    //[vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];
    
    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"jid"];
    //[vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];
    
    var vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];
    
    [[self tableDestinationVMs] addTableColumn:vmColumStatusIcon];
    [[self tableDestinationVMs] addTableColumn:vmColumNickname];
    [[self tableDestinationVMs] addTableColumn:vmColumJID];
    
    [[self tableDestinationVMs] setDataSource:[self vmDestinationDatasource]];
}


- (void)willLoad
{
    [super willLoad];
    
    //[_mapView setFrame:bounds];
    //[mapViewContainer setFrame:bounds];
}

- (void)willShow 
{
    [super willShow];
    
    // var bounds = [[self superview] bounds];
    // 
    // [[self splitViewVertical] setFrame:bounds];
}

- (void)willHide 
{
    [super willHide];
}

- (void)mapViewIsReady:(MKMapView)aMapView
{
    var rosterItems = [[self roster] contacts];
    CPLogConsole([self roster]);
    
    var latitude = 48.8542;
    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];
        
        if ([[[item vCard] firstChildWithName:@"TYPE"] text] == @"hypervisor")
        {
            CPLogConsole("found one hypervisor with name " + [item nickname]);
            
            var loc     = [[MKLocation alloc] initWithLatitude:latitude andLongitude:2.3449]; //TODO: GET POSITION OF HYPERVISOR
            var marker  = [[MKMarker alloc] initAtLocation:loc];
            
            latitude++;
            
            [marker setDraggable:NO];
            [marker setClickable:YES];
            [marker setDelegate:self];
            [marker setUserInfo:[CPDictionary dictionaryWithObjectsAndKeys:item, @"rosterItem"]];
            
            [marker addToMapView:_mapView];
        }
    }
}

- (void)markerClicked:(MKMarker)aMarker userInfo:(CPDictionary)someUserInfo
{
    _currentItem = [someUserInfo objectForKey:@"rosterItem"];
    
    [CPAlert alertWithTitle:@"Define path" 
                    message:@"Please choose if this " + [_currentItem nickname] + @" is origin or destination of the migration." 
                      style:CPInformationalAlertStyle 
                   delegate:self 
                    buttons:["Origin", "Destination", "Cancel"]];

}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{   
    if (returnCode == 0)
    {
        [self setOriginHypervisor:_currentItem];
        [[self textFieldOriginName] setStringValue:[_currentItem nickname]];
    }
    else if (returnCode == 1)
    {
        [self setDestinationHypervisor:_currentItem];
        [[self textFieldDestinationName] setStringValue:[_currentItem nickname]];
    }
    else
        return;
        
    [self rosterOfHypervisor:_currentItem];
}

- (void)rosterOfHypervisor:(TNStropheContact)anHypervisor
{
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorControl}];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorControlRosterVM}];
    
    if (anHypervisor == [self originHypervisor])
        [anHypervisor sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveOriginHypervisorRoster:) ofObject:self];
    else
        [anHypervisor sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveDestinationHypervisorRoster:) ofObject:self];
}

- (void)didReceiveOriginHypervisorRoster:(id)aStanza 
{
    var queryItems  = [aStanza childrenWithName:@"item"];
    var center      = [CPNotificationCenter defaultCenter];
    
    [[[self vmOrginDatasource] VMs] removeAllObjects];
    
    for (var i = 0; i < [queryItems count]; i++)
    {
        var jid     = [[queryItems objectAtIndex:i] text];
        var entry   = [[self roster] getContactFromJID:jid];
        
        if (entry) 
        {
           if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
           {
                [[self vmOrginDatasource] addVM:entry];
                //[center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];   
           }
        }
    }
    [[self tableOriginVMs] reloadData];
}

- (void)didReceiveDestinationHypervisorRoster:(id)aStanza 
{
    var queryItems  = [aStanza childrenWithName:@"item"];
    var center      = [CPNotificationCenter defaultCenter];
    
    [[[self vmDestinationDatasource] VMs] removeAllObjects];
    
    for (var i = 0; i < [queryItems count]; i++)
    {
        var jid     = [[queryItems objectAtIndex:i] text];
        var entry   = [[self roster] getContactFromJID:jid];
        
        if (entry) 
        {
           if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
           {
                [[self vmDestinationDatasource] addVM:entry];
                //[center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];   
           }
        }
    }
    [[self tableDestinationVMs] reloadData];
}


@end


