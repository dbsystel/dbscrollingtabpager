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
@_spi(Advanced) import SwiftUIIntrospect

/// The DBScrollingTabPager provides a scrollable pager with sticky tabs, consisting of a header on top, a tab-bar (optionally with rounded corners) and content. When the content is scrolled, the tab-bar scrolls with it and obscures the
/// header under it reaches the top of the page, at which point the tab-bar sticks to the top beneath an optional navigation bar.
public struct DBScrollingTabPager<TabLabel: View, Header: View, Background: View, Pages: View, Tab: DBTab>: View {
    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let background: () -> Background
    @ViewBuilder private let tabLabelProvider: (DBTabContext) -> TabLabel
    private let pages: Pages
    
    @Environment(\.dbScrollingTabPagerStyle) private var tabPagerStyle
    
    @StateObject private var viewModel: DBScrollingTabPagerViewModel<Tab>
    @Binding private var selection: Tab?
    private var headerOpacity: Binding<CGFloat>?
    /// Creates a scrolling tab pager with customizable tabs, header, and pages.
    ///
    /// The scrolling tab pager displays a header at the top, followed by a tab bar that becomes sticky when scrolled,
    /// and content pages that correspond to each tab. Users can switch between tabs by tapping the tab bar or
    /// swiping horizontally through the pages.
    ///
    /// - Parameters:
    ///   - tabs: An array of tabs conforming to ``DBTab`` that define the available pages in the pager.
    ///   - selection: A binding to the currently selected tab. If `nil` on appearance, the first tab will be selected automatically.
    ///   - headerOpacity: An optional binding that receives the current opacity value of the header as it scrolls and becomes hidden (0.0 when fully hidden, 1.0 when fully visible).
    ///   - header: A view builder that creates the header content displayed above the tab bar.
    ///   - background: A view builder that creates the background view for the entire pager. Defaults to `Color.clear`.
    ///   - tabLabelProvider: A view builder that creates the label for each tab, receiving a ``DBTabContext`` to customize the appearance based on the tab's state.
    ///   - pages: A view builder that creates the content views for each page. The number of views must match the number of tabs.
    public init(tabs: [Tab],
                selection: Binding<Tab?>,
                headerOpacity: Binding<CGFloat>? = nil,
                @ViewBuilder header: @escaping () -> Header,
                @ViewBuilder background: @escaping () -> Background = { Color.clear },
                @ViewBuilder tabLabelProvider: @escaping (DBTabContext) -> TabLabel,
                @ViewBuilder pages: @escaping () -> Pages
    ) {
        
        self.tabLabelProvider = tabLabelProvider
        self.header = header
        self.pages = pages()
        self.background = background
        self._selection = selection
        self.headerOpacity = headerOpacity
        self._viewModel = StateObject(
            wrappedValue: DBScrollingTabPagerViewModel(tabs: tabs)
        )
    }

    // At the base is a horizontal scrollview which contains the vertical scrollviews containing the individual pages.
    // The active page shows the header and the tabbar, which both pin themselves to the x position with a high z-index.
    // The inactive pages just have empty rectangles and low z-index. That causes horizontal swipes to page correctly
    // while vertical swipes only operate on the active page.
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                background().edgesIgnoringSafeArea(.top)
                
                ScrollViewReader { rootScrollViewReader in
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            Group(subviews: pages) { collection in
                                if collection.count != viewModel.tabs.count {
                                    VStack(alignment: .center) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 64))
                                        Text("Tab count does not match view count")
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }.padding()
                                } else {
                                    ForEach(Array(viewModel.tabs.enumerated()), id: \.offset) { index, tab in
                                        TabPage(index: index,
                                                tab: tab,
                                                rootProxy: proxy,
                                                subview: collection[index],
                                                header: header,
                                                tabLabelProvider: tabLabelProvider,
                                                selection: $selection)
                                        .id(tab)
                                        .accessibilityIdentifier(tab.label)
                                        .accessibilityHidden(selection != tab)
                                        .environmentObject(viewModel)
                                    }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $selection)
                    .scrollIndicators(.hidden)
                    .scrollDisabled(viewModel.mainScrollDisabled)
                    .scrollClipDisabled()
                    .allowsHitTesting(viewModel.mainScrollPhase == .idle)
                    .onScrollPhaseChange { _, newPhase in
                        viewModel.mainScrollPhase = newPhase
                    }
                    .introspect(.scrollView, on: .iOS(.v16...)) {
                        $0.bouncesHorizontally = false
                    }.onChange(of: viewModel.headerOpacity) { _, newValue in
                        self.headerOpacity?.wrappedValue = newValue
                    }
                    .onScrollGeometryChange(
                        for: ScrollGeometry.self,
                        of: { $0 },
                        action: { _, newValue in
                            viewModel.mainScrollGeometry = newValue
                        }
                    )
                    .mask {
                        // This mask is used to lock the scrolling below the tab bar when the bar is pinned,
                        // otherwise the entire view can transparently scroll through the safe area. Elsewhere,
                        // the opacity is shifted during scrolling.
                        Rectangle()
                            .ignoresSafeArea(.all, edges: viewModel.isHeaderSticking ? .bottom : [])
                            .frame(height: viewModel.isHeaderSticking ? nil :
                                    proxy.size.height
                                   + proxy.safeAreaInsets.top
                                   + proxy.safeAreaInsets.bottom
                            )
                    }
                    .sensoryFeedback(.selection, trigger: selection)
                    .onAppear {
                        if selection == nil {
                            selection = viewModel.tabs.first
                        }
                        
                        if selection != viewModel.tabs.first {
                            rootScrollViewReader.scrollTo(selection)
                        }
                    }
                }
            }
        }
        .coordinateSpace(name: "container")
    }
}
