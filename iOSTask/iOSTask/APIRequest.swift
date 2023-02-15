//
//  APIRequest.swift
//  iOSTask
//
//  Created by Mert Duran on 14.02.2023.
//

import Foundation

struct ConfigAccess {
    static var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "accessToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "accessToken")
        }
    }
}
func performLoginRequest(completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
    let headers = [
        "Authorization": "Basic QVBJX0V4cGxvcmVyOjEyMzQ1NmlzQUxhbWVQYXNz",
        "Content-Type": "application/json"
    ]
    let parameters = [
        "username": "365",
        "password": "1"
    ] as [String : Any]
    
    let postData = try? JSONSerialization.data(withJSONObject: parameters)
    
    let request = NSMutableURLRequest(url: URL(string: "https://api.baubuddy.de/index.php/login")!,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            completion(.failure(error))
        } else {
            if let httpResponse = response as? HTTPURLResponse {
                do {
                    let json = try JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String: Any]
                    if let oauth = json?["oauth"] as? [String: Any], let accessToken = oauth["access_token"] as? String {
                        print("Access Token: \(accessToken)")
                        ConfigAccess.accessToken = accessToken
                        completion(.success(httpResponse))
                    } else {
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Access token not found in JSON response"])
                        completion(.failure(error))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received in response"])
                completion(.failure(error))
            }
        }
    })
    
    dataTask.resume()
}



func printAccessToken(_ response: HTTPURLResponse?, _ accessToken: String?, _ error: Error?) {
    if let error = error {
        print("Error: \(error)")
        return
    }
    
    if let response = response, response.statusCode != 200 {
        print("Unexpected status code: \(response.statusCode)")
        return
    }
    
    if let accessToken = accessToken {
        print("Access token: \(accessToken)")
    } else {
        print("No access token found in response")
    }
}

func requestTasks(accessToken: String?, completion: @escaping (_ response: HTTPURLResponse?, _ tasks: [Task]?, _ error: Error?) -> Void)
{
    guard let accessToken = ConfigAccess.accessToken else {
        completion(nil, nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Access token not available"]))
        return
    }
    
    let headers = [
        "Authorization": "Bearer \(accessToken)",
        "Content-Type": "application/json"
    ]
    
    let request = NSMutableURLRequest(url: URL(string: "https://api.baubuddy.de/dev/index.php/v1/tasks/select")!,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            completion(nil, nil, error)
        } else {
            let httpResponse = response as? HTTPURLResponse
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                    let tasks = json?.compactMap({ Task(json: $0) })
                    completion(httpResponse, tasks, nil)
                } catch {
                    completion(httpResponse, nil, error)
                }
            } else {
                completion(httpResponse, nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received in response"]))
            }
        }
    })
    
    dataTask.resume()
}
