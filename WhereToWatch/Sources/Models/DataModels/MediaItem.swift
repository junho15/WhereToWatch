import UIKit
import MovieDatabaseAPI

struct MediaItem: MediaItemProtocol {
    var genre: String?
    var id: Int {
        return media.id
    }
    var title: String? {
        return media.title
    }
    var date: String? {
        return media.date?.year
    }
    var posterPath: String? {
        return media.posterPath
    }
    var backdropPath: String? {
        return media.backdropPath
    }
    var mediaType: MediaType {
        return media.mediaType
    }
    var overView: String? {
        return media.overview
    }
    private let media: any MediaProtocol

    init(media: any MediaProtocol, genreList: GenreList?) {
        self.media = media
        guard let genreIds = media.genreIds else { return }
        self.genre = genreList?.genres.filter {
            genreIds.contains($0.id)
        }.compactMap {
            $0.name
        }.joined(separator: ", ")
    }
}
