//
//  CalendarView.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/02/04.
//

import SwiftUI
import FSCalendar
 
struct CalendarView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        
        typealias UIViewType = FSCalendar
        
        let fsCalendar = FSCalendar()
            
        return fsCalendar
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
