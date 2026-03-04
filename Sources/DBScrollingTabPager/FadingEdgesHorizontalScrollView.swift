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

public struct FadingEdgesHorizontalScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    
    private let fadeColor = Color.black.opacity(0)
    @State private var leadingColor: Color = Color.black
    @State private var trailingColor: Color = Color.black
    
    @State private var scrollViewWidth: CGFloat = 0
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                content.trackFrame(in: .named("fadingEdgeScrollView"), of: \.self) { frame in
                    let origin = -1 * frame.origin.x
                    let delta = frame.width - scrollViewWidth - origin
                
                    if frame.origin.x < 0 {
                        leadingColor = fadeColor
                    } else if frame.origin.x >= 0 {
                        leadingColor = Color.black
                    }
                    
                    if delta > 0 {
                        trailingColor = fadeColor
                    } else {
                        trailingColor = Color.black
                    }
                }
            }.coordinateSpace(name: "fadingEdgeScrollView")
            .mask(
                HStack(spacing: 0) {
                    SideGradient(leadingColor: leadingColor, trailingColor: Color.black)
                    Rectangle().fill(Color.black)
                    SideGradient(leadingColor: Color.black, trailingColor: trailingColor)
                }
            )
            .accessibilityIdentifier("FadingEdgesHorizontalScrollView")
            .trackSize(\.width) { scrollViewWidth = $0 }
    }
}

fileprivate struct SideGradient: View {
    let leadingColor: Color
    let trailingColor: Color
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [leadingColor,
                                                   trailingColor]),
                       startPoint: .leading,
                       endPoint: .trailing)
        .frame(width: 20)
    }
}

#Preview {
    VStack(spacing: 4) {
        FadingEdgesHorizontalScrollView {
            Text("Single Item")
        }
        Divider()
        FadingEdgesHorizontalScrollView {
            HStack(alignment: .center, spacing: 8) {
                ForEach(1...10, id: \.self) { i in
                    Text("Pos \(i)").font(.caption)
                }
            }
        }
        Spacer()
    }.padding(16)
}
