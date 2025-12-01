//
//  PartScreen.swift
//  App
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct PartScreen: View {
    let part: Part

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(part.seq). \(part.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Text(part.content)
                    .font(.body)
                    .padding()

                Spacer()
            }
        }
    }
}