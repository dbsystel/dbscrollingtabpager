//  Copyright (C) 2025 DB Fernverkehr AG.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


import SwiftUI

/// Style configuration for the scrolling tab pager component.
public struct DBScrollingTabPagerStyle {
    // Background color when tab pager is in standard position
    let standardTabPagerBackgroundColor: Color
    // Background color when tab pager is stuck to top during scroll
    let stuckTabPagerBackgroundColor: Color
    // Background color of the content area
    let contentBackgroundColor: Color
    // Color of divider line between the tab bar and the content when sticky
    let dividerColor: Color
    // Corner radius for top corners
    let topCornerRadius: CGFloat

    /// Creates a new tab pager style.
    /// - Parameters:
    ///   - standardTabPagerBackgroundColor: Tab bar background color in standard position
    ///   - stuckTabPagerBackgroundColor: Tab bar background color when stuck (defaults to standard)
    ///   - contentBackgroundColor: Content area background (defaults to standard)
    ///   - dividerColor: Divider color (defaults to gray)
    ///   - topCornerRadius: Top corner radius (defaults to 0)
    public init(standardTabPagerBackgroundColor: Color,
                stuckTabPagerBackgroundColor: Color? = nil,
                contentBackgroundColor: Color? = nil,
                dividerColor: Color? = nil,
                topCornerRadius: CGFloat? = nil) {

        self.standardTabPagerBackgroundColor = standardTabPagerBackgroundColor
        self.stuckTabPagerBackgroundColor = stuckTabPagerBackgroundColor ?? standardTabPagerBackgroundColor
        self.contentBackgroundColor = contentBackgroundColor ?? standardTabPagerBackgroundColor
        self.dividerColor = dividerColor ?? Color.gray
        self.topCornerRadius = topCornerRadius ?? 0
    }
}

public extension EnvironmentValues {
    @Entry var dbScrollingTabPagerStyle: DBScrollingTabPagerStyle = .init(standardTabPagerBackgroundColor: .primary)
}

public extension View {
    func scrollingTabPagerStyle(_ style: DBScrollingTabPagerStyle) -> some View {
        environment(\.dbScrollingTabPagerStyle, style)
    }
}
