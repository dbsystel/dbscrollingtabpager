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

@available(iOS 18.0, *)
internal struct TabPage<Header: View, TabLabel: View, Tab: DBTab>: View {
    let index: Int
    let tab: Tab
    let rootProxy: GeometryProxy
    let subview: Subview
    
    @Binding var selection: Tab?
    @State private var containerHeight: CGFloat = 0
    
    @Environment(\.dbScrollingTabPagerStyle) private var tabSelectorStyle
    @Environment(\.accessibilityVoiceOverEnabled) var isVoiceOverRunning
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(DBScrollingTabPagerViewModel<Tab>.self) private var viewModel

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
        @Bindable var viewModel = viewModel

        ScrollView(.vertical) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // MARK: Shared Header
                ZStack {
                    if selection == tab {
                        header()
                            .padding(.leading, rootProxy.safeAreaInsets.leading)
                            .padding(.trailing, rootProxy.safeAreaInsets.trailing)
                            .padding(.bottom, tabSelectorStyle.topCornerRadius != 0 ? 8 : 0)
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
                            minHeight: max(0, (containerHeight > 0 ? containerHeight : rootProxy.size.height)
                                           - viewModel.tabBarSize.height - rootProxy.safeAreaInsets.bottom),
                            alignment: .top
                        )
                        .frame(maxWidth: .infinity)
                        .safeAreaPadding(.bottom, rootProxy.safeAreaInsets.bottom)
                        .safeAreaPadding(.leading, rootProxy.safeAreaInsets.leading)
                        .safeAreaPadding(.trailing, rootProxy.safeAreaInsets.trailing)
                        .background(tabSelectorStyle.contentBackgroundColor)
                        .background {
                            // extra background to ensure it covers the over-scrolling area
                            tabSelectorStyle.contentBackgroundColor
                                .offset(y: rootProxy.size.height - viewModel.tabBarSize.height)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("TAB: \(tab.label)")
                } header: {
                    // MARK: Tab Selection
                    ZStack {
                        // Only show the tab for the currently active page. Otherwise just show a blank placeholder (which the user
                        // will not see, as the tabbar remains over it).
                        if selection == tab {
                            TabPagerTabBar(selection: $selection,
                                           rootProxy: rootProxy,
                                           tabLabelProvider: tabLabelProvider)
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
        .onScrollGeometryChange(for: CGFloat.self, of: \.containerSize.height) { _, height in
            // The scroll view extends below the root's safe area. Short pages
            // must fill its actual viewport so the entire header can scroll away.
            containerHeight = height
        }
        .onScrollGeometryChange(
            for: CGFloat.self,
            of: { $0.contentOffset.y + $0.contentInsets.top },
            action: { _, newValue in
                viewModel.updateScrollOffset(newValue, at: index, selection: selection)
            }
        )
        .scrollPosition($viewModel.scrollPositions[index])
        .onScrollPhaseChange { _, newPhase in
            guard selection == tab, newPhase == .idle else { return }
            viewModel.synchronizeScrollPositions(with: selection)

            if viewModel.mainScrollDisabled {
                viewModel.mainScrollDisabled = false
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { _ in
            guard selection == tab else { return }
            // Real width changes need alignment; height/content-size changes
            // during toolbar minimization must not start another scroll request.
            viewModel.synchronizeScrollPositions(with: selection)
        }
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
}

@available(iOS 18.0, *)
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
