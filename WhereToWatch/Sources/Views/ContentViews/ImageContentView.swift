import UIKit

final class ImageContentView: UIView, UIContentView {

    // MARK: Properties

    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration)
        }
    }
    private let imageView = UIImageView()

    // MARK: View Lifecycle

    init(_ configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        backgroundColor = Constants.backgroundColor

        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Methods

extension ImageContentView {
    func configure(_ configuration: UIContentConfiguration) {
        guard let configuration = configuration as? Configuration else { return }
        if let contentMode = configuration.imageViewContentMode {
            imageView.contentMode = contentMode
        }
        imageView.image = configuration.image
    }

    private func configureSubviews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.spacing),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.spacing)
        ])
    }
}

// MARK: - Configuration

extension ImageContentView {
    struct Configuration: UIContentConfiguration {
        var image: UIImage?
        var imageViewContentMode: ContentMode?

        func makeContentView() -> UIView & UIContentView {
            return ImageContentView(self)
        }

        func updated(for state: UIConfigurationState) -> ImageContentView.Configuration {
            return self
        }
    }
}

// MARK: - Constants

extension ImageContentView {
    private enum Constants {
        static let backgroundColor = UIColor.systemGray6
        static let spacing = CGFloat(10)
    }
}

// MARK: - UICollectionViewCell

extension UICollectionViewCell {
    func imageConfiguration() -> ImageContentView.Configuration {
        return ImageContentView.Configuration()
    }
}
