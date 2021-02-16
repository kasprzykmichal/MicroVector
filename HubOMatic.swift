//
//  HubOMatic.swift
//  MicroVector
//
//  Created by Marc Prud'hommeaux on 2/12/21.
//

import Foundation
import MiscKit
import Combine
import SwiftUI
import Sparkle

/// The central manager for checking for app updates and providing UI components for configuring and controlling the update process.
public final class HubOMatic : ObservableObject {
    private var subscribers = Set<AnyCancellable>()
    let updater = SUUpdater.shared()
    let config: Config

    public struct Config : Hashable, Codable {
        var releasesURL: URL
        var versionInfo: URL
        var versionInfoLocal: URL?
        var relativeArtifact: String

        /// Creates a HubOMatic config for the given GitHub organization and repository following default naming conventions.
        ///
        /// "https://github.com/hubomatic/MicroVector/releases/latest/download/appcast.xml"
        static func github(org: String, repo: String, update: String = "appcast.xml", archive: String? = nil, latest: String = "latest") -> Self {
            let github = URL(string: "https://github.com")!
            let orgURL = github.appendingPathComponent(org)
            let repoURL = orgURL.appendingPathComponent(repo)
            let releasesURL = repoURL.appendingPathComponent("releases")
            let latestURL = releasesURL.appendingPathComponent(latest)
            let downloadDir = latestURL.appendingPathComponent("download")
            let updatePath = downloadDir.appendingPathComponent(update)

            let config = Config(releasesURL: releasesURL, versionInfo: updatePath, versionInfoLocal: Bundle.main.url(forResource: update, withExtension: nil), relativeArtifact: archive ?? repo + ".zip")

            return config
        }
    }

    deinit {
        subscribers.removeAll()
    }

    private init(config: Config) {
        self.config = config
    }

    func setup() {
        UserDefaults.standard.set(config.versionInfo.absoluteString, forKey: "SUFeedURL")
    }
}

public extension HubOMatic {
    /// The URL for downloading the artifact
    var artifactURL: URL {
        config.versionInfo
            .deletingLastPathComponent()
            .appendingPathComponent(config.relativeArtifact)
    }

    @discardableResult static func create(_ config: Config) -> Self {
        dbg("HubOMatic starting with config:", config)
        let hom = Self(config: config)
        hom.setup()
        return hom
    }

    /// Initiates an update check
    func checkForUpdateAction() {
        dbg()
        updater?.checkForUpdates(nil)
    }

    func toolbarButton() -> some View {
        Button(loc("Check for Update"), action: checkForUpdateAction)
    }
}


public struct HubOMaticUpdateCommands : Commands {
    let hub: HubOMatic

    public var body: some Commands {
        Group {
            CommandGroup(after: CommandGroupPlacement.appSettings) {
                Button(loc("Check for Updates"), action: hub.checkForUpdateAction)
            }
        }
    }
}

public extension Scene {
    func withHubOMatic(_ hub: HubOMatic) -> some Scene {
        Group {
            self.commands { HubOMaticUpdateCommands(hub: hub) }
        }

    }
}

