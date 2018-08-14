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

class ConfigManager {
    
    static let shared = ConfigManager()
    
    private init(){}
    
    let storageManager = LocalStorageManager.shared
    let kDefaultConfigKey = "config"
    
    /// Saves configuration information to memory with a given key.
    ///
    /// - Parameters:
    ///   - config: COnfiguration object.
    ///   - configKey: Key which configurations are saved under
    func saveConfig(config: OIDServiceConfiguration, configKey: String) {
        storageManager.saveData(object: config, key: configKey)
    }
    
    /// Saves configuration information to memory with default key.
    ///
    /// - Parameter config: Configuration object.
    func saveConfig(config: OIDServiceConfiguration) {
        storageManager.saveData(object: config, key: kDefaultConfigKey)
    }
    
    /// Retrieves configuration information from memory for a given key.
    ///
    /// - Parameter configKey: Key which configurations are saved under.
    /// - Returns: Configuration object.
    func getConfig(configKey: String) -> OIDServiceConfiguration? {
        if let config = storageManager.getData(key: configKey) as? OIDServiceConfiguration {
            return config
        } else {
            return nil
        }
    }
    
    /// Retrieves configuration information from memory for the default key.
    ///
    /// - Returns: Configuration object.
    func getConfig() -> OIDServiceConfiguration? {
        if let config = storageManager.getData(key: kDefaultConfigKey) as? OIDServiceConfiguration {
            return config
        } else {
            return nil
        }
    }
    
}
