import UIKit
import MovieDatabaseAPI

final class FavoriteViewModel {

    // MARK: Properties

    private let favoriteService = FavoriteService.shared
    private let movieDatabaseAPIClient: MovieDatabaseAPIClient
    private(set) var sortOption: FavoriteService.SortOption
    private var query: String
    private var favoriteMediaItems: [FavoriteMediaItem] {
        didSet {
            self.onUpdate?(favoriteMediaItemIDs)
        }
    }
    private var onError: ((String) -> Void)?
    private var onUpdate: (([FavoriteMediaItem.ID]) -> Void)?

    private var favoriteMediaItemIDs: [FavoriteMediaItem.ID] {
        favoriteMediaItems.map { $0.id }
    }

    // MARK: Lifecycle

    init(
        movieDatabaseAPIClient: MovieDatabaseAPIClient = MovieDatabaseAPIClient(apiKey: Secrets.apiKey),
        sortOption: FavoriteService.SortOption = .registrationDate,
        query: String  = "",
        favoriteMediaItems: [FavoriteMediaItem] = []
    ) {
        self.movieDatabaseAPIClient = movieDatabaseAPIClient
        self.sortOption = sortOption
        self.query = query
        self.favoriteMediaItems = favoriteMediaItems
    }
}

// MARK: - Methods

extension FavoriteViewModel {
    enum Action {
        case fetchFavoriteMediaItems(sortOption: FavoriteService.SortOption? = nil, query: String? = nil)
        case deleteFavoriteMediaItem(FavoriteMediaItem.ID)
    }

    func action(_ action: Action) {
        switch action {
        case .fetchFavoriteMediaItems(let sortOption, let query):
            fetchFavoriteMediaItems(sortOption: sortOption, query: query)
        case .deleteFavoriteMediaItem(let id):
            deleteFavoriteMediaItem(for: id)
        }
    }

    func favoriteMediaItem(for id: FavoriteMediaItem.ID) -> FavoriteMediaItem? {
        return favoriteMediaItems.first(where: { $0.id == id })
    }

    func mediaDetailViewModel(for id: FavoriteMediaItem.ID) -> MediaDetailViewModel? {
        guard let favoriteItem = favoriteMediaItem(for: id) else { return nil }
        return MediaDetailViewModel(mediaItem: favoriteItem)
    }

    func similarViewModel<T: MediaProtocol>(
        for id: FavoriteMediaItem.ID, type: MovieDatabaseAPI.MediaType?
    ) -> SimilarViewModel<T>? {
        guard let mediaItem = favoriteMediaItem(for: id) else { return nil }
        return SimilarViewModel(mediaItem: mediaItem)
    }

    func image(imageSize: MovieDatabaseURL.ImageSize, imagePath: String?) async -> UIImage? {
        guard let imagePath else { return nil }
        do {
            let image = try await movieDatabaseAPIClient.fetchImage(imageSize: imageSize, imagePath: imagePath)
            return image
        } catch {
            await MainActor.run {
                onError?(error.localizedDescription)
            }
            return nil
        }
    }

    func bind(onError: @escaping (String) -> Void) {
        self.onError = onError
    }

    func bind(onUpdate: @escaping ([FavoriteMediaItem.ID]) -> Void) {
        self.onUpdate = onUpdate
    }

    private func fetchFavoriteMediaItems(sortOption: FavoriteService.SortOption?, query: String?) {
        if let sortOption {
            self.sortOption = sortOption
        }
        do {
            favoriteMediaItems = try favoriteService.fetch(sortOption: self.sortOption, query: query)
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func deleteFavoriteMediaItem(for id: FavoriteMediaItem.ID) {
        do {
            try favoriteService.delete(id)
            favoriteMediaItems.removeAll(where: { $0.id == id })
        } catch {
            onError?(error.localizedDescription)
        }
    }
}
