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

nonisolated fileprivate struct CoordinateSpaceBox: @unchecked Sendable {
    let space: CoordinateSpace
}

extension KeyPath: @unchecked @retroactive Sendable where Root: Sendable, Value: Sendable {}

internal extension View {
    func modify<Content: View>(@ViewBuilder _ content: (Self) -> Content) -> some View {
        content(self)
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func trackFrame<T: Equatable&Sendable>(in space: CoordinateSpace,
                                           of transform: @Sendable @escaping (CGRect) -> T,
                                           action: @escaping (T) -> Void) -> some View {
        let box = CoordinateSpaceBox(space: space)
        return onGeometryChange(for: T.self, of: { proxy in
            transform(proxy.frame(in: box.space))
        }, action: action)
    }

    func trackSize<T: Equatable&Sendable>(_ value: KeyPath<CGSize, T> = \.self,
                                          _ perform: @escaping (T) -> Void) -> some View {
        onGeometryChange(for: T.self, of: { $0.size[keyPath: value] }, action: perform)
    }

}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
