//
//  WSO2UserAgentSession.swift
//  WSO2-IS-SampleApp
//
//  Created by Dileesha on 8/10/18.
//  Copyright © 2018 WSO2. All rights reserved.
//

import Foundation
import AppAuth
import SafariServices

class CustomUserAgentSession: NSObject, OIDExternalUserAgentSession {
    
    func cancel() {
        print("User cancelled")
    }
    
    func resumeExternalUserAgentFlow(with URL: URL!) -> Bool {
        let str = URL.absoluteString
        print("#######################")
        print(str)
        print("#######################")
        return false
    }
    
    func failExternalUserAgentFlowWithError(_ error: Error!) {
        print("**********************")
        print(error)
        print("**********************")
    }

}
