/*
 * TNWindowAddContact.j
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

/*! @ingroup archipelcore
    subclass of CPWindow that allows to add a TNStropheContact
*/
@implementation TNContactsController: CPObject
{
    @outlet CPPopUpButton   newContactGroup;
    @outlet CPTextField     newContactJID;
    @outlet CPTextField     newContactName;

    @outlet CPWindow        mainWindow          @accessors(readonly);
    TNStropheRoster         _roster             @accessors(property=roster);
    TNPubSubController      _pubsubController   @accessors(property=pubSubController);
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_performPushRosterAdded:) name:TNStropheRosterPushAddedContactNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_performPushRosterRemoved:) name:TNStropheRosterPushRemovedContactNotification object:nil];
}

#pragma mark -
#pragma mark Utilities

- (void)subscribeToPubSubNodeOfContactWithJID:(TNStropheJID)aJID
{
    var nodeName = @"/archipel/" + [aJID bare] + @"/events",
        server = [TNStropheJID stropheJIDWithString:@"pubsub." + [aJID domain]];

    if (![_pubsubController nodeWithName:nodeName])
        [_pubsubController subscribeToNodeWithName:nodeName server:server];
}

- (void)unsubscribeToPubSubNodeOfContactWithJID:(TNStropheJID)aJID
{
    var nodeName = "/archipel/" + [aJID bare] + "/events",
        server = [TNStropheJID stropheJIDWithString:@"pubsub." + [aJID domain]];

    if ([_pubsubController nodeWithName:nodeName])
        [_pubsubController unsubscribeFromNodeWithName:nodeName server:server]
}


#pragma mark -
#pragma mark Notification handlers

- (void)_didPubSubSubscriptionsRetrieved:(CPNotification)aNotification
{
    var eventNode = [[[aNotification object] nodes] objectAtIndex:0];

    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubSubscriptionsRetrievedNotification object:[aNotification object]];

    [eventNode unsubscribe];
}

- (void)_performPushRosterAdded:(CPNotification)aNotification
{
    var contact = [aNotification userInfo];

    [self subscribeToPubSubNodeOfContactWithJID:[contact JID]];
}

- (void)_performPushRosterRemoved:(CPNotification)aNotification
{
    var contact = [aNotification userInfo];

    [self unsubscribeToPubSubNodeOfContactWithJID:[contact JID]];
}

#pragma mark -
#pragma mark Actions

/*! overide of the orderFront
    @param aSender the sender
*/
- (IBAction)showWindow:(id)aSender
{
    var groups = [_roster groups];

    [newContactJID setStringValue:@""];
    [newContactName setStringValue:@""];
    [newContactGroup removeAllItems];
    //[self makeFirstResponder:newContactJID];

    if (![_roster containsGroup:@"General"])
    {
        [newContactGroup addItemWithTitle:@"General"];
    }

    //@each (var group in groups)
    for (var i = 0; i < [groups count]; i++)
    {
        var group   = [groups objectAtIndex:i];
        [newContactGroup addItemWithTitle:[group name]];
    }

    [newContactGroup selectItemWithTitle:@"General"];

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! add a contact according to the values of the outlets
    @param aSender the sender
*/
- (IBAction)addContact:(id)aSender
{
    var group   = [newContactGroup title],
        JID     = [TNStropheJID stropheJIDWithString:[newContactJID stringValue]],
        name    = [newContactName stringValue],
        growl   = [TNGrowlCenter defaultCenter],
        msg     = @"Presence subsciption has been sent to " + JID + ".";

    if (name == "")
        name = [JID node];

    [_roster addContact:JID withName:name inGroupWithName:group];
    [_roster askAuthorizationTo:JID];
    [_roster authorizeJID:JID];
    [self subscribeToPubSubNodeOfContactWithJID:JID];

    [mainWindow performClose:nil];

    CPLog.info(@"added contact " + JID);

    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + JID + @" has been added"];
}

/*! will ask for deleting the selected contact
    @param aSender the sender of the action
*/
- (void)deleteContact:(TNStropheContact)aContact
{
    if ([aContact class] != TNStropheContact)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"User supression" message:@"You must choose a contact" icon:TNGrowlIconError];
        return;
    }

    var alert = [TNAlert alertWithMessage:@"Delete contact"
                                informative:@"Are you sure you want to delete this contact?"
                                 target:self
                                 actions:[["Delete", @selector(performDeleteContact:)], ["Cancel", nil]]];

    [alert setHelpTarget:self action:@selector(showHelpForDelete:)];
    [alert setUserInfo:aContact];
    [alert runModal];
}

/*! Action for the deleteContact:'s confirmation TNAlert.
    It will delete the contact
    @param aSender the sender of the action
*/
- (void)performDeleteContact:(id)userInfo
{
    var contact = userInfo;

    [self unsubscribeToPubSubNodeOfContactWithJID:[contact JID]];

    [_roster removeContact:contact];

    CPLog.info(@"contact " + [contact JID] + "removed");
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Contact" message:@"Contact " + [contact JID] + @" has been removed"];
}

/*! action sent by alert to show help for subscription
    @param aSender the sender of the action
*/
- (IBAction)showHelpForSubscription:(id)aSender
{
    window.open("http://www.google.fr/search?q=XMPP subscription request", "_new");
}

/*! action sent by alert to show help for subscription
    @param aSender the sender of the action
*/
- (IBAction)showHelpForDelete:(id)aSender
{
    window.open("http://www.google.fr/search?q=XMPP delete contact", "_new");
}

#pragma mark -
#pragma mark Delegate

/*! Delegate method of main TNStropheRoster.
    will be performed when a subscription request is sent
    @param requestStanza TNStropheStanza cotainining the subscription request
*/
- (void)roster:(TNStropheRoster)aRoster receiveSubscriptionRequest:(id)requestStanza
{
    var nick;

    if ([requestStanza firstChildWithName:@"nick"])
        nick = [[requestStanza firstChildWithName:@"nick"] text];
    else
        nick = [requestStanza from];

    var alert = [TNAlert alertWithMessage:@"Subscription request"
                                informative:nick + @" is asking you subscription. Do you want to authorize it ?"
                                 target:self
                                 actions:[["Accept", @selector(performAuthorize:)],
                                            ["Decline", @selector(performRefuse:)]]];

    [alert setHelpTarget:self action:@selector(showHelpForSubscription:)];
    [alert setUserInfo:requestStanza]
    [alert runModal];
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will accept the subscription and try to register to Archipel pubsub nodes
*/
- (void)performAuthorize:(TNStropheStanza)aRequestStanza
{
    [self subscribeToPubSubNodeOfContactWithJID:[aRequestStanza from]];
    [_roster answerAuthorizationRequest:aRequestStanza answer:YES];
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will refuse the subscription and try to unregister to Archipel pubsub nodes
*/
- (void)performRefuse:(TNStropheStanza)aRequestStanza
{
    [_roster answerAuthorizationRequest:aRequestStanza answer:NO];
}
@end