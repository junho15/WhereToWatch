import UIKit

final class PosterContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration)
        }
    }
    private let imageView = UIImageView()

    init(_ configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        backgroundColor = Constants.backgroundColor

        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ configuration: UIContentConfiguration) {
        guard let configuration = configuration as? Configuration else { return }
        imageView.image = configuration.image
    }

    private func configureSubviews() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(
                lessThanOrEqualTo: imageView.heightAnchor, multiplier: Constants.imageViewRatio
            ),
            imageView.heightAnchor.constraint(equalToConstant: Constants.height)
        ])
    }
}

extension PosterContentView {
    struct Configuration: UIContentConfiguration {
        var image: UIImage?

        func makeContentView() -> UIView & UIContentView {
            return PosterContentView(self)
        }

        func updated(for state: UIConfigurationState) -> PosterContentView.Configuration {
            return self
        }
    }
}

extension PosterContentView {
    private enum Constants {
        static let backgroundColor = UIColor.systemGray6
        static let imageViewRatio = 1/1.3
        static let height = CGFloat(200)
    }
}

extension UICollectionViewCell {
    func posterContentView() -> PosterContentView.Configuration {
        return PosterContentView.Configuration()
    }
}