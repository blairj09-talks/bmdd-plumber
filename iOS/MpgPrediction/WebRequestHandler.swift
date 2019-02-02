//
//  WebRequestHandler.swift
//  MpgPrediction
//
//  Created by Nathan Dudley on 1/13/19.
//  Copyright © 2019 Nathan Dudley. All rights reserved.
//

import Foundation

class WebRequestHandler {
    
    static func createHeaderParameters(parameters: [String: Any]) -> Data? {
        do {
            let serializedParameters = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
            if let jsonString = String(data: serializedParameters!, encoding: .utf8) {
                print(jsonString)
            }
            
            return serializedParameters
        }
    }
    
    static func sendWebRequest(httpMethod: String, endpoint: String, httpBody: Data?,
                               onCompletion: @escaping (NSArray) -> (),
                               onError: @escaping (String) -> () ){
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            guard let url = URL(string: endpoint) else {
                returnError(onError: onError, message: "Error: Cannot create URL.")
                return
            }
            
            var urlRequest = URLRequest(url: url)
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            urlRequest.httpMethod = httpMethod
            
            if httpBody != nil {
                urlRequest.httpBody = httpBody
                urlRequest.setValue("application/json", forHTTPHeaderField:"Content-Type")
            }
            
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                guard let responseData = data else {
                    returnError(onError: onError, message: "Error: No data returned.")
                    return
                }
                
                guard error == nil else {
                    returnError(onError: onError, message: "Error: \(String(describing: error))")
                    return
                }
                
                do {
                    if let webResponse = try JSONSerialization.jsonObject(with: responseData, options: []) as? NSArray {
                        DispatchQueue.main.async(execute: {
                            print(webResponse)
                            onCompletion(webResponse)
                        })
                    }
                } catch  {
                    returnError(onError: onError, message: "Error: Could not convert data to JSON.")
                    return
                }
            })
            task.resume()
        }
    }
    
    private static func returnError(onError: @escaping (String) -> (), message: String) {
        DispatchQueue.main.async(execute: {
            onError(message)
        })
    }
}
