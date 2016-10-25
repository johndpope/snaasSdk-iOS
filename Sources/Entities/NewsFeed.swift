//
//  NewsFeed.swift
//  Tapglue
//
//  Created by John Nilsen on 8/4/16.
//  Copyright © 2016 Tapglue. All rights reserved.
//

import Foundation

open class NewsFeed: NSObject, DefaultInstanceEntity {
    var activities: [Activity]?
    var posts: [Post]?
    
    required public override init() {
        activities = [Activity]()
        posts = [Post]()
    }
}
