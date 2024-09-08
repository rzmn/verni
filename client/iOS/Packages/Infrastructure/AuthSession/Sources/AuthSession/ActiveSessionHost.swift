import Foundation
import Domain

actor SessionHost {
    private enum Constants {
        static let host = "host"
    }

    var active: User.ID? {
        UserDefaults.standard.string(forKey: Constants.host)
    }

    func sessionStarted(host: User.ID) {
        UserDefaults.standard.set(host, forKey: Constants.host)
    }

    func sessionFinished() {
        UserDefaults.standard.removeObject(forKey: Constants.host)
    }
}
