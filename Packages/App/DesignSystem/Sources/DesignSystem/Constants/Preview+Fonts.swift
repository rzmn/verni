import Foundation
import SwiftUI

extension Bundle {
    private class ClassForGettingBundle {}
    
    static func forModule(class: AnyClass?) -> Bundle? {
        // The name of your local package bundle. This may change on every different version of Xcode.
        // It used to be "LocalPackages_<ModuleName>" for iOS. To find out what it is, print out  the path for
        // Bundle(for: CurrentBundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
        // and then look for what bundle is named in there.
        let bundleName = "DesignSystem_DesignSystem"
        let urlsForClass: (AnyClass) -> [URL?] = { `class` in
            [
                Bundle(for: `class`).resourceURL,
                // Bundle should be present here when running previews from a different package
                // (this is the path to "…/Debug-iphonesimulator/").
                Bundle(for: `class`)
                    .resourceURL?
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent(),
                Bundle(for: `class`)
                    .resourceURL?
                    .deletingLastPathComponent()
                    .deletingLastPathComponent(),
            ]
        }
        
        let candidates = [
            [
                // Bundle should be present here when the package is linked into an App.
                Bundle.main.resourceURL,
                // Bundle should be present here when the package is linked into a framework.
                Bundle.module.resourceURL,
                Bundle.module.bundleURL,
                // For command-line tools.
                Bundle.main.bundleURL,
            ],
            `class`.flatMap(urlsForClass) ?? [],
            urlsForClass(ClassForGettingBundle.self)
        ].flatMap { $0 }

        for candidate in candidates {
            let bundlePathiOS = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePathiOS.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return nil
    }
}

public enum CustomFonts {
    @discardableResult
    public static func registerCustomFonts(class: AnyClass?) -> String? {
        let errors = [
            "\(Font.mediumTextFontName).ttf",
            "\(Font.regularTextFontName).ttf"
        ].compactMap { font in
            guard let bundle = Bundle.forModule(class: `class`) else {
                return "Cannot find bundle for class \(`class`.debugDescription)"
            }
            guard let url = bundle.url(forResource: font, withExtension: nil) else {
                return "Can't find resource for \(font) in bundle \(bundle). See Bundle+Extensions.swift"
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            return nil
        }
        return errors.isEmpty ? nil : "registerCustomFonts errors:\n \(errors.joined(separator: "\n"))"
    }
}

extension View {
    @ViewBuilder public func loadCustomFonts(class: AnyClass? = nil) -> some View {
        if let text = CustomFonts.registerCustomFonts(class: `class`) {
            self.overlay {
                Text(text)
                    .foregroundStyle(Color.red)
            }
        } else {
            self
        }
    }
}
