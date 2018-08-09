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
    var reDirectURLStr: String?
    var clientId: String?
    var userInfo: UserInfo?
    
    let userInfoManager = UserInfoManager.shared
    
    // MARK: Properties
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            reDirectURLStr = configFileDictionaryContent.object(forKey: Constants.OAuthReqConstants.kRedirectURLPropKey) as? String
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func signOutButton(_ sender: UIButton) {
        logOutUser()
    }
    
    /// Logs out the user.
    func logOutUser() {
        
        
        // Retrieve access token from current state
        let currentIdToken: String? = authState?.lastTokenResponse?.idToken
        
        
        // Attempt to fetch fresh tokens if current tokens are expired and perform user info retrieval
        authState?.performAction() { (accessToken, idToken, error) in
            
            if error != nil  {
                print(Constants.ErrorMessages.kErrorFetchingFreshTokens + " \(error?.localizedDescription ?? Constants.LogTags.kError)")
                return
            }
            
            guard let idToken = idToken else {
                print(Constants.ErrorMessages.kErrorRetrievingIdToken)
                return
            }
            
            if currentIdToken != idToken {
                print(Constants.LogInfoMessages.kAccessTokenRefreshed + ": (\(currentIdToken ?? Constants.LogTags.kCurrentIdToken) to \(idToken))")
            } else {
                print(Constants.LogInfoMessages.kIdTokenValid)
            }
            
        }
        
        let logoutURL = URL(string: logoutURLStr!)
        var responseObj: [String: Any]?
        let state = authState?.lastAuthorizationResponse.state!

        // Build the URL
        var urlComponents = URLComponents(string: logoutURLStr!)
        
        urlComponents?.queryItems = [
            URLQueryItem(name: "id_token_hint", value: currentIdToken),
            URLQueryItem(name: "post_logout_redirect_uri", value: reDirectURLStr),
            URLQueryItem(name: "state", value: state)
        ]
        
        // Open browserview
        let safariVC = SFSafariViewController(url: (urlComponents?.url)!)
        safariVC.delegate = self
        self.present(safariVC, animated: true)
        
        return
        
    }
}
