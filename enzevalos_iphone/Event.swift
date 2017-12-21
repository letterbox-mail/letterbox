//
//  Event.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

class Event {
    internal var fields: [String: Any] = [:]
    
    var type: LoggingEventType {
        get {
            if let str = fields["type"] as? String, let type = LoggingEventType(rawValue: str) {
                return type
            }
            return LoggingEventType.unknown
        }
    }
    
    public var description: String {
        get {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: fields)
                if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                    return json
                }
                return ""
            } catch {
                return "{\"error\":\"json conversion failed\"}"
            }
        }
    }
    
    init() {
        let now = Date()
        fields["timestamp"] = now.description
    }
    
    /*init(type: LoggingEventType) {
        let now = Date()
        fields["timestamp"] = now.description
        fields["type"] = type.rawValue
    }*/
    
    public func append(key: String, value: Any) {
        fields[key] = value
    }
}
