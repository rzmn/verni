import UIKit
import SwiftUI
internal import Device

@MainActor public final class DynamicIsland {
    static let shared = DynamicIsland()
    
    lazy var isAvailable = Device.hasDynamicIsland
    lazy var frame = CGRect(x: originX, y: originY, width: width, height: height)
    
    private lazy var width = 124 * zoom
    private lazy var height = 36 * zoom
    
    private lazy var originX = UIScreen.main.bounds.midX - width / 2
    
    private lazy var originY: CGFloat = {
        let multipler: CGFloat
        switch Device.version() {
        case .iPhone16Pro, .iPhone16Pro_Max:
            multipler = 14
        default:
            multipler = 12
        }
        return multipler * zoom
    }()
    
    private lazy var zoom: CGFloat = UIScreen.main.scale / UIScreen.main.nativeScale
}

extension View {
    @ViewBuilder public func dynamicIslandContent(block: () -> some View) -> some View {
        if DynamicIsland.shared.isAvailable {
            ZStack {
                self
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        Color.clear
                            .frame(width: DynamicIsland.shared.frame.width, height: DynamicIsland.shared.frame.height)
                            .clipShape(.rect(cornerRadius: DynamicIsland.shared.frame.height / 2))
                            .padding(.top, DynamicIsland.shared.frame.minY)
                            .overlay {
                                block()
                                    .padding(.horizontal, DynamicIsland.shared.frame.height / 2)
                            }
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
        } else {
            self
        }
    }
}
