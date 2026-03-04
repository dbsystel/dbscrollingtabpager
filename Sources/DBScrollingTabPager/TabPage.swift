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

internal struct TabPage<Header: View, TabLabel: View, Tab: DBTab>: View {
    let index: Int
    let tab: Tab
    let rootProxy: GeometryProxy
    let subview: Subview
    
    @Binding var selection: Tab?
    
    @Environment(\.dbScrollingTabPagerStyle) private var tabSelectorStyle
    @Environment(\.accessibilityVoiceOverEnabled) var isVoiceOverRunning
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @EnvironmentObject var viewModel: DBScrollingTabPagerViewModel<Tab>

    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let tabLabelProvider: (DBTabContext) -> TabLabel

    init(index: Int,
         tab: Tab,
         rootProxy: GeometryProxy,
         subview: Subview,
         header: @escaping () -> Header,
         @ViewBuilder tabLabelProvider: @escaping (DBTabContext) -> TabLabel,
         selection: Binding<Tab?>) {
        self.index = index
        self.tab = tab
        self.rootProxy = rootProxy
        self.subview = subview
        self.header = header
        self.tabLabelProvider = tabLabelProvider
        self._selection = selection
    }

    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // MARK: Shared Header
                ZStack {
                    if selection == tab {
                        header()
                            .padding(.bottom, tabSelectorStyle.topCornerRadius)
                            .opacity(viewModel.headerOpacity)
                            .visualEffect { content, proxy in
                                // Pin the header and prevent it from swiping
                                content.offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX)
                            }
                            .onGeometryChange(for: CGFloat.self) {
                                $0.size.height
                            } action: { newValue in
                                viewModel.headerHeight = newValue
                            }
                            .transition(.identity)
                            .modify { view in
                                // parallax header scrolling
                                if !isVoiceOverRunning && !dynamicTypeSize.isAccessibilitySize {
                                    view.visualEffect { view, proxy in
                                        let offset = max(-proxy.frame(in: .scrollView).minY/2, 0)
                                        return view.offset(y: offset)
                                    }
                                } else { view }
                            }
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: viewModel.headerHeight)
                            .transition(.identity)
                    }
                }.gesture(horizontalScrollDisableGesture)

                Section {
                    // MARK: Tab Content
                    subview
                        // If the content frame is too small, it causes severe problems with the header
                        .frame(
                            minHeight: rootProxy.size.height - viewModel.tabBarSize.height,
                            alignment: .top
                        )
                        .frame(width: rootProxy.size.width)
                        .padding(.bottom, rootProxy.safeAreaInsets.bottom)
                        .background(tabSelectorStyle.contentBackgroundColor)
                        .background {
                            // extra background to ensure it covers the over-scrolling area 
                            tabSelectorStyle.contentBackgroundColor
                                .offset(y: rootProxy.size.height - 32)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("TAB: \(tab.label)")
                } header: {
                    // MARK: Tab Selection
                    ZStack {
                        // Only show the tab for the currently active page. Otherwise just show a blank placeholder (which the user
                        // will not see, as the tabbar remains over it).
                        if selection == tab {
                            TabPagerTabBar(selection: $selection, tabLabelProvider: tabLabelProvider)
                                .visualEffect { content, proxy in
                                    // Note: This does the "magic" of keeping the tab bar stuck where it is
                                    content.offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX)
                                }
                                .transition(.identity)
                        } else {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(height: viewModel.tabBarSize.height)
                                .transition(.identity)
                        }
                    }
                    .contentShape(.rect)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("TAB-Auswahl")
                    .gesture(horizontalScrollDisableGesture)
                }
            }
        }
        .coordinateSpace(name: "scrollView")
        .onScrollGeometryChange(
            for: CGFloat.self,
            of: { $0.contentOffset.y + $0.contentInsets.top },
            action: { _, newValue in
                viewModel.scrollOffsetsY[index] = newValue
                if newValue < 0 {
                    resetScrollViews(tab)
                }
                
                if viewModel.headerHeight > 0 {
                    // Wait until the headerHeight is known before assuming we're sticking
                    viewModel.isHeaderSticking = newValue >= viewModel.headerHeight
                    let halfHeight = viewModel.headerHeight / 2
                    viewModel.headerOpacity = max(
                        0.0,
                        min(1.0 - ((newValue - halfHeight) / halfHeight), 1.0)
                    )
                }
            }
        )
        .scrollPosition($viewModel.scrollPositions[index])
        .onScrollPhaseChange { _, newPhase in
            let offsetY = viewModel.scrollOffsetsY[index]
            let maxOffset = min(offsetY, viewModel.headerHeight)
            
            if newPhase == .idle && maxOffset <= viewModel.headerHeight {
                updateOtherScrollViews(tab, to: maxOffset)
            }
            
            if newPhase == .idle && viewModel.mainScrollDisabled {
                viewModel.mainScrollDisabled = false
            }
        }
        .frame(width: rootProxy.size.width)
        .scrollClipDisabled()
        .zIndex(selection == tab ? 1000 : 0)
    }
    
    // We need to disable horizontal swiping on the header while still allowing
    // vertical scrolling. That requires a custom gesture.
    var horizontalScrollDisableGesture: some UIGestureRecognizerRepresentable {
        CustomPanGesture { gesture in
            let state = gesture.state
            switch state {
            case .began, .changed:
                viewModel.mainScrollDisabled = true
            case .ended, .cancelled, .failed:
                viewModel.mainScrollDisabled = false
            default: ()
            }
        }
    }

    func resetScrollViews(_ from: Tab) {
        for index in viewModel.tabs.indices {
            let label = viewModel.tabs[index]

            if label != from {
                viewModel.scrollPositions[index].scrollTo(y: 0)
            }
        }
    }

    func updateOtherScrollViews(_ from: Tab, to: CGFloat) {
        for index in viewModel.tabs.indices {
            let label = viewModel.tabs[index]
            let offset = viewModel.scrollOffsetsY[index]

            let wantsUpdate = offset < viewModel.headerHeight || to < viewModel.headerHeight

            if wantsUpdate && label != from {
                viewModel.scrollPositions[index].scrollTo(y: to)
            }
        }
    }
}

private struct CustomPanGesture: UIGestureRecognizerRepresentable {
    var handler: (UIPanGestureRecognizer) -> Void
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {

    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        handler(recognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
                UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
