import UIKit

/// 尚未原生重写的页面：给一个真正的原生过渡页（不加载网页），说明当前进度。
final class ComingSoonViewController: UIViewController {
    private let header: PageHeader
    private let card = GlassCard()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let noteLabel = UILabel()
    private let progressLabel = UILabel()

    init(title: String) {
        header = PageHeader(title: title, subtitle: "原生版", showBack: true, icon: "🐾")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        header.backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        view.addSubview(header)
        view.addSubview(card)

        iconLabel.text = "🐾"
        iconLabel.font = Theme.font(34)
        iconLabel.textAlignment = .center
        card.addSubview(iconLabel)

        titleLabel.text = header.titleLabel.text ?? ""
        titleLabel.textColor = Theme.ink
        titleLabel.font = Theme.font(18, true)
        titleLabel.textAlignment = .center
        card.addSubview(titleLabel)

        noteLabel.text = "这个页面正在用 Swift 原生重写，当前 IPA 里不包含任何网页内容。"
        noteLabel.textColor = Theme.muted
        noteLabel.font = Theme.font(13)
        noteLabel.numberOfLines = 0
        noteLabel.textAlignment = .center
        card.addSubview(noteLabel)

        progressLabel.text = "已经原生接好的：登录 / 首页 / 棋类训练五步 / 五子棋对局\n其余页面按批次继续接入。"
        progressLabel.textColor = Theme.faint
        progressLabel.font = Theme.font(12)
        progressLabel.numberOfLines = 0
        progressLabel.textAlignment = .center
        card.addSubview(progressLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        header.frame = CGRect(x: 0, y: safeTop + 4, width: w, height: 92)
        let cardW = min(w - 40, 460)
        card.frame = CGRect(x: (w - cardW) / 2, y: header.frame.maxY + 30, width: cardW, height: 300)
        iconLabel.frame = CGRect(x: 0, y: 30, width: cardW, height: 50)
        titleLabel.frame = CGRect(x: 20, y: 88, width: cardW - 40, height: 26)
        noteLabel.frame = CGRect(x: 24, y: 128, width: cardW - 48, height: 60)
        progressLabel.frame = CGRect(x: 24, y: 200, width: cardW - 48, height: 80)
    }

    @objc private func tapBack() {
        navigationController?.popViewController(animated: true)
    }
}
