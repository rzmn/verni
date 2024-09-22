import Foundation
import Domain

actor SessionHost {
    private enum Constants {
        static let host = "host"
    }

    var active: User.Identifier? {
        UserDefaults.standard.string(forKey: Constants.host)
    }

    func sessionStarted(host: User.Identifier) {
        UserDefaults.standard.set(host, forKey: Constants.host)
    }

    func sessionFinished() {
        UserDefaults.standard.removeObject(forKey: Constants.host)
    }
}
