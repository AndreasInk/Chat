//
//  SessionManager.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 13.06.2023.
//

import Foundation
import ExyteChat
#if os(iOS)
import UIKit
#endif
let hasCurrentSessionKey = "hasCurrentSession"
let currentUserKey = "currentUser"

class SessionManager {

    static let shared = SessionManager()

    static var currentUserId: String {
        shared.currentUser?.id ?? ""
    }

    static var currentUser: User? {
        shared.currentUser
    }

    var deviceId: String {
#if os(iOS)
        UIDevice.current.identifierForVendor?.uuidString ?? ""
        #else
        UUID().uuidString
        #endif
    }

    @Published private var currentUser: User?

    func storeUser(_ user: User) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
        UserDefaults.standard.set(true, forKey: hasCurrentSessionKey)
        currentUser = user
    }

    func loadUser() {
        if let data = UserDefaults.standard.data(forKey: "currentUser") {
            currentUser = try? JSONDecoder().decode(User.self, from: data)
        }
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.set(false, forKey: hasCurrentSessionKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
}
