import UIKit

@MainActor public protocol ViewProtocol<Model> {
    associatedtype Model

    var model: Model { get }
    var view: UIView { get }

    init(model: Model)
}
