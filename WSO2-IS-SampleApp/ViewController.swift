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
    var clientId: String?
    var issuerURLStr: String?
    var redirectURLStr: String?
    var authURLStr: String?
    var tokenURLStr: String?
    var userInfoURLStr: String?
    var logoutURLStr: String?
    
    // Tokens
    var accessToken: String?
    var refreshToken: String?
    var idToken: String?
    
    let kAuthStateKey = "authState"
    var authState: OIDAuthState?
    let authStateManager = AuthStateManager.shared
    let userInfoManager = UserInfoManager.shared
    let configManager = ConfigManager.shared
    var config: OIDServiceConfiguration?
    
    var userInfo: UserInfo!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var configFileDictionary: NSDictionary?
        
        //Load configurations into the resourceFileDictionary dictionary
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            configFileDictionary = NSDictionary(contentsOfFile: path)
        }
        
        // Load auth state if exists
        let authState = authStateManager.getAuthState()
        if (authState != nil) {
            self.authState = authState
        }
        
        // Read from dictionary content
        if let configFileDictionaryContent = configFileDictionary {
            clientId = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kClientIdPropKey) as? String
            issuerURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kIssuerIdPropKey) as? String
            redirectURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kRedirectURLPropKey) as? String
            authURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kAuthURLPropKey) as? String
            tokenURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kTokenURLPropKey) as? String
            userInfoURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kUserInfoURLPropKey) as? String
            logoutURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kLogoutURLPropKey) as? String
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
        let userInfoURL = URL(string: userInfoURLStr!)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // Configure OIDC Service
        self.config = OIDServiceConfiguration(authorizationEndpoint: authURL!, tokenEndpoint: tokenURL!)
        appDelegate.config = self.config
        configManager.saveConfig(config: self.config!)
        
        // Generate authorization request with PKCE
        let authRequest = OIDAuthorizationRequest(configuration: config!,
                                                  clientId: clientId!,
                                                  scopes: [Constants.OAuthReqConstants.kScope],
                                                  redirectURL: redirectURL!,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
        
        // Perform authorization
        appDelegate.externalUserAgentSession = OIDAuthState.authState(byPresenting: authRequest, presenting: self, callback: { (authorizationState, error) in
            
            // Handle authorization error
            if let e = error {
                print(NSLocalizedString("error.authorization", comment: Constants.ErrorMessages.kAuthorizationError) + " : " + e.localizedDescription)
                let alert = UIAlertController(title: "Error", message: NSLocalizedString("error.authorization", comment: Constants.ErrorMessages.kAuthorizationError), preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            // Authorization request success
            if let authState = authorizationState {
                self.setAuthState(authState)
                self.accessToken = authState.lastTokenResponse?.accessToken!
                self.refreshToken = authState.lastTokenResponse?.refreshToken!
                self.idToken = authState.lastTokenResponse?.idToken!
                self.retrieveUserInfo(userInfoURL: userInfoURL!)
            }
        })
        
    }
    
    /// Retrieves user information from the server using the access token.
    ///
    /// - Parameters:
    ///   - userInfoEP: User information endpoint.
    /// - Returns: User information as a JSON object.
    func retrieveUserInfo(userInfoURL: URL) {
        
        // Retrieve access token from current state
        let currentAccessToken: String? = authState?.lastTokenResponse?.accessToken
        
        var jsonResponse: [String: Any]?
        
        // Attempt to fetch fresh tokens if current tokens are expired and perform user info retrieval
        authState?.performAction() { (accessToken, idToken, error) in
            
            if error != nil  {
                print(NSLocalizedString("error.fetch.freshtokens", comment: Constants.ErrorMessages.kErrorFetchingFreshTokens) + " \(error?.localizedDescription ?? Constants.LogTags.kError)")
                return
            }
            
            guard let accessToken = accessToken else {
                print(NSLocalizedString("error.fetch.accesstoken", comment: Constants.ErrorMessages.kErrorRetrievingAccessToken))
                return
            }
            
            if currentAccessToken != accessToken {
                print(NSLocalizedString("info.accesstoken.refreshed", comment: Constants.LogInfoMessages.kAccessTokenRefreshed) + ": (\(currentAccessToken ?? Constants.LogTags.kCurrentAccessToken) to \(accessToken))")
            } else {
                print(NSLocalizedString("info.accesstoken.valid", comment: Constants.LogInfoMessages.kAccessTokenValid) + ": \(accessToken)")
            }
            
            // Build user info request
            var urlRequest = URLRequest(url: userInfoURL)
            urlRequest.httpMethod = "POST"
            // Request header
            urlRequest.allHTTPHeaderFields = ["Authorization":"Bearer \(accessToken)"]
            // Request body
            let tokenStr = "token=\(accessToken)"
            let data: Data? = tokenStr.data(using: .utf8)
            urlRequest.httpBody = data
            
            // Retrieve user information
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        print(NSLocalizedString("error.http.request.fail", comment: Constants.ErrorMessages.kHTTPRequestFailed) + " \(error?.localizedDescription ?? Constants.LogTags.kError)")
                        return
                    }
                    
                    // Check for non-HTTP response
                    guard let response = response as? HTTPURLResponse else {
                        print(NSLocalizedString("info.nonhttp.response", comment: Constants.LogInfoMessages.kNonHTTPResponse))
                        return
                    }
                    
                    // Check for empty response
                    guard let data = data else {
                        print(NSLocalizedString("info.http.response.empty", comment: Constants.LogInfoMessages.kHTTPResponseEmpty))
                        return
                    }
                    
                    // Parse data into a JSON object
                    do {
                        jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        print(NSLocalizedString("error.json.serialization", comment: Constants.ErrorMessages.kJSONSerializationError))
                    }
                    
                    // Response with an error
                    if response.statusCode != Constants.HTTPResponseCodes.kOk {
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                        
                        if response.statusCode == Constants.HTTPResponseCodes.kUnauthorised {
                            // Possible an issue with the authorization grant
                            let oAuthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: jsonResponse,
                                                                                                underlyingError: error)
                            self.authState?.update(withAuthorizationError: oAuthError)
                            print(Constants.ErrorMessages.kAuthorizationError + " (\(oAuthError)). Response: \(responseText ?? Constants.LogTags.kResponseText)")
                        } else {
                            print(Constants.LogTags.kHTTP + "\(response.statusCode), Response: \(responseText ?? Constants.LogTags.kResponseText)")
                        }
                    }
                    
                    if let json = jsonResponse {
                        print(NSLocalizedString("info.information.fetch.success", comment:Constants.LogInfoMessages.kInfoRetrievalSuccess) + ": \(json)")
                        let userName = jsonResponse!["username"] as? String
                        if let un = userName {
                            let userInfo = UserInfo(userName: un.components(separatedBy: "@")[0])
                            self.userInfo = userInfo
                            self.userInfoManager.saveUserInfo(userInfo: userInfo)
                        }
                        self.logIn()
                    }
                }
            }
            task.resume()
        }
    }
    
    /// Logs user in and switches to the next view.
    func logIn() {
        print("Access Token: " + accessToken!)
        print("Refresh Token: " + refreshToken!)
        print("ID Token: " + idToken!)

        performSegue(withIdentifier: "loggedInSegue", sender: self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let loggedInVC : LoggedInViewController = segue.destination as! LoggedInViewController
        loggedInVC.authState = self.authState
        loggedInVC.clientId = self.clientId
        if let userInfo = self.userInfo {
            loggedInVC.userInfo = userInfo
        }
    }
    
}

//MARK: OIDAuthState Delegate
extension ViewController: OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    func didChange(_ state: OIDAuthState) {
        self.authStateChanged()
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("Authorization error: \(error)")
    }
    
}

//MARK: Helper Methods
extension ViewController {
 
    /// Sets or updates the auth state.
    func setAuthState(_ authState: OIDAuthState?) {
        if (self.authState == authState) {
            return;
        }
        self.authState = authState;
        self.authState?.stateChangeDelegate = self;
        self.authStateChanged()
    }
    
    /// Updates the state when a change occures.
    func authStateChanged() {
        authStateManager.saveAuthState(authState: self.authState!)
    }
    
    /// Clears the auth state.
    func clearAuthState() {
        self.authState = nil
    }
    
}

