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

//extension MKMapPoint: Decodable {
//    public init(from decoder: Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//
//        let x = try container.decode(Double.self)
//        let y = try container.decode(Double.self)
//
//        self = MKMapPoint(x: x, y: y)
//    }
//}


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

enum GeoFeature {
    case feature(geometry: Geom?, properties: [String: DecodableValue], id: String?)
    case featureCollection(features: [GeoFeature], properties: [String: DecodableValue], id: String?)
}

extension GeoFeature: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case features
        case id
        case properties
        case geometry
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try! container.decode(String.self, forKey: .type)
        let id = try? container.decode(String.self, forKey: .id)
        let properties = try? container.decode([String: DecodableValue].self, forKey: CodingKeys.properties)
        
        switch type {
        case "Feature":
            let geometry = try! container.decode(Geom?.self, forKey: .geometry)
            self = .feature(geometry: geometry, properties: properties ?? [:], id: id)
        case "FeatureCollection":
            let features = try! container.decode([GeoFeature].self, forKey: .features)
            self = .featureCollection(features: features, properties: properties ?? [:], id: id)
        default:
            throw GeoJSONError.invalidFeatureType(type)
        }
    }
}
