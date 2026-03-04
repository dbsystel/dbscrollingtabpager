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

internal struct TabPagerTabBar<TabLabel: View, Tab: DBTab>: View {
    internal init(selection: Binding<Tab?>,
                  @ViewBuilder tabLabelProvider: @escaping (DBTabContext) -> TabLabel) {
        self._selection = selection
        self.tabLabelProvider = tabLabelProvider
    }
    
    @EnvironmentObject var viewModel: DBScrollingTabPagerViewModel<Tab>
    @Environment(\.dbScrollingTabPagerStyle) private var tabSelectorStyle
    @ViewBuilder let tabLabelProvider: (DBTabContext) -> TabLabel
    
    @Binding var selection: Tab?
    
    var body: some View {
        ViewThatFits {
            StaticTabPagerTabBar(selection: $selection, tabLabelProvider: tabLabelProvider)
            ScrollingTabPagerTabBar(selection: $selection, tabLabelProvider: tabLabelProvider)
        }
        .background(alignment: .bottom) {
            Divider().overlay(tabSelectorStyle.dividerColor)
        }
        .background(alignment: .bottom) {
            (viewModel.isHeaderSticking ? tabSelectorStyle.stuckTabPagerBackgroundColor : tabSelectorStyle.standardTabPagerBackgroundColor)
                .frame(height: viewModel.tabBarSize.height
                       + (tabSelectorStyle.topCornerRadius != 0 ? 8 : 0)
                       * min(viewModel.headerOpacity * 3, 1.0))
                .cornerRadius(
                    viewModel.isHeaderSticking ? 0 :
                        tabSelectorStyle.topCornerRadius
                    * min(viewModel.headerOpacity * 3, 1.0),
                    corners: [.topLeft, .topRight]
                )
        }
        .modify { view in
            if #unavailable(iOS 26) {
                // The divider is only shown on iOS <= 18
                view.overlay(alignment: .top) {
                    Divider().overlay(tabSelectorStyle.dividerColor)
                }
            } else { view }
        }
    }
}

internal struct ScrollingTabPagerTabBar<TabLabel: View, Tab: DBTab>: View {
    internal init(selection: Binding<Tab?>,
                  @ViewBuilder tabLabelProvider: @escaping (DBTabContext) -> TabLabel) {
        self._selection = selection
        self.tabLabelProvider = tabLabelProvider
    }
    
    @EnvironmentObject var viewModel: DBScrollingTabPagerViewModel<Tab>
    @Binding var selection: Tab?
    @ViewBuilder let tabLabelProvider: (DBTabContext) -> TabLabel
    
    var body: some View {
        ScrollViewReader { proxy in
            FadingEdgesHorizontalScrollView {
                StaticTabPagerTabBar(selection: $selection, tabLabelProvider: tabLabelProvider)
            }
            .onChange(of: selection) { _, selection in
                withAnimation {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }.onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
        }
    }
}

internal struct StaticTabPagerTabBar<TabLabel: View, Tab: DBTab>: View {
    internal init(selection: Binding<Tab?>,
                  @ViewBuilder tabLabelProvider: @escaping (DBTabContext) -> TabLabel) {
        self._selection = selection
        self.tabLabelProvider = tabLabelProvider
    }
    
    @EnvironmentObject var viewModel: DBScrollingTabPagerViewModel<Tab>
    @Binding var selection: Tab?
    @ViewBuilder let tabLabelProvider: (DBTabContext) -> TabLabel
    
    @Environment(\.dbScrollingTabPagerStyle) private var tabSelectorStyle

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 16)
            ForEach(viewModel.tabs, id: \.self) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = tab
                    }
                } label: {
                    ZStack {
                        tabLabelProvider(.init(tab: tab, isSelected: isSelected))
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .trackFrame(in: .named("tabSelector"), of: \.self) {
                        viewModel.tabFrame[tab] = $0
                    }
                }
                .transaction { $0.animation = nil }
                .id(tab)
                .accessibilityLabel(tab.label)
                .accessibilityHint(
                    isSelected
                    ? "Ausgewählt" : "Auswählen um Inhalte anzuzeigen"
                )
                if tab != viewModel.tabs.last {
                    Spacer(minLength: 8)
                }
            }.multilineTextAlignment(.center)
            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity)
        .trackSize(\.self) { viewModel.tabBarSize = $0 }
        .coordinateSpace(name: "tabSelector")
        // tab selection inidicator
        .overlay(alignment: .bottomLeading) {
            let (offset, width) = tabSelectorCalculation()
            
            Capsule()
                .fill(.foreground)
                .frame(width: width, height: 4)
                .offset(x: offset)
        }
    }

    func tabSelectorCalculation() -> (CGFloat, CGFloat) {
        let initialProgress: CGFloat =
            viewModel.mainScrollGeometry.contentOffset.x
            / viewModel.mainScrollGeometry.bounds.width
        let progress = max(
            0,
            min(initialProgress, CGFloat(viewModel.tabs.count - 1))
        )

        let start = Int(progress.rounded(.down))
        let end = start + 1

        let startPoint = viewModel.tabStartingPoints[safe: start] ?? 0.0
        let endPoint = viewModel.tabStartingPoints[safe: end] ?? 0.0
        let offset =
            startPoint + (endPoint - startPoint) * (progress - CGFloat(start))

        let startWidth: CGFloat = viewModel.tabWidths[safe: start] ?? 0.0
        let endWidth: CGFloat = viewModel.tabWidths[safe: end] ?? 0.0
        let width =
            startWidth + (endWidth - startWidth) * (progress - CGFloat(start))

        return (offset, width)
    }
}

fileprivate extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
