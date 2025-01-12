import Foundation

actor SessionHost {
    private enum Constants {
        static let host = "host"
    }

    var active: String? {
        UserDefaults.standard.string(forKey: Constants.host)
    }

    func sessionStarted(host: String) {
        UserDefaults.standard.set(host, forKey: Constants.host)
    }

    func sessionFinished() {
        UserDefaults.standard.removeObject(forKey: Constants.host)
    }
}
