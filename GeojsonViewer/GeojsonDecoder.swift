//
//  GeojsonDecoder.swift
//  GeojsonViewer
//
//  Created by Brian Sanders on 5/12/18.
//  Copyright © 2018 Brian Sanders. All rights reserved.
//

import Foundation
//import MapKit


enum GeoJSONError: Error {
    case invalidGeometryType(String)
    case invalidFeatureType(String)
    case decodeError
}

typealias FeatureDecodedCallback = ([CodingKey], GeoFeature) -> Void


enum Geom {
    case point([Double])
    case multiPoint([[Double]])
    case lineString([[Double]])
    case multiLineString([[[Double]]])
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])
    case geometryCollection([Geom])
}

extension Geom: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case coordinates
        case geometries
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try! container.decode(String.self, forKey: .type)
        
        switch type {
        case "Point":
            self = .point(try! container.decode([Double].self, forKey: .coordinates))
        case "MultiPoint":
            self = .multiPoint(try! container.decode([[Double]].self, forKey: .coordinates))
        case "LineString":
            self = .lineString(try! container.decode([[Double]].self, forKey: .coordinates))
        case "MultiLineString":
            self = .multiLineString(try! container.decode([[[Double]]].self, forKey: .coordinates))
        case "Polygon":
            self = .polygon(try! container.decode([[[Double]]].self, forKey: .coordinates))
        case "MultiPolygon":
            self = .multiPolygon(try! container.decode([[[[Double]]]].self, forKey: .coordinates))
        case "GeometryCollection":
            self = .geometryCollection(try! container.decode([Geom].self, forKey: .geometries))
        default:
            throw GeoJSONError.invalidGeometryType(type)
        }
    }
}

enum DecodableValue: Decodable {
    case str(String)
    case number(Double)
    case bool(Bool)
    case array([DecodableValue])
    case dict([String: DecodableValue])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // There MUST be a better way to do this, surely!
        if let strVal = try? container.decode(String.self) {
            self = .str(strVal)
        } else if let numVal = try? container.decode(Double.self) {
            self = .number(numVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let arrayVal = try? container.decode([DecodableValue].self) {
            self = .array(arrayVal)
        } else if let dictVal = try? container.decode([String: DecodableValue].self) {
            self = .dict(dictVal)
        } else {
            self = .null
        }
    }
}

class GeoFeature: Decodable {
    enum FeatureType {
        case feature(geometry: Geom?)
        case collection(features: [GeoFeature])
    }
    let properties: [String: DecodableValue]
    let id: String?
    let type: FeatureType
    
    init(properties: [String: DecodableValue], id: String?, type: FeatureType) {
        self.properties = properties
        self.id = id
        self.type = type
    }

    enum CodingKeys: CodingKey {
        case type
        case features
        case id
        case properties
        case geometry
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try? container.decode(String.self, forKey: .id)
        self.properties = (try? container.decode([String: DecodableValue].self, forKey: CodingKeys.properties)) ?? [:]
        let typeName = try! container.decode(String.self, forKey: .type)
        
        switch typeName {
        case "Feature":
            let geometry = try! container.decode(Geom?.self, forKey: .geometry)
            self.type = .feature(geometry: geometry)
        case "FeatureCollection":
            let features = try! container.decode([GeoFeature].self, forKey: .features)
            self.type = .collection(features: features)
        default:
            throw GeoJSONError.invalidFeatureType(typeName)
        }
        
        let key = CodingUserInfoKey(rawValue: "onProgress")!
        if let onProgress = decoder.userInfo[key] as? FeatureDecodedCallback{
            onProgress(decoder.codingPath, self)
        }
    }
}
