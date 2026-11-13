import UIKit

/// 猫夜原生 iOS 版配色：沿用 Windows 原生版 —— 深色照片背景 + 玻璃卡片 + 蓝色强调。
enum Theme {
    static let bg = UIColor(red: 0.055, green: 0.06, blue: 0.085, alpha: 1)
    static let bg2 = UIColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1)
    static let card = UIColor(white: 1.0, alpha: 0.085)
    static let cardHot = UIColor(white: 1.0, alpha: 0.16)
    static let innerCard = UIColor(white: 1.0, alpha: 0.10)
    static let stroke = UIColor(white: 1.0, alpha: 0.16)
    static let strokeSoft = UIColor(white: 1.0, alpha: 0.10)
    static let ink = UIColor(white: 1.0, alpha: 0.96)
    static let muted = UIColor(white: 0.72, alpha: 1.0)
    static let faint = UIColor(white: 0.48, alpha: 1.0)
    static let accent = UIColor(red: 0.18, green: 0.35, blue: 0.80, alpha: 1)
    static let accentLight = UIColor(red: 0.44, green: 0.61, blue: 0.96, alpha: 1)
    static let badgeBg = UIColor(red: 0.20, green: 0.34, blue: 0.72, alpha: 0.75)
    static let good = UIColor(red: 0.37, green: 0.88, blue: 0.54, alpha: 1)
    static let warn = UIColor(red: 0.88, green: 0.71, blue: 0.37, alpha: 1)
    static let error = UIColor(red: 0.91, green: 0.49, blue: 0.49, alpha: 1)

    static let radiusCard: CGFloat = 24
    static let radiusInner: CGFloat = 16
    static let radiusItem: CGFloat = 14
    static let pad: CGFloat = 16

    static func font(_ size: CGFloat, _ bold: Bool = false) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    static func mono(_ size: CGFloat) -> UIFont {
        return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// 照片背景（和 Windows 原生版一样：猫片 + 深色薄雾），没有图片时退回深色渐变。
    static func installBackground(_ view: UIView) {
        let holder = UIView(frame: view.bounds)
        holder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        holder.isUserInteractionEnabled = false
        holder.tag = 90901
        if let img = UIImage(named: "bg_home") ?? UIImage(named: "bg_home.jpg") {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.frame = holder.bounds
            iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            holder.addSubview(iv)
        }
        let veil = GradientVeil()
        veil.frame = holder.bounds
        veil.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        holder.addSubview(veil)
        view.insertSubview(holder, at: 0)
    }

    static func layoutBackground(_ view: UIView) {
        if let holder = view.viewWithTag(90901) {
            holder.frame = view.bounds
        }
    }
}

/// 背景薄雾：上方稍亮、下方更暗，保证文字可读又保留猫片的氛围。
final class GradientVeil: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let colors = [
            UIColor(red: 0.03, green: 0.035, blue: 0.05, alpha: 0.62).cgColor,
            UIColor(red: 0.02, green: 0.025, blue: 0.04, alpha: 0.82).cgColor,
            UIColor(red: 0.01, green: 0.015, blue: 0.025, alpha: 0.92).cgColor
        ]
        let locs: [CGFloat] = [0.0, 0.55, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray, locations: locs) {
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: bounds.midX, y: 0),
                                   end: CGPoint(x: bounds.midX, y: bounds.height),
                                   options: [])
        }
    }
}

/// 玻璃卡片：圆角 + 细描边 + 半透明白底（和 Windows 的卡片同一套参数）。
final class GlassCard: UIView {
    init(radius: CGFloat = Theme.radiusCard, fill: UIColor = Theme.card) {
        super.init(frame: .zero)
        backgroundColor = fill
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
        titleLabel?.font = Theme.font(16, true)
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
        layer.cornerRadius = Theme.radiusItem
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Theme.stroke.cgColor
    }
}

/// 页面顶部：左上返回 + 居中图标/标题/副标题（和 Windows 原版的页头一致）。
final class PageHeader: UIView {
    let backButton = UIButton(type: .system)
    let iconLabel = UILabel()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    init(title: String, subtitle: String, showBack: Bool, icon: String = "") {
        super.init(frame: .zero)
        backButton.setTitle("← 返回", for: .normal)
        backButton.setTitleColor(Theme.ink, for: .normal)
        backButton.titleLabel?.font = Theme.font(13)
        backButton.backgroundColor = UIColor(white: 1, alpha: 0.10)
        backButton.layer.cornerRadius = 15
        backButton.layer.cornerCurve = .continuous
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = Theme.strokeSoft.cgColor
        backButton.isHidden = !showBack
        addSubview(backButton)

        iconLabel.text = icon
        iconLabel.font = Theme.font(24)
        iconLabel.textAlignment = .center
        addSubview(iconLabel)

        titleLabel.text = title
        titleLabel.textColor = Theme.ink
        titleLabel.font = Theme.font(21, true)
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
        backButton.frame = CGRect(x: 8, y: (bounds.height - 30) / 2, width: 78, height: 30)
        let centerW = bounds.width - 180
        iconLabel.frame = CGRect(x: 90, y: 2, width: centerW, height: 26)
        titleLabel.frame = CGRect(x: 90, y: 26, width: centerW, height: 26)
        subtitleLabel.frame = CGRect(x: 90, y: 52, width: centerW, height: 18)
    }
}
