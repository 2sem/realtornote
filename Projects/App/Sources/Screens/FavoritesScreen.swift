//
//  FavoritesScreen.swift
//  App
//
//  Created by Claude on 12/3/25.
//

import SwiftUI
import SwiftData

struct FavoritesScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Favorite.id) private var favorites: [Favorite]
    
    @AppStorage("FavoriteSortType") private var sortType: Int = 0
    
    enum SortType: Int {
        case byNumber = 0
        case bySubject = 1
    }
    
    var currentSortType: SortType {
        SortType(rawValue: sortType) ?? .byNumber
    }
    
    // Group favorites by subject
    var favoritesBySubject: [(Subject, [Favorite])] {
        let grouped = Dictionary(grouping: favorites) { favorite -> Subject? in
            favorite.part.chapter?.subject
        }
        
        return grouped
            .compactMap { key, value -> (Subject, [Favorite])? in
                guard let subject = key else { return nil }
                return (subject, value.sorted { $0.id < $1.id })
            }
            .sorted { $0.0.id < $1.0.id }
    }
    
    var body: some View {
        List {
            switch currentSortType {
            case .byNumber:
                ForEach(favorites) { favorite in
                    FavoriteRow(favorite: favorite, showSubject: true)
                        .onTapGesture {
                            // Navigate to part (will be handled by parent)
                        }
                }
                .onDelete(perform: deleteFavorites)

            case .bySubject:
                ForEach(favoritesBySubject, id: \.0.id) { subject, subjectFavorites in
                    Section(header: Text(subject.name)) {
                        ForEach(subjectFavorites) { favorite in
                            FavoriteRow(favorite: favorite, showSubject: false)
                                .onTapGesture {
                                    // Navigate to part (will be handled by parent)
                                }
                        }
                        .onDelete { indexSet in
                            deleteFavoritesInSection(subjectFavorites, at: indexSet)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.506, green: 0.831, blue: 0.980))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.506, green: 0.831, blue: 0.980), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("정렬", selection: $sortType) {
                    Text("번호순").tag(0)
                    Text("과목순").tag(1)
                }
                .pickerStyle(.segmented)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("완료") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .onAppear {
            configureNavigationBarAppearance()
        }
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.506, green: 0.831, blue: 0.980, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
        try? modelContext.save()
    }
    
    private func deleteFavoritesInSection(_ subjectFavorites: [Favorite], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjectFavorites[index])
        }
        try? modelContext.save()
    }
}

struct FavoriteRow: View {
    let favorite: Favorite
    let showSubject: Bool
    
    var part: Part {
        favorite.part
    }
    
    var chapter: Chapter? {
        part.chapter
    }
    
    var subject: Subject? {
        chapter?.subject
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chapter info
            if showSubject {
                Text("\(subject?.name ?? "") 〉 \(chapter?.seq.toRoman() ?? ""). \(chapter?.name ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(chapter?.seq.toRoman() ?? ""). \(chapter?.name ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Part info
            Text("\(part.seq). \(part.name)")
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

// Extension to convert Int to Roman numerals
extension Int {
    func toRoman() -> String {
        let romanValues = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        
        var result = ""
        var number = self
        
        for (value, letter) in romanValues {
            while number >= value {
                result += letter
                number -= value
            }
        }
        
        return result
    }
}
