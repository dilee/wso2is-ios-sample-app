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
    var redirectURLStr: String?
    var authURLStr: String?
    var tokenURLStr: String?
    
    // Tokens
    var accessToken: String?
    var refreshToken: String?
    var idToken: String?

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
            redirectURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kRedirectURLPropKey) as? String
            authURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kAuthURLPropKey) as? String
            tokenURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kTokenURLPropKey) as? String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /// Disable auto-rotate
    override open var shouldAutorotate: Bool {
        return false
    }

    // MARK: Actions
    @IBAction func loginButtonAction(_ sender: UIButton) {
        // Action when the login button is clicked
        startAuthWithPKCE()
    }
    
    /// Starts authorization flow.
    func startAuthWithPKCE() {
        
        let authURL = URL(string: authURLStr!)
        let tokenURL = URL(string: tokenURLStr!)
        let redirectURL = URL(string: redirectURLStr!)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // Configure OIDC Service
        let config = OIDServiceConfiguration(authorizationEndpoint: authURL!, tokenEndpoint: tokenURL!)
        
        // Generate authorization request with PKCE
        let authRequest = OIDAuthorizationRequest(configuration: config,
                                                  clientId: clientID!,
                                                  scopes: [Constants.OAuthReqConstants.kScope],
                                                  redirectURL: redirectURL!,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
        
        // Perform authorization
        appDelegate.externalUserAgentSession = OIDAuthState.authState(byPresenting: authRequest, presenting: self, callback: { (authorizationState, error) in
            
            // Handle authorization error
            if let e = error {
                print(Constants.ErrorMessages.authorizationErrorGeneral + " : " + e.localizedDescription)
                let alert = UIAlertController(title: "Error", message: Constants.ErrorMessages.authorizationErrorGeneral, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            // Authorization request success
            if let authState = authorizationState {
                self.logIn(authorizationState: authState)
            }
        })
        
    }
    
    
    /// Logs in user and switches to the next view.
    ///
    /// - Parameter authorizationState: Authorization State object.
    func logIn(authorizationState: OIDAuthState) -> Void {
        accessToken = authorizationState.lastTokenResponse?.accessToken!
        refreshToken = authorizationState.lastTokenResponse?.refreshToken!
        idToken = authorizationState.lastTokenResponse?.idToken!
        
        print("Access Token: " + accessToken!)
        print("Refresh Token: " + refreshToken!)
        print("ID Token: " + idToken!)
        
        performSegue(withIdentifier: "loggedInSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let loggedInVC : LoggedInViewController = segue.destination as! LoggedInViewController
        loggedInVC.accessToken = accessToken
        loggedInVC.refreshToken = refreshToken
        loggedInVC.idToken = idToken
    }

}

