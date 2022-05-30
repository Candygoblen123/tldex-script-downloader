//
//  TLDex.swift
//  
//
//  Created by Andrew Glaze on 5/29/22.
//

import Foundation

struct TLDex: Codable {
    let name: String
    let timestamp: String
    let message: String
}

struct VidMeta: Codable {
    let status: String?
    let start_actual: String?
    let available_at: String?
}
