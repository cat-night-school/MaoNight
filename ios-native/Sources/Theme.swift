import UIKit

/// 猫夜原生 iOS 版配色：深色玻璃 + 蓝色强调，和 Windows 原生版同一套视觉。
enum Theme {
    static let bg = UIColor(red: 0.055, green: 0.06, blue: 0.085, alpha: 1)
    static let bg2 = UIColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1)
    static let card = UIColor(white: 1.0, alpha: 0.06)
    static let cardHot = UIColor(white: 1.0, alpha: 0.12)
    static let stroke = UIColor(white: 1.0, alpha: 0.12)
    static let strokeHot = UIColor(white: 1.0, alpha: 0.22)
    static let ink = UIColor(white: 1.0, alpha: 0.95)
    static let muted = UIColor(white: 0.63, alpha: 1.0)
    static let faint = UIColor(white: 0.42, alpha: 1.0)
    static let accent = UIColor(red: 0.18, green: 0.35, blue: 0.78, alpha: 1)
    static let accentLight = UIColor(red: 0.44, green: 0.61, blue: 0.94, alpha: 1)
    static let good = UIColor(red: 0.37, green: 0.88, blue: 0.54, alpha: 1)
    static let warn = UIColor(red: 0.88, green: 0.71, blue: 0.37, alpha: 1)
    static let error = UIColor(red: 0.91, green: 0.49, blue: 0.49, alpha: 1)

    static let radius: CGFloat = 20
    static let radiusSmall: CGFloat = 12
    static let pad: CGFloat = 16

    static func font(_ size: CGFloat, _ bold: Bool = false) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    static func mono(_ size: CGFloat) -> UIFont {
        return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// 深色渐变底
    static func installBackground(_ view: UIView) {
        let g = CAGradientLayer()
        g.colors = [bg.cgColor, bg2.cgColor]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        g.frame = view.bounds
        g.name = "mn-bg"
        view.layer.insertSublayer(g, at: 0)
    }

    static func layoutBackground(_ view: UIView) {
        view.layer.sublayers?.first(where: { $0.name == "mn-bg" })?.frame = view.bounds
    }
}

/// 玻璃卡片：圆角 + 细描边 + 半透明白底。
final class GlassCard: UIView {
    init(radius: CGFloat = Theme.radius) {
        super.init(frame: .zero)
        backgroundColor = Theme.card
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Theme.stroke.cgColor
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }
}

/// 主按钮：蓝色渐变胶囊。
final class AccentButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setTitleColor(.white, for: .normal)
        titleLabel?.font = Theme.font(15, true)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        let g = CAGradientLayer()
        g.colors = [Theme.accentLight.cgColor, Theme.accent.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        g.name = "mn-accent"
        layer.insertSublayer(g, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first(where: { $0.name == "mn-accent" })?.frame = bounds
    }
}

/// 普通玻璃按钮（次要操作）。
final class SoftButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setTitleColor(Theme.ink, for: .normal)
        titleLabel?.font = Theme.font(14)
        backgroundColor = Theme.card
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Theme.stroke.cgColor
    }
}

/// 页面顶部：左上返回 + 居中标题 + 副标题。
final class PageHeader: UIView {
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    init(title: String, subtitle: String, showBack: Bool) {
        super.init(frame: .zero)
        backButton.setTitle("← 返回", for: .normal)
        backButton.setTitleColor(Theme.ink, for: .normal)
        backButton.titleLabel?.font = Theme.font(13)
        backButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        backButton.layer.cornerRadius = 15
        backButton.layer.cornerCurve = .continuous
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = Theme.stroke.cgColor
        backButton.isHidden = !showBack
        addSubview(backButton)

        titleLabel.text = title
        titleLabel.textColor = Theme.ink
        titleLabel.font = Theme.font(20, true)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        subtitleLabel.text = subtitle
        subtitleLabel.textColor = Theme.muted
        subtitleLabel.font = Theme.font(12)
        subtitleLabel.textAlignment = .center
        addSubview(subtitleLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        backButton.frame = CGRect(x: 4, y: (bounds.height - 30) / 2, width: 76, height: 30)
        titleLabel.frame = CGRect(x: 84, y: bounds.height / 2 - 20, width: bounds.width - 168, height: 24)
        subtitleLabel.frame = CGRect(x: 84, y: bounds.height / 2 + 4, width: bounds.width - 168, height: 18)
    }
}
