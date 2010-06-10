/*  
 * TNSnapshot.j
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


@implementation TNSnapshot : CPObject 
{
    CPString    name           @accessors;
    CPString    description    @accessors;
    CPString    creationTime   @accessors;
    CPString    _state         @accessors(setter=setState:);
    CPString    parent         @accessors;
    CPString    domain         @accessors;
    CPString    UUID           @accessors;
    BOOL        _isCurrent     @accessors(setter=setCurrent:);
    
    CPImage _currentIcon;
}

- (id)init
{
    if(self = [super init]) 
    {
        var bundle      = [CPBundle mainBundle];
        _currentIcon    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"button-icons/button-icon-arrow-right.png"] size:CPSizeMake(16, 16)];
    }
    
    return self;
}

- (CPImage)isCurrent
{
    if (_isCurrent)
        return _currentIcon;
    return nil;
}

@end