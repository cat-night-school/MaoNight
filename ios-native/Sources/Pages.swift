import UIKit

// MARK: - 页面基类

/// 所有原生页面的基类：照片背景 + 居中页头 + 可滚动内容。
class MnPage: UIViewController {
    let header: PageHeader
    let scroll = UIScrollView()
    let stack = UIStackView()
    private var scrollTop: NSLayoutConstraint?
    private var scrollHeight: NSLayoutConstraint?

    init(title: String, subtitle: String, icon: String) {
        header = PageHeader(title: title, subtitle: subtitle, showBack: true, icon: icon)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        view.addSubview(header)
        header.backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)

        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollHeight = scroll.heightAnchor.constraint(equalToConstant: view.bounds.height)
        scrollHeight?.isActive = true
        scrollTop = scroll.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
        scrollTop?.isActive = true

        stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16).isActive = true
        stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16).isActive = true
        stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8).isActive = true
        stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -30).isActive = true
        stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let safeTop = view.safeAreaInsets.top
        header.frame = CGRect(x: 0, y: safeTop + 4, width: view.bounds.width, height: 92)
        scrollTop?.constant = header.frame.maxY + 6
        scrollHeight?.constant = view.bounds.height - header.frame.maxY - 6
    }

    @objc func tapBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: 内容块

    func add(_ b: UIView, gap: CGFloat = 10) {
        if gap != 10 { stack.setCustomSpacing(gap, after: stack.arrangedSubviews.last ?? b) }
        stack.addArrangedSubview(b)
    }

    @discardableResult
    func section(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = Theme.ink
        l.font = Theme.font(15, true)
        let wrap = UIView()
        wrap.addSubview(l)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 2).isActive = true
        l.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 8).isActive = true
        l.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: 0).isActive = true
        add(wrap)
        return l
    }

    func paragraph(_ text: String) {
        let card = GlassCard(fill: Theme.card)
        let l = UILabel()
        l.text = text
        l.textColor = Theme.muted
        l.font = Theme.font(13)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(l)
        l.topAnchor.constraint(equalTo: card.topAnchor, constant: 14).isActive = true
        l.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14).isActive = true
        l.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
        l.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14).isActive = true
        add(card)
    }

    func kv(_ key: String, _ value: String) {
        let card = GlassCard(radius: 14, fill: Theme.card)
        let k = UILabel()
        k.text = key
        k.textColor = Theme.muted
        k.font = Theme.font(13)
        let v = UILabel()
        v.text = value
        v.textColor = Theme.ink
        v.font = Theme.font(14, true)
        v.textAlignment = .right
        k.translatesAutoresizingMaskIntoConstraints = false
        v.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(k)
        card.addSubview(v)
        k.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
        k.topAnchor.constraint(equalTo: card.topAnchor, constant: 12).isActive = true
        k.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12).isActive = true
        v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14).isActive = true
        v.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        v.leadingAnchor.constraint(greaterThanOrEqualTo: k.trailingAnchor, constant: 12).isActive = true
        add(card, gap: 8)
    }

    func primaryButton(_ title: String, action: Selector) {
        let b = AccentButton()
        b.setTitle(title, for: .normal)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        add(b, gap: 12)
    }

    func softButton(_ title: String, action: Selector) {
        let b = SoftButton()
        b.setTitle(title, for: .normal)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        add(b, gap: 10)
    }

    /// 可点的一行（标题 + 副标题 + 右侧箭头）
    func linkRow(_ title: String, _ subtitle: String, action: Selector) {
        let card = GlassCard(radius: 16, fill: Theme.card)
        let t = UILabel()
        t.text = title
        t.textColor = Theme.ink
        t.font = Theme.font(15, true)
        let s = UILabel()
        s.text = subtitle
        s.textColor = Theme.muted
        s.font = Theme.font(12)
        s.numberOfLines = 2
        let chev = UILabel()
        chev.text = "›"
        chev.textColor = Theme.faint
        chev.font = Theme.font(22)
        [t, s, chev].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        t.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
        t.topAnchor.constraint(equalTo: card.topAnchor, constant: 12).isActive = true
        t.trailingAnchor.constraint(lessThanOrEqualTo: chev.leadingAnchor, constant: -8).isActive = true
        s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
        s.trailingAnchor.constraint(equalTo: chev.leadingAnchor, constant: -8).isActive = true
        s.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 3).isActive = true
        s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12).isActive = true
        chev.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12).isActive = true
        chev.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        let tap = TapTarget(action: action, target: self)
        card.addGestureRecognizer(tap.gesture)
        add(card, gap: 8)
    }

    func textField(placeholder: String) -> UITextField {
        let f = UITextField()
        f.backgroundColor = UIColor(white: 0, alpha: 0.3)
        f.textColor = Theme.ink
        f.font = Theme.font(14)
        f.layer.cornerRadius = Theme.radiusInner
        f.layer.cornerCurve = .continuous
        f.layer.borderWidth = 1
        f.layer.borderColor = Theme.strokeSoft.cgColor
        f.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: Theme.faint])
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        f.leftView = pad
        f.leftViewMode = .always
        f.heightAnchor.constraint(equalToConstant: 46).isActive = true
        add(f, gap: 8)
        return f
    }
}

/// 点击转发的 UITapGestureRecognizer 包装（避免 selector 参数不匹配）。
final class TapTarget: NSObject {
    let action: Selector
    weak var target: AnyObject?
    lazy var gesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(fire))
        return g
    }()

    init(action: Selector, target: AnyObject) {
        self.action = action
        self.target = target
    }

    @objc private func fire() {
        _ = target?.perform(action)
    }
}

// MARK: - 页面工厂

enum Pages {
    static func build(key: String, title: String) -> UIViewController {
        switch key {
        case "social.chat": return ChatRoomPage()
        case "social.rank": return RankPage()
        case "play.season-race": return SeasonPage(race: true)
        case "play.season": return SeasonPage(race: false)
        case "social.friends": return FriendsPage()
        case "social.dm": return DMPage()
        case "account.profile": return ProfilePage()
        case "social.board": return BoardPage()
        case "social.online-list": return OnlinePage()
        case "account.shop": return ShopPage()
        case "account.redeem": return RedeemPage()
        case "account.fish": return PointsPage()
        case "account.feed": return FeedPage()
        case "tools.tools": return ToolsPage()
        case "tools.network": return NetworkPage()
        case "tools.security": return SecurityPage()
        case "tools.download": return DownloadPage()
        case "account.setting": return SettingsPage()
        case "admin.log": return AdminLogPage()
        case "account.recharge": return InfoPage(title: title, icon: "💰", subtitle: "充值猫币", lines: RechargeText.lines)
        case "account.recharge-lv": return InfoPage(title: title, icon: "📈", subtitle: "累充等级", lines: RechargeText.levelLines)
        case "account.member": return MemberPage()
        case "admin.customize": return InfoPage(title: title, icon: "🧬", subtitle: "越狱定制", lines: InfoText.customize)
        case "admin.trollstore": return InfoPage(title: title, icon: "🧩", subtitle: "巨魔商店", lines: InfoText.trollstore)
        case "social.fortune": return FortunePage()
        case "social.story": return InfoPage(title: title, icon: "📖", subtitle: "网站故事", lines: InfoText.story)
        case "account.terms": return InfoPage(title: title, icon: "📜", subtitle: "协议中心", lines: InfoText.terms)
        case "social.tutorial": return InfoPage(title: title, icon: "📚", subtitle: "新手教程", lines: InfoText.tutorial)
        case "social.contact": return InfoPage(title: title, icon: "📞", subtitle: "联系我们", lines: InfoText.contact)
        default: return InfoPage(title: title, icon: "🐾", subtitle: "原生版", lines: ["这个页面正在继续接入中。"])
        }
    }
}

// MARK: - 通用信息页

struct RechargeText {
    static let lines: [String] = [
        "【充值比例】",
        "1 元 = 100 猫币，充值后即时到账。",
        "",
        "【可选档位】",
        "6 元 / 600 猫币\n30 元 / 3000 猫币\n68 元 / 6800 猫币\n128 元 / 12800 猫币\n328 元 / 32800 猫币\n648 元 / 64800 猫币",
        "",
        "【说明】",
        "网页端和 Windows 端支持扫码充值；iOS 原生版先展示档位，支付通道接入后会直接跳转。充值问题联系管理员。"
    ]
    static let levelLines: [String] = [
        "【累充等级】",
        "累计充值金额决定等级，等级越高福利越多。",
        "",
        "Lv1 累充 10 元 · 每日签到 +10 猫币",
        "Lv2 累充 50 元 · 专属头衔「小富喵」",
        "Lv3 累充 200 元 · 商城 95 折",
        "Lv4 累充 500 元 · 专属头像框",
        "Lv5 累充 1000 元 · 会员月卡赠送",
        "",
        "等级在「个人设置」里可以查看当前进度。"
    ]
}

enum InfoText {
    static let customize: [String] = [
        "【越狱定制是什么】",
        "给越狱设备（Dopamine / TrollStore）定制猫夜 IPA：换图标、换内部背景、改标题和作者。",
        "",
        "【iOS 原生版怎么用】",
        "原生版本身已经是独立 App，不需要再定制 IPA。这个页面在 Windows 原生版里完成定制流程；手机上可以查看说明，或者去网页端上传图片下单。",
        "",
        "【注意】",
        "定制产物只用于个人设备，请勿分发。"
    ]
    static let trollstore: [String] = [
        "【巨魔商店是什么】",
        "TrollStore 是永久安装未签名 IPA 的工具，不需要 Apple ID 签名。",
        "",
        "【适用条件】",
        "iOS 14.0 – 17.0（部分版本有内核漏洞支持），具体看设备型号和系统版本。",
        "你的设备是 iOS 18.6.2，巨魔商店不支持，需要用 Sideloadly / AltStore 签名安装。",
        "",
        "【下载】",
        "https://github.com/opa334/TrollStore/releases"
    ]
    static let story: [String] = [
        "【网站故事】",
        "猫夜最初是一个给猫猫们交流的小站：聊天室、棋盘、岛屿和小游戏。后来搬到 Windows 原生客户端，所有页面离线可用，数据走猫夜自己的后端。",
        "",
        "【现在】",
        "同一个账号可以在 Windows、网页和 iOS 原生版之间登录，猫币、头衔、聊天记录都存在云端。"
    ]
    static let terms: [String] = [
        "【用户协议】",
        "1. 本应用仅供个人学习交流使用，禁止用于任何违法用途。",
        "2. 不得利用本应用传播违法、侵权或恶意内容。",
        "3. 账号仅限本人使用，禁止出售、出借或共享。",
        "4. 恶意攻击、刷屏、作弊等行为会被封禁账号。",
        "5. 因使用本应用产生的任何后果由使用者自行承担。",
        "",
        "【隐私说明】",
        "登录信息（账号、密码哈希）保存在猫夜后端；设备指纹仅用于安全风控；不会出售或分享给第三方。"
    ]
    static let tutorial: [String] = [
        "【新手三步】",
        "1. 登录：用你的猫夜账号登录，没有账号先在网页端注册。",
        "2. 棋盘：首页 → 棋类训练 → 选棋种 → 人机/双人/联机 → 难度 → 先手 → 开始。",
        "3. 资源：猫币用于商城，小鱼干用于兑换和喂猫；每日签到、赛季、任务都能拿。",
        "",
        "【常用入口】",
        "· 聊天室：全站聊天，支持自动刷新\n· 排行榜：猫币/连胜/等级\n· 喵喵岛屿：盖房子、放猫、攒资源\n· 商城：买头衔和道具\n· 赛季：报名比赛、领奖励",
        "",
        "【遇到问题】",
        "先在「个人设置 → 刷新资料」重试；仍然不行就联系管理员。"
    ]
    static let contact: [String] = [
        "【联系我们】",
        "管理员：王关喆（admin）",
        "邮箱：maonight@example.com",
        "QQ 群：见网页端「联系我们」页",
        "",
        "【反馈建议】",
        "App 内问题请附：设备型号、iOS 版本、复现步骤、截图。"
    ]
}

class InfoPage: MnPage {
    private let lines: [String]

    init(title: String, icon: String, subtitle: String, lines: [String]) {
        self.lines = lines
        super.init(title: title, subtitle: subtitle, icon: icon)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        for line in lines {
            if line.hasPrefix("【") {
                section(line.replacingOccurrences(of: "【", with: "").replacingOccurrences(of: "】", with: ""))
            } else if line.isEmpty {
                let spacer = UIView()
                spacer.heightAnchor.constraint(equalToConstant: 2).isActive = true
                add(spacer, gap: 2)
            } else {
                paragraph(line)
            }
        }
    }
}
