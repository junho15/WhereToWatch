import UIKit

final class MediaDetailViewController: UICollectionViewController {

    // MARK: Properties

    private let mediaDetailViewModel: MediaDetailViewModel
    private var dataSource: DataSource?

    // MARK: View Lifecycle

    init(mediaDetailViewModel: MediaDetailViewModel) {
        self.mediaDetailViewModel = mediaDetailViewModel

        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = Constants.collectionViewBackgroundColor
        configuration.headerMode = .firstItemInSection
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
        configureNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateSnapshot()
    }
}

// MARK: - Methods

extension MediaDetailViewController {
    private func configureDataSource() {
        let textCellRegistration = UICollectionView.CellRegistration(handler: textCellRegistrationHandler)
        let posterCellRegistration = UICollectionView.CellRegistration(handler: posterCellRegistrationHandler)
        let watchProviderCellRegistration = UICollectionView.CellRegistration(
            handler: watchProviderCellRegistrationHandler
        )
        let imageCellRegistration = UICollectionView.CellRegistration(handler: imageCellRegistrationHandler)
        dataSource = DataSource(
            collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
                switch itemIdentifier {
                case .header, .text:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: textCellRegistration, for: indexPath, item: itemIdentifier
                    )
                case .poster:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: posterCellRegistration, for: indexPath, item: itemIdentifier
                    )
                case .watchProvider:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: watchProviderCellRegistration, for: indexPath, item: itemIdentifier)
                case .image:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: imageCellRegistration, for: indexPath, item: itemIdentifier
                    )
                }
            }
        )
    }

    private func configureNavigationItem() {
        let mediaItem = mediaDetailViewModel.mediaItemDetail()
        navigationItem.title = mediaItem.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close, primaryAction: UIAction(handler: { [weak self] _ in
                guard let self else { return }
                dismiss(animated: true)
            })
        )
    }
}

// MARK: - DataSource

extension MediaDetailViewController {
    enum Section: Hashable {
        case poster
        case watchProvider(WatchProviderType)
        case overView
        case justWatch
    }

    enum Row: Hashable {
        case header(String?)
        case text(String?)
        case poster(UIImage?)
        case watchProvider(type: WatchProviderType, watchProvider: WatchProvider)
        case image(UIImage?)
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Row>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Row>

    private func textCellRegistrationHandler(
        cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: Row
    ) {
        var contentConfiguration = cell.defaultContentConfiguration()
        if case .text(let text) = itemIdentifier {
            contentConfiguration.text = text
        } else if case .header(let title) = itemIdentifier,
                  let title {
            contentConfiguration.attributedText = AttributedStringMaker.mediaDetailHeader(title: title).attributedString
        }
        cell.contentConfiguration = contentConfiguration
    }

    private func posterCellRegistrationHandler(
        cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: Row
    ) {
        guard case .poster(let image) = itemIdentifier else { return }
        var contentConfiguration = cell.posterContentView()
        contentConfiguration.image = image
        cell.contentConfiguration = contentConfiguration
    }

    private func watchProviderCellRegistrationHandler(
        cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: Row
    ) {
        guard case .watchProvider(_, let watchProvider) = itemIdentifier else {
            return
        }
        var contentConfiguration = cell.defaultContentConfiguration()
        if let name = watchProvider.providerName {
            contentConfiguration.attributedText = AttributedStringMaker.watchProviderName(name: name).attributedString
        }
        contentConfiguration.image = Constants.emptyLogoImage?.resized(targetSize: Constants.watchProviderLogoSize)
        cell.contentConfiguration = contentConfiguration
        Task {
            if let logoPath = watchProvider.logoPath {
                let image = await mediaDetailViewModel.image(imageSize: .original, imagePath: logoPath)
                if indexPath == collectionView.indexPath(for: cell) {
                    await MainActor.run {
                        contentConfiguration.image = image?.resized(targetSize: Constants.watchProviderLogoSize)
                        cell.contentConfiguration = contentConfiguration
                    }
                }
            }
        }
    }

    private func imageCellRegistrationHandler(
        cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: Row
    ) {
        guard case .image(let image) = itemIdentifier else { return }
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.image = image
        cell.contentConfiguration = contentConfiguration
    }

    private func updateSnapshot() {
        Task {
            let mediaItem = mediaDetailViewModel.mediaItemDetail()
            var snapShot = Snapshot()
            var image: UIImage?
            if let posterPath = mediaItem.posterPath {
                image = await mediaDetailViewModel.image(imageSize: .w500, imagePath: posterPath)
            } else {
                image = Constants.emptyPosterImage
            }
            snapShot.appendSections([.poster])
            snapShot.appendItems([.poster(image)], toSection: .poster)
            if let watchProviderList = await mediaDetailViewModel.fetchWatchProviderList() {
                WatchProviderType.allCases.forEach { type in
                    if let result = watchProviderList.results[type] {
                        snapShot.appendSections([.watchProvider(type)])
                        snapShot.appendItems([.header(type.title)], toSection: .watchProvider(type))
                        snapShot.appendItems(
                            result.map { .watchProvider(type: type, watchProvider: $0) },
                            toSection: .watchProvider(type)
                        )
                    }
                }
                snapShot.appendSections([.justWatch])
                snapShot.appendItems(
                    [.image(Constants.justWatchLogoImage?.resized(targetSize: Constants.justWatchLogoSize))],
                    toSection: .justWatch
                )
            }
            snapShot.appendSections([.overView])
            snapShot.appendItems([.header(Constants.overViewHeader), .text(mediaItem.overView)], toSection: .overView)
            await MainActor.run {
                dataSource?.apply(snapShot)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension MediaDetailViewController {
    override func collectionView(
        _ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath
    ) -> Bool {
        return false
    }
}

// MARK: - Constants

extension MediaDetailViewController {
    private enum Constants {
        static let collectionViewBackgroundColor = UIColor.systemGray6
        static let emptyPosterImage = UIImage(named: "Empty")
        static let emptyLogoImage = UIImage(named: "Empty")
        static let justWatchLogoImage = UIImage(named: "JustWatch")
        static let genreHeader = NSLocalizedString("GENRE_HEADER", comment: "Genre Header")
        static let overViewHeader = NSLocalizedString("OVERVIEW_HEADER", comment: "Overview Header")
        static let watchProviderLogoSize = CGSize(width: 40, height: 40)
        static let justWatchLogoSize = CGSize(width: 100, height: 100)
    }
}