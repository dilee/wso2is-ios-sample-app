//
//  ConfigManager.swift
//  WSO2-IS-SampleApp
//
//  Created by Dileesha on 8/13/18.
//  Copyright © 2018 WSO2. All rights reserved.
//

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
