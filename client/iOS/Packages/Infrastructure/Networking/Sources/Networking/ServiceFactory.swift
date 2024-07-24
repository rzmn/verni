import Foundation

public protocol NetworkServiceFactory {
    func create() -> NetworkService
}
