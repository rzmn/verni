import Foundation
import DataTransferObjects

actor SessionHost {
    private enum Constants {
        static let host = "host"
    }

    var active: UserDto.Identifier? {
        UserDefaults.standard.string(forKey: Constants.host)
    }

    func sessionStarted(host: UserDto.Identifier) {
        UserDefaults.standard.set(host, forKey: Constants.host)
    }

    func sessionFinished() {
        UserDefaults.standard.removeObject(forKey: Constants.host)
    }
}
