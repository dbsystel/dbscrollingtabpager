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
import Observation

@MainActor
public protocol DBTab: Hashable {
    var label: String { get }
}

public struct DBTabContext {
    public let tab: any DBTab
    public let isSelected: Bool
}

@available(iOS 18.0, *)
@MainActor
@Observable
internal final class DBScrollingTabPagerViewModel<Tab: DBTab> {
    let tabs: [Tab]
    
    var headerHeight: CGFloat = 0
    var mainScrollDisabled = false
    var mainScrollPhase: ScrollPhase = .idle
    var mainScrollGeometry = ScrollGeometry(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(.zero),
        containerSize: .zero
    )
    var isHeaderSticking: Bool = false
    var tabBarSize: CGSize = .zero
    var tabFrame: [Tab: CGRect] = [:] {
        didSet {
            tabStartingPoints = tabs.map { tabFrame[$0]?.minX ?? 0 }
            tabWidths = tabs.map { tabFrame[$0]?.width ?? 0 }
        }
    }
    var tabStartingPoints: [CGFloat] = []
    var tabWidths: [CGFloat] = []
    var headerOpacity: CGFloat = 1.0
    var scrollOffsetsY: [CGFloat]
    var scrollPositions: [ScrollPosition]
    @ObservationIgnored private var requestedScrollOffsetsY: [CGFloat?]
    
    init(tabs: [Tab]) {
        self.tabs = tabs
        let count = tabs.count
        self.scrollPositions = .init(repeating: .init(), count: count)
        self.scrollOffsetsY = .init(repeating: .zero, count: count)
        self.requestedScrollOffsetsY = .init(repeating: nil, count: count)
    }

    /// Only a width change requires realigning the horizontally paged content.
    /// A minimizing navigation bar continuously changes its height while scrolling.
    func updateMainScrollGeometry(_ geometry: ScrollGeometry) -> Bool {
        let widthChanged = mainScrollGeometry.containerSize.width != geometry.containerSize.width
            || mainScrollGeometry.contentSize.width != geometry.contentSize.width
        mainScrollGeometry = geometry
        return widthChanged
    }

    func updateScrollOffset(_ offset: CGFloat, at index: Int, selection: Tab?) {
        if scrollPositions[index].isPositionedByUser {
            requestedScrollOffsetsY[index] = nil
        }
        scrollOffsetsY[index] = offset
        guard tabs[index] == selection else { return }

        if offset < 0 {
            for otherIndex in tabs.indices where otherIndex != index {
                if scrollPositions[otherIndex].isPositionedByUser {
                    scroll(to: 0, at: otherIndex)
                }
            }
        }
        updateHeader(for: selection)
    }

    func updateHeader(for selection: Tab?) {
        guard let index = tabs.firstIndex(where: { $0 == selection }), headerHeight > 0 else { return }

        // Offscreen pages can receive geometry updates as the safe area changes,
        // but must not overwrite the visible page's shared header and sticky state.
        let offset = scrollOffsetsY[index]
        let isSticking = offset >= headerHeight
        let halfHeight = headerHeight / 2
        let opacity = max(0, min(1 - ((offset - halfHeight) / halfHeight), 1))
        if isHeaderSticking != isSticking {
            isHeaderSticking = isSticking
        }
        if headerOpacity != opacity {
            headerOpacity = opacity
        }
    }

    func synchronizeScrollPositions(with selection: Tab?) {
        guard let selectedIndex = tabs.firstIndex(where: { $0 == selection }), headerHeight > 0 else { return }
        let target = max(0, min(scrollOffsetsY[selectedIndex], headerHeight))

        // Never scroll the active page in response to a layout change. Doing so
        // interrupts the gesture and feeds back into navigation-bar minimization.
        for index in tabs.indices where index != selectedIndex {
            if scrollOffsetsY[index] < headerHeight || target < headerHeight {
                scroll(to: target, at: index)
            }
        }
    }

    private func scroll(to offset: CGFloat, at index: Int) {
        guard scrollOffsetsY[index] != offset else { return }
        // ScrollPosition doesn't expose a y-only target on iOS 18, and issuing
        // scrollTo again creates another request even for the same coordinate.
        guard requestedScrollOffsetsY[index] != offset else { return }
        var position = scrollPositions[index]
        position.scrollTo(y: offset)
        requestedScrollOffsetsY[index] = offset
        scrollPositions[index] = position
    }
}
