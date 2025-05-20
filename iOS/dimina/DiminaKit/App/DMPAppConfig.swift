//
//  DMPAppConfig.swift
//  dimina
//
//  Created by Lehem on 2025/4/17.
//

import SwiftUI

public struct DMPAppConfig : Identifiable {
    var appName: String
    var appId: String

    var path: String?
    var versionCode: Int?
    var versionName: String?

    var color: Color?
    var icon: String?

    // 符合Identifiable协议的id属性
    public var id: String { appId }

    init(appName: String, appId: String) {
        self.appName = appName
        self.appId = appId
    }
}
