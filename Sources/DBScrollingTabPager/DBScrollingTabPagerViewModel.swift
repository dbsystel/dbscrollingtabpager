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

public protocol DBTab: Hashable {
    var label: String { get }
}

public struct DBTabContext {
    public let tab: any DBTab
    public let isSelected: Bool
}

internal class DBScrollingTabPagerViewModel<Tab: DBTab>: ObservableObject {
    let tabs: [Tab]
    
    @Published var headerHeight: CGFloat = 0
    @Published var mainScrollDisabled = false
    @Published var mainScrollPhase: ScrollPhase = .idle
    @Published var mainScrollGeometry = ScrollGeometry(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(.zero),
        containerSize: .zero
    )
    @Published var isHeaderSticking: Bool = false
    @Published var tabBarSize: CGSize = .zero
    @Published var tabFrame: [Tab: CGRect] = [:] {
        didSet {
            tabStartingPoints = tabs.map { tabFrame[$0]?.minX ?? 0 }
            tabWidths = tabs.map { tabFrame[$0]?.width ?? 0 }
        }
    }
    @Published var tabStartingPoints: [CGFloat] = []
    @Published var tabWidths: [CGFloat] = []
    @Published var headerOpacity: CGFloat = 1.0
    @Published var scrollOffsetsY: [CGFloat]
    @Published var scrollPositions: [ScrollPosition]
    
    init(tabs: [Tab]) {
        self.tabs = tabs
        let count = tabs.count
        self._scrollPositions = .init(
            initialValue: .init(repeating: .init(), count: count)
        )
        self._scrollOffsetsY = .init(
            initialValue: .init(repeating: .zero, count: count)
        )
    }
}
