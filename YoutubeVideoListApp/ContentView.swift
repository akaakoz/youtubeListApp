//
//  ContentView.swift
//  YoutubeVideoListApp
//
//  Created by Akiya Ozawa on R 3/10/21.
//

import SwiftUI

struct YoutubeSearchList: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String
    let regionCode: String
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeId
    let snippet: Snippet
}

struct YouTubeId: Codable {
    let kind: String
    let videoId: String
}

struct Snippet: Codable {
    let title: String
    let description: String
    let thumbnails: ThumbnailInfo
}

struct ThumbnailInfo: Codable {
    let `default`: ThumbDefaultInfo?
    let high: ThumbHighInfo?
}

struct ThumbDefaultInfo: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct ThumbHighInfo: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct ContentDetails: Codable {
    let duration: String
}

class YoutubeVideoViewModel: ObservableObject {
  
    let youtubeApiService = YoutubeApiService()
    @Published var pageToken = ""
    @Published var youtubeSearchLists = [YoutubeSearchList]()
    @Published var perPage = 15
    
    func fetchVideoWithSearch(searchText: String, pageToken: String = "") {
        youtubeApiService.fetchYouTubeVideos(searchText: searchText, pageToken: pageToken) { [weak self] youtubeSearchList in
            self?.youtubeSearchLists.append(youtubeSearchList)
        }
    }
}

struct YoutubeApiService {
    
    public func fetchYouTubeVideos(searchText: String, pageToken: String = "", completion: @escaping (YoutubeSearchList) -> Void) {
        // TODO: - ↓ Replace your api key
        let apiKey = ""
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(searchText)&pageToken=\(pageToken)&regionCode=US&maxResults=15&type=video&key=\(apiKey)"
      
        guard let url = URL(string: urlString) else {return}
        
        let task = URLSession.shared.dataTask(with: url) { jsonData, response, err in
            if let err = err {
                print("failed to get json data", err.localizedDescription)
                return
            }
            
            guard let jsonData = jsonData else {return}
            
            do {
                let youtubeSeachList = try JSONDecoder().decode(YoutubeSearchList.self, from: jsonData)
                DispatchQueue.main.async {
                    completion(youtubeSeachList)
                }
            } catch let jsonError {
                print("json serialization error", jsonError.localizedDescription)
            }
        }
        task.resume()
    }
}

struct ContentView: View {

    @ObservedObject var youtubeVideoViewModel = YoutubeVideoViewModel()
    @State private var searchText = ""
  
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText) { isEditing in
                } onCommit: {
                    youtubeVideoViewModel.fetchVideoWithSearch(searchText: searchText)
                }
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                List {
                    Group {
                        ForEach(0..<youtubeVideoViewModel.youtubeSearchLists.count, id: \.self) { index in
                            ForEach(0..<youtubeVideoViewModel.youtubeSearchLists[index].items.count, id: \.self) { secondIndex in
                                HStack {
                                    URLImage(url: youtubeVideoViewModel.youtubeSearchLists[index].items[secondIndex].snippet.thumbnails.high?.url ?? "")
                                        .aspectRatio(contentMode: .fit).background(Color.blue)
                                    VStack {
                                        Text(youtubeVideoViewModel.youtubeSearchLists[index].items[secondIndex].snippet.title)
                                            .bold()
                                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5))
                                        Text( youtubeVideoViewModel.youtubeSearchLists[index].items[secondIndex].snippet.description)
                                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                    }
                                }.frame(width: .none, height: 150, alignment: .center)
                                 .onAppear(perform: {
                                   if secondIndex == youtubeVideoViewModel.perPage - 1 && ((youtubeVideoViewModel.youtubeSearchLists.count - 1) == index) {
                                       let pageToken = youtubeVideoViewModel.youtubeSearchLists[index].nextPageToken
                                       youtubeVideoViewModel.fetchVideoWithSearch(searchText: searchText, pageToken: pageToken)
                                   }
                                })
                            }
                        }
                    }
                }
            }
            .navigationTitle("Anime Videos")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class ImageDownloader : ObservableObject {
    @Published var downloadData: Data? = nil

    func downloadImage(url: String) {

        guard let imageURL = URL(string: url) else { return }

        DispatchQueue.global().async {
            let data = try? Data(contentsOf: imageURL)
            DispatchQueue.main.async {
                self.downloadData = data
            }
        }
    }
}

struct URLImage: View {

    let url: String
    @ObservedObject private var imageDownloader = ImageDownloader()

    init(url: String) {
        self.url = url
        self.imageDownloader.downloadImage(url: self.url)
    }

    var body: some View {
        
        if let imageData = self.imageDownloader.downloadData {
            let img = UIImage(data: imageData)
            return VStack {
                Image(uiImage: img!).resizable()
            }
        } else {
            return VStack {
                let img = UIImage()
                Image(uiImage: img).resizable()
            }
        }
    }
}
