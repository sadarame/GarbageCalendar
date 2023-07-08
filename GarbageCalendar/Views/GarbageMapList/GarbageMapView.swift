//
//  MapView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import SwiftUI
import MapKit

struct GarbageMapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.331516, longitude: -122.031778), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        
        var body: some View {
            Map(coordinateRegion: $region, annotationItems: [AnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 37.331516, longitude: -122.031778))]) { item in
                MapPin(coordinate: item.coordinate)
            }
        }
    }

    struct AnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }

//    struct ContentView_Previews: PreviewProvider {
//        static var previews: some View {
//            ContentView()
//        }
//    }
