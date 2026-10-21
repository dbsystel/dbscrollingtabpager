import SwiftUI
import Testing
@testable import DBScrollingTabPager

private var supportsScrollingTabPager: Bool {
    if #available(iOS 18.0, *) { true } else { false }
}

@Suite(.enabled(if: supportsScrollingTabPager))
@MainActor
struct DBScrollingTabPagerViewModelTests {
    private enum Tab: String, DBTab {
        case first, second, third

        var label: String { rawValue }
    }

    @Test func finishingScrollOnlySynchronizesOtherPages() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [40, 0, 250])
        let previousPositions = model.scrollPositions

        model.synchronizeScrollPositions(with: .first)

        #expect(model.scrollPositions[0] == previousPositions[0])
        #expect(model.scrollPositions[1] != previousPositions[1])
        #expect(model.scrollPositions[2] != previousPositions[2])
        if #available(iOS 26.0, *) {
            #expect(model.scrollPositions[1].y == 40)
            #expect(model.scrollPositions[2].y == 40)
        }
    }

    @Test func collapsedHeaderPreservesDeepOffsetsOnOtherPages() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [200, 0, 300])
        let previousPositions = model.scrollPositions

        model.synchronizeScrollPositions(with: .first)

        #expect(model.scrollPositions[0] == previousPositions[0])
        #expect(model.scrollPositions[1] != previousPositions[1])
        #expect(model.scrollPositions[2] == previousPositions[2])
        if #available(iOS 26.0, *) {
            #expect(model.scrollPositions[1].y == 100)
        }
    }

    @Test func layoutChangeRealignsActivePageWithoutResettingDeepOffset() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [200, 0, 300])
        let previousPositions = model.scrollPositions

        model.realignScrollPositions(with: .first)

        #expect(model.scrollPositions[0] != previousPositions[0])
        #expect(model.scrollPositions[1] != previousPositions[1])
        #expect(model.scrollPositions[2] == previousPositions[2])
        if #available(iOS 26.0, *) {
            #expect(model.scrollPositions[0].y == 200)
            #expect(model.scrollPositions[1].y == 100)
        }
    }

    @Test func layoutChangeClampsOverscrollToTop() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [-20, 100, 300])
        let previousPositions = model.scrollPositions

        model.realignScrollPositions(with: .first)

        for index in model.tabs.indices {
            #expect(model.scrollPositions[index] != previousPositions[index])
        }
        if #available(iOS 26.0, *) {
            #expect(model.scrollPositions.allSatisfy { $0.y == 0 })
        }
    }

    @Test func layoutChangeRetriesPreviouslyRequestedOffsets() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [40, 0, 0])
        model.synchronizeScrollPositions(with: .first)
        let previousRequest = model.scrollPositions[1]
        model.updateScrollOffset(10, at: 1, selection: .first)

        model.synchronizeScrollPositions(with: .first)
        #expect(model.scrollPositions[1] == previousRequest)

        model.realignScrollPositions(with: .first)
        #expect(model.scrollPositions[1] != previousRequest)
        if #available(iOS 26.0, *) {
            #expect(model.scrollPositions[1].y == 40)
        }
    }

    @Test func layoutChangeWithoutSelectionDoesNotScroll() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [40, 0, 0])
        let previousPositions = model.scrollPositions

        model.realignScrollPositions(with: nil)

        #expect(model.scrollPositions == previousPositions)
    }

    @Test func horizontalPagingDoesNotRealignForHeightChanges() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [0, 0, 0])
        let initial = geometry(container: CGSize(width: 320, height: 600),
                               content: CGSize(width: 960, height: 600))
        let taller = geometry(container: CGSize(width: 320, height: 800),
                              content: CGSize(width: 960, height: 800))
        let wider = geometry(container: CGSize(width: 400, height: 800),
                             content: CGSize(width: 1200, height: 800))

        #expect(model.updateMainScrollGeometry(initial))
        #expect(!model.updateMainScrollGeometry(taller))
        #expect(model.mainScrollGeometry == taller)
        #expect(model.updateMainScrollGeometry(wider))
    }

    @Test func visiblePageOffsetUpdatesSharedHeader() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [0, 0, 0])

        model.updateScrollOffset(75, at: 0, selection: .first)
        #expect(model.headerOpacity == 0.5)
        #expect(!model.isHeaderSticking)

        model.updateScrollOffset(100, at: 0, selection: .first)
        #expect(model.headerOpacity == 0)
        #expect(model.isHeaderSticking)
    }

    @Test func offscreenPageOffsetDoesNotOverwriteSharedHeader() {
        guard #available(iOS 18.0, *) else { return }
        let model = makeModel(offsets: [0, 0, 0])
        model.updateScrollOffset(75, at: 0, selection: .first)

        model.updateScrollOffset(200, at: 1, selection: .first)

        #expect(model.scrollOffsetsY[1] == 200)
        #expect(model.headerOpacity == 0.5)
        #expect(!model.isHeaderSticking)
    }

    @available(iOS 18.0, *)
    private func makeModel(offsets: [CGFloat]) -> DBScrollingTabPagerViewModel<Tab> {
        let model = DBScrollingTabPagerViewModel(tabs: [Tab.first, .second, .third])
        model.headerHeight = 100
        model.scrollOffsetsY = offsets
        return model
    }

    @available(iOS 18.0, *)
    private func geometry(container: CGSize, content: CGSize) -> ScrollGeometry {
        ScrollGeometry(contentOffset: .zero, contentSize: content,
                       contentInsets: .init(.zero), containerSize: container)
    }
}
