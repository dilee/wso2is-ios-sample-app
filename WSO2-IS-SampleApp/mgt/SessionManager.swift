/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import Foundation
import AppAuth

class SessionManager {
    
    static let shared = SessionManager()
    
    private init(){}
    
    let storageManager = LocalStorageManager.shared
    let kDefaultSessionKey = "authSession" 
    
    /// Saves the user agent session to memory with a given key.
    ///
    /// - Parameters:
    ///   - session: User agent session.
    ///   - sessionKey: Key to store session under.
    func saveSession(session: OIDExternalUserAgentSession, sessionKey: String) {
        storageManager.saveData(object: session, key: sessionKey)
    }
  
    /// Saves the user agent session to memory with default key.
    ///
    /// - Parameter session: User agent session.
    func saveSession(session: OIDExternalUserAgentSession) {
        storageManager.saveData(object: session, key: kDefaultSessionKey)
    }
    
    /// Retrieves the user agent session from memory from a given key.
    ///
    /// - Parameter sessionKey: Key which the session is stored under.
    /// - Returns: User agent session.
    func getSession(sessionKey: String) -> OIDExternalUserAgentSession? {
        if let sessionWrapper = storageManager.getData(key: sessionKey) as? SessionWrapper {
            return sessionWrapper.uaSession
        } else {
            return nil
        }
    }
    
    /// Retrieves the user agent session from memory from default key.
    ///
    /// - Returns: User agent session.
    func getSession() -> OIDExternalUserAgentSession? {
        if let session = storageManager.getData(key: kDefaultSessionKey) as? OIDExternalUserAgentSession {
            return session
        } else {
            return nil
        }
    }
    
}
