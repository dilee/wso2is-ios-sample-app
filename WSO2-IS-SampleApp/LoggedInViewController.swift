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
import SafariServices

class LoggedInViewController: UIViewController, SFSafariViewControllerDelegate {
    
    var logoutURLStr: String?
    var authState: OIDAuthState?
    var redirectURLStr: String?
    var clientId: String?
    var userInfo: UserInfo?
    
    let userInfoManager = UserInfoManager.shared
    let authStateManager = AuthStateManager.shared
    let localStorageManager = LocalStorageManager.shared
    let configManager = ConfigManager.shared
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var userAgent:OIDExternalUserAgentIOS?
    
    // MARK: Properties
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        self.userAgent = OIDExternalUserAgentIOS(presenting: self)
        super.viewDidLoad()
        
        if self.authState == nil {
            self.authState = self.authStateManager.getAuthState()
        }
        
        if self.userInfo == nil {
            self.userInfo = self.userInfoManager.getUserInfo()
        }

        // Setting user information to labels
        if let userInfo = self.userInfo {
            userNameLabel.text = userInfo.userName
        }
        
        var configFileDictionary: NSDictionary?
        
        //Load configurations into the resourceFileDictionary dictionary
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            configFileDictionary = NSDictionary(contentsOfFile: path)
        }
        
        // Read from dictionary content
        if let configFileDictionaryContent = configFileDictionary {
            logoutURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kLogoutURLPropKey) as? String
            redirectURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kRedirectURLPropKey) as? String
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func signOutButton(_ sender: UIButton) {
        let refreshAlert = UIAlertController(title: NSLocalizedString("info.alert.signout.title", comment: "Sign out"), message: NSLocalizedString("info.alert.signout.message", comment: "Are you sure you want to logout? This will clear all your data on this device."), preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.logOutUser()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    /// Logs out the user.
    func logOutUser() {
        
        // Retrieve ID token from current state
        let currentIdToken: String? = authState?.lastTokenResponse?.idToken
        
        // Attempt to fetch fresh tokens if current tokens are expired and perform user info retrieval
        authState?.performAction() { (accessToken, idToken, error) in
            
            if error != nil  {
                print(NSLocalizedString("error.fetch.freshtokens", comment: Constants.ErrorMessages.kErrorFetchingFreshTokens) + " \(error?.localizedDescription ?? Constants.LogTags.kError)")
                return
            }
            
            guard let idToken = idToken else {
                print(NSLocalizedString("error.fetch.idtoken", comment: Constants.ErrorMessages.kErrorRetrievingIdToken))
                return
            }
            
            if currentIdToken != idToken {
                print(NSLocalizedString("info.idtoken.refreshed", comment: Constants.LogInfoMessages.kAccessTokenRefreshed)  + ": (\(currentIdToken ?? Constants.LogTags.kCurrentIdToken) to \(idToken))")
            } else {
                print(NSLocalizedString("info.idtoken.valid", comment: Constants.LogInfoMessages.kIdTokenValid))
            }
            
        }
        
        // Redirect to the OP's logout page
        let logoutURL = URL(string: logoutURLStr!)
        let postLogoutRedirURL = URL(string: redirectURLStr!)
        
        if (appDelegate.config == nil) {
            appDelegate.config = configManager.getConfig()
        }
        
        let config = OIDServiceConfiguration(authorizationEndpoint: (appDelegate.config?.authorizationEndpoint)!, tokenEndpoint: (appDelegate.config?.tokenEndpoint)!, issuer: nil, registrationEndpoint: nil, endSessionEndpoint: logoutURL)
        
        let logoutRequest = OIDEndSessionRequest(configuration: config, idTokenHint: currentIdToken!, postLogoutRedirectURL: postLogoutRedirURL!, state: (authState?.lastAuthorizationResponse.state)!, additionalParameters: nil)
        
        appDelegate.externalUserAgentSession = OIDAuthorizationService.present(logoutRequest, externalUserAgent: userAgent!, callback: { (authorizationState, error) in})

        // Log out locally
        appDelegate.externalUserAgentSession = nil
        localStorageManager.clearLocalMemory()
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "mainVC")
        self.appDelegate.window?.rootViewController = viewController
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

}
