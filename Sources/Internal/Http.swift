    //
//  Http.swift
//  Tapglue
//
//  Created by John Nilsen on 7/8/16.
//  Copyright © 2016 Tapglue. All rights reserved.
//

import Foundation
import RxSwift

class Http {
    private var successCodes: Range<Int> = 200..<299
    
	func execute<T: Codable>(_ request: URLRequest) -> Observable<T> {
        return Observable.create {observer in
            let session = URLSession.shared
            var task: URLSessionDataTask?
            
            log(request)
			task = session.dataTask(with: request, completionHandler: { (data, response, error) in
				guard error == nil else {
					self.handleError(data, onObserver: observer, withDefaultError: error)
					return
				}
				if let httpResponse = response as? HTTPURLResponse {
					log(response ?? "HTTP: no response")
					guard self.successCodes.contains(httpResponse.statusCode) else {
						self.handleError(data, onObserver: observer, withDefaultError: error)
						return
					}
					if let data = data {
						let decoder = JSONDecoder()
						if let object = try? decoder.decode(T.self, from: data) {
							observer.on(.next(object))
						} else {
							if let nf = T.self as? NullableFeed.Type {
								let defaultObject = nf.init()
								observer.on(.next(defaultObject as! T))
							}
							else if let empty = [] as? T {
								observer.on(.next(empty))
							}
						}
						observer.on(.completed)
					}
				} else {
					self.handleError(data, onObserver: observer, withDefaultError: error)
				}
			})

            task?.resume()
            
            return Disposables.create()
        }
    }
    
    func execute(_ request: URLRequest) -> Observable<[String:Any]> {
        return Observable.create {observer in
            let session = URLSession.shared
            var task: URLSessionDataTask?
            
            log(request)
            task = session.dataTask(with: request) { (data: Data?, response:URLResponse?, error:Error?) in
                guard error == nil else {
                    self.handleError(data, onObserver: observer, withDefaultError: error)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    log(response ?? "HTTP: no response")
                    guard self.successCodes.contains(httpResponse.statusCode) else {
                        self.handleError(data, onObserver: observer, withDefaultError: error)
                        return
                    }
					if let data = data, let json = self.dataToJSON(data: data) as? [String: Any] {
                        observer.on(.next(json))
					}
					else {
						observer.on(.next([:]))
					}
					observer.on(.completed)
                } else {
                    self.handleError(data, onObserver: observer, withDefaultError: error)
                }
            }
            
            task?.resume()
            
            return Disposables.create()
        }
    }
    
    func execute(_ request:URLRequest) -> Observable<Void> {
        
        return Observable.create {observer in
            let session = URLSession.shared
            var task: URLSessionDataTask?
            
            log(request)
            task = session.dataTask(with: request) { (data: Data?, response:URLResponse?, error:Error?) in
                guard error == nil else {
                    self.handleError(data, onObserver: observer, withDefaultError: error)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    log(response ?? "HTTP: no response")
                    guard self.successCodes.contains(httpResponse.statusCode) else {
                        self.handleError(data, onObserver: observer, withDefaultError: error)
                        return
                    }
                    observer.on(.completed)
                } else {
                    self.handleError(data, onObserver: observer, withDefaultError: error)
                }
            }
            
            task?.resume()
            
            return Disposables.create()
        }
    }

    fileprivate func handleError<T>(_ data: Data?, onObserver observer: AnyObserver<T>,
                                withDefaultError error: Error?) {
        if let data = data {
            let json = String(data: data, encoding: String.Encoding.utf8)!
            if let errorFeed = ErrorFeed.fromJSON(with: json) {
                log(errorFeed.toJSONString() ?? "HTTP: no error json to print")
                if let tapglueErrors = errorFeed.errors {
                    observer.on(.error(tapglueErrors[0]))
                } else {
                    observer.on(.error(error ?? TapglueError()))
                }
            } else {
                observer.on(.error(error ?? TapglueError()))
            }
        }
    }
    
    fileprivate func dataToJSON(data: Data) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil
    }
}
