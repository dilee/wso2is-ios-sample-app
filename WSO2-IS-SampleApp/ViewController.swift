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

import UIKit
import AppAuth

class ViewController: UIViewController {
    
    // Configuration Properties
    var clientID: String?
    var clientSecret: String?
    var redirectURLStr: String?
    var authURLStr: String?
    var tokenURLStr: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    
        var configFileDictionary: NSDictionary?
        
        //Load configurations into the resourceFileDictionary dictionary
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            configFileDictionary = NSDictionary(contentsOfFile: path)
        }
        
        // Read from dictionary content
        if let configFileDictionaryContent = configFileDictionary {
            clientID = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kClientIdPropKey) as? String
            clientSecret = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kClientSecretPropKey) as? String
            redirectURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kRedirectURLPropKey) as? String
            authURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kAuthURLPropKey) as? String
            tokenURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kTokenURLPropKey) as? String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Disable auto-rotate
    override open var shouldAutorotate: Bool {
        return false
    }

    // MARK: Actions
    @IBAction func loginButtonAction(_ sender: UIButton) {
        // Action when the login button is clicked
        startAuthWithPKCE()
    }
    
    func startAuthWithPKCE() {
        
        let authURL = URL(string: authURLStr!)
        let tokenURL = URL(string: tokenURLStr!)
        let redirectURL = URL(string: redirectURLStr!)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        var authState: OIDAuthState?
        
        // Configure OIDC Service
        let config = OIDServiceConfiguration(authorizationEndpoint: authURL!, tokenEndpoint: tokenURL!)
        
        // Generate PKCE code verifier
        let codeVerifier = OIDAuthorizationRequest.generateCodeVerifier()
        
        //Generate code challenge
        let codeChallenge = OIDAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
        
        // Code challange method
        let codeChalMethod = OIDOAuthorizationRequestCodeChallengeMethodS256
        
        // Generate authorization request
        let authRequest = OIDAuthorizationRequest(configuration: config,
                                                  clientId: clientID!,
                                                  clientSecret: clientSecret,
                                                  scope: Constants.OAuthReqConstants.kScope,
                                                  redirectURL: redirectURL,
                                                  responseType: OIDResponseTypeCode,
                                                  state: OIDAuthorizationRequest.generateState(),
                                                  codeVerifier: codeVerifier,
                                                  codeChallenge: codeChallenge,
                                                  codeChallengeMethod: codeChalMethod,
                                                  additionalParameters: nil)
        
        appDelegate.externalUserAgentSession = OIDAuthState.authState(byPresenting: authRequest, presenting: self, callback: { (authorizationState, error) in
            
            // Handle authorization error
            if let e = error {
                print(Constants.ErrorMessages.authorizationErrorGeneral + " : " + e.localizedDescription)
            }
            
            // Authorization request success
            if let authState = authorizationState {
                self.logIn(authotizationState: authState)
            }
        })
    }
    
    func logIn(authotizationState: OIDAuthState) {
        let loggedInVC = LoggedInViewController()
        loggedInVC.accessToken = authotizationState.lastTokenResponse?.accessToken!
        loggedInVC.refreshToken = authotizationState.lastTokenResponse?.refreshToken!
        navigationController?.pushViewController(loggedInVC, animated: true)
    }

}

