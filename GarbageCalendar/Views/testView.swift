//
//  testView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/12.
//

import SwiftUI

struct testView: View {
    
    @State var editingText = ""
    @FocusState var isInputActive: Bool
    
    var body: some View {
        VStack {
            TextField("input", text: $editingText)
                .padding()
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Cancel") {
                            self.isInputActive = false
                        }
                    }
                }
            TextField("あああああ", text: $editingText)

        }
    }
}
