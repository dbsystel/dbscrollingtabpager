# DBScrollingTabPager

A SwiftUI component that provides a scrollable pager with sticky tabs, featuring a header that scrolls away and a tab bar that sticks to the top of the screen.

## Overview

`DBScrollingTabPager` creates an interactive tabbed interface where:
- A header sits at the top and scrolls out of view as users scroll down
- A tab bar follows the header and "sticks" to the top of the screen once the header is scrolled away
- Multiple pages can be swiped horizontally between tabs
- The tab bar remains accessible while scrolling through page content

![Demo](https://raw.githubusercontent.com/dbsystel/dbscrollingtabpager/main/demo.gif)

## Requirements

- iOS 18.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dbsystel/dbscrollingtagpager.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Package Dependencies
2. Enter the repository URL
3. Select the version you want to use

## Usage

### Demo

The `TrainFacts` demo shows how to use all of the functionality.

### Basic Example

```swift
import SwiftUI
import DBScrollingTabPager

enum MyTab: DBTab {
    case first
    case second
    case third
    
    var label: String {
        switch self {
        case .first: "First"
        case .second: "Second"
        case .third: "Third"
        }
    }
}

struct MyView: View {
    @State private var selection: MyTab? = nil
    
    var body: some View {
        NavigationStack {
            DBScrollingTabPager(
                tabs: [.first, .second, .third],
                selection: $selection
            ) {
                // Header that scrolls away
                Text("My Header")
                    .font(.largeTitle)
                    .padding()
            } background: {
                // Background color extending into safe area
                Color.blue.gradient
            } tabLabelProvider: { context in
                // Tab label customization
                Text(context.tab.label)
                    .font(context.isSelected ? .headline : .body)
            } pages: {
                // Your page views
                FirstPageView()
                SecondPageView()
                ThirdPageView()
            }
            .scrollingTabPagerStyle(
                .init(standardTabPagerBackgroundColor: .white)
            )
        }
    }
}
```

### Customizing Appearance

Use `DBScrollingTabPagerStyle` to customize the component's appearance:

```swift
.scrollingTabPagerStyle(.init(
    standardTabPagerBackgroundColor: .white,
    stuckTabPagerBackgroundColor: .gray.opacity(0.1),
    contentBackgroundColor: .white,
    dividerColor: .gray,
    topCornerRadius: 12
))
```

**Style Parameters:**
- `standardTabPagerBackgroundColor`: Tab bar background when not stuck
- `stuckTabPagerBackgroundColor`: Tab bar background when stuck to top (optional, defaults to standard)
- `contentBackgroundColor`: Background of the content area (optional, defaults to standard)
- `dividerColor`: Color of the divider line between tab bar and content (optional, defaults to gray)
- `topCornerRadius`: Corner radius for top corners of the content when not pinned (optional, defaults to 0)

### Tracking Header Opacity

You can track the header's opacity as it scrolls, which you can use to fade the navbar title in and out:

```swift
@State private var headerOpacity: CGFloat = 1.0

DBScrollingTabPager(
    tabs: tabs,
    selection: $selection,
    headerOpacity: $headerOpacity
) {
    // Header content
} // ...

// Use headerOpacity to fade in/out other UI elements
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("Title")
            .opacity(1 - headerOpacity)
    }
}
```

## Components

### DBScrollingTabPager

The main container view that orchestrates the scrolling behavior.

**Parameters:**
- `tabs`: Array of tab items conforming to `DBTab`
- `selection`: Binding to the currently selected tab
- `headerOpacity`: Optional binding to track header visibility
- `header`: ViewBuilder for the scrollable header content
- `background`: ViewBuilder for the background
- `tabLabelProvider`: Closure that provides the view for each tab label
- `pages`: ViewBuilder containing the page views (this must match the count of items in the `tabs` array!)

### DBTab Protocol

Your tab enum must conform to the `DBTab` protocol. It will be given to the `tabLabelProvider` later so you can perform
individual styling depending on whether or not the tab is selected. The *label* is used solely for the accessibility
identifier and label, the `tabLabelProvider` is responsible for providing a styled Text.

```swift
public protocol DBTab: Hashable, Identifiable, Sendable {
    var label: String { get }
}
```

### DBTabContext

Provided to the `tabLabelProvider` closure with information about the tab:

```swift
public struct DBTabContext {
    let tab: Tab          // The tab item
    let isSelected: Bool  // Whether this tab is currently selected
}
```

## License

Copyright (C) 2025 DB Fernverkehr AG.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
