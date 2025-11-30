//
//  SubjectScreen 2.swift
//  App
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct SubjectScreen: View {
    let subject: Subject

    var body: some View {
        NavigationView {
            VStack {
                Text(subject.name)
                    .font(.largeTitle)
                    .padding()

                Text(subject.detail)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()

                // TODO: 실제 과목 내용 표시
                Text("과목 내용이 여기에 표시됩니다")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle(subject.name)
        }
    }
}