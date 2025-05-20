//
//  DMPPageRecord.swift
//  dimina
//
//  Created by Lehem on 2025/5/12.
//

public class DMPPageRecord {
    var webViewId: Int
    var fromWebViewId: Int
    var pagePath: String
    var query: [String: Any]?
    var navStyle: [String: Any]?
//    var pageStyle: DMPPageStyle?

    init(webViewId: Int, fromWebViewId: Int, pagePath: String) {
        self.pagePath = pagePath
        self.webViewId = webViewId
        self.fromWebViewId = fromWebViewId
    }
}
