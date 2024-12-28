import SwiftUI
import CoreMotion
internal import DesignSystem

struct PopupsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    @State private var bottomSheet: AlertBottomSheetPreset?

    var body: some View {
        HStack {
            Spacer()
            VStack {
                ContentView(motion: MotionManager())
                Spacer()
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: .sheetNoConnectionTitle),
                    action: {
                        if bottomSheet != nil {
                            bottomSheet = nil
                        } else {
                            bottomSheet = .noConnection(onRetry: {
                                bottomSheet = nil
                            }, onClose: {
                                bottomSheet = nil
                            })
                        }
                    }
                )
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
        .bottomSheet(preset: $bottomSheet)
    }
}

class MotionManager: ObservableObject {

    private var motionManager: CMMotionManager

    struct Data {
        var x: Double
        var y: Double
        var z: Double

        static var zero: Data {
            Data(x: 0, y: 0, z: 0)
        }
    }

    @Published var current: Data?
    @Published var initial: Data?
    @Published var delta: Data = .zero

    init() {
        self.motionManager = CMMotionManager()
        self.motionManager.magnetometerUpdateInterval = 1/60
        self.motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
            guard let self else {
                return
            }
            guard error == nil else {
                print(error!)
                return
            }
            if let motionData {
                let data = Data(x: abs(motionData.attitude.roll), y: abs(motionData.attitude.pitch), z: abs(motionData.attitude.yaw))
                current = data
                guard let initial else {
                    initial = data
                    return
                }
                delta = Data(x: data.x - initial.x, y: data.y - initial.y, z: data.z - initial.z)
            }
        }
    }
}

private struct ContentView: View {
    @ObservedObject var motion: MotionManager

    private var dx: Double {
        motion.delta.x * multiplicator
    }

    private var dy: Double {
        motion.delta.y * multiplicator
    }

    private var dz: Double {
        motion.delta.z * multiplicator
    }

    private var multiplicator: Double {
        1
    }

    init(motion: MotionManager) {
        self.motion = motion
    }

    var body: some View {
        ZStack {
            Image.noConnection.resizable().scaledToFit()
                .frame(width: 316, height: 417)
                .overlay(
                    Rectangle()
                        .frame(width: 300, height: 50)
                    // Remove .colorInvert() if it displays the 'shine' in dark shade on device
//                        .colorInvert()
                        .blur(radius: 50)
                        .offset(x: -dx / 1.5 * 100, y: -dy / 1.5 * 100)

                )
                .clipped()
            VStack {
                Text("Magnetometer Data")
                    .foregroundStyle(.red)
                Text("X: \(dx)")
                    .foregroundStyle(.red)
                Text("Y: \(dy)")
                    .foregroundStyle(.red)
                Text("Z: \(dz)")
                    .foregroundStyle(.red)
            }
//            Image("charizard").resizable().scaledToFill()
//                .offset(x: 20, y: -70)
//                .frame(width: 160, height: 160)
//                .offset(x: ValueTranslation.width / 30, y: ValueTranslation.height / 30)

        }
        .frame(width: 316, height: 417)
        .background(.black)
        .clipShape(.rect(cornerRadius: 24))
        .rotation3DEffect(
            .degrees(max(dx, dy, dz) * 5),
            axis: (x: -dy, y: -dx, z: -dz)
        )
//        .gesture(DragGesture()
//            .onChanged({ value in
//                withAnimation {
//                    ValueTranslation = value.translation
//                    isDragging = true
//                }
//            })
//                .onEnded({ vaule in
//                    withAnimation {
//                        ValueTranslation = .zero
//                        isDragging = false
//                    }
//                })
//        )
    }
}
