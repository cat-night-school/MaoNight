import UIKit

/// 首页：原生自绘用户卡 + 功能菜单九宫格（31 项），和 Windows 原生版同一套结构。
final class HomeViewController: UIViewController {
    private let scroll = UIScrollView()
    private let content = UIView()
    private let barTitle = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let welcome = UILabel()
    private let card = GlassCard()

    private let avatar = UILabel()
    private let nick = UILabel()
    private let badge = UILabel()
    private let shortId = UILabel()
    private let statValues = [UILabel(), UILabel(), UILabel()]
    private let statNames = [UILabel(), UILabel(), UILabel()]
    private let rankLabel = UILabel()
    private let rankBar = UIView()
    private let rankFill = UIView()
    private let idLabel = UILabel()

    private let sectionTitle = UILabel()
    private let sectionBadge = UILabel()
    private let grid = UIView()

    private struct MenuItem {
        let icon: String
        let title: String
        let key: String
    }

    private let menu: [MenuItem] = [
        MenuItem(icon: "🎮", title: "棋类训练", key: "play.chess"),
        MenuItem(icon: "🏝", title: "喵喵岛屿", key: "play.island"),
        MenuItem(icon: "🏆", title: "连胜排行", key: "social.rank"),
        MenuItem(icon: "📅", title: "赛季进阶赛", key: "play.season-race"),
        MenuItem(icon: "💬", title: "聊天室", key: "social.chat"),
        MenuItem(icon: "👥", title: "好友系统", key: "social.friends"),
        MenuItem(icon: "✉️", title: "私聊", key: "social.dm"),
        MenuItem(icon: "🏠", title: "用户小主页", key: "account.profile"),
        MenuItem(icon: "📝", title: "留言板", key: "social.board"),
        MenuItem(icon: "🟢", title: "在线列表", key: "social.online-list"),
        MenuItem(icon: "🌟", title: "赛季页", key: "play.season"),
        MenuItem(icon: "📀", title: "充值猫币", key: "account.recharge"),
        MenuItem(icon: "📈", title: "累充等级", key: "account.recharge-lv"),
        MenuItem(icon: "🔮", title: "今日运势", key: "social.fortune"),
        MenuItem(icon: "🛍", title: "商城", key: "account.shop"),
        MenuItem(icon: "🧰", title: "实用工具", key: "tools.tools"),
        MenuItem(icon: "💳", title: "猫夜会员", key: "account.member"),
        MenuItem(icon: "🧬", title: "越狱定制", key: "admin.customize"),
        MenuItem(icon: "🧩", title: "巨魔商店", key: "admin.trollstore"),
        MenuItem(icon: "📱", title: "手机下载", key: "tools.download"),
        MenuItem(icon: "🔑", title: "兑换中心", key: "account.redeem"),
        MenuItem(icon: "🐟", title: "兑换小鱼干", key: "account.fish"),
        MenuItem(icon: "🍖", title: "投喂小猫", key: "account.feed"),
        MenuItem(icon: "📋", title: "记录页", key: "admin.log"),
        MenuItem(icon: "📖", title: "网站故事", key: "social.story"),
        MenuItem(icon: "🌐", title: "网络加速", key: "tools.network"),
        MenuItem(icon: "🛡", title: "病毒检测", key: "tools.security"),
        MenuItem(icon: "⚙️", title: "个人设置", key: "account.setting"),
        MenuItem(icon: "📜", title: "协议中心", key: "account.terms"),
        MenuItem(icon: "📚", title: "新手教程", key: "social.tutorial"),
        MenuItem(icon: "📞", title: "联系我们", key: "social.contact")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)

        barTitle.text = "首页"
        barTitle.textColor = Theme.ink
        barTitle.font = Theme.font(16, true)
        view.addSubview(barTitle)

        logoutButton.setTitle("退出", for: .normal)
        logoutButton.setTitleColor(Theme.muted, for: .normal)
        logoutButton.titleLabel?.font = Theme.font(13)
        logoutButton.addTarget(self, action: #selector(tapLogout), for: .touchUpInside)
        view.addSubview(logoutButton)

        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.addSubview(content)

        welcome.text = "欢迎回来"
        welcome.textColor = Theme.ink
        welcome.font = Theme.font(19)
        welcome.textAlignment = .center
        content.addSubview(welcome)

        card.backgroundColor = UIColor(white: 0.05, alpha: 0.55)
        content.addSubview(card)

        avatar.textAlignment = .center
        avatar.textColor = Theme.ink
        avatar.font = Theme.font(22, true)
        avatar.backgroundColor = UIColor(white: 1, alpha: 0.14)
        avatar.layer.cornerRadius = 26
        avatar.layer.cornerCurve = .continuous
        avatar.layer.masksToBounds = true
        card.addSubview(avatar)

        nick.textColor = Theme.ink
        nick.font = Theme.font(19, true)
        card.addSubview(nick)

        badge.textColor = UIColor(red: 0.79, green: 0.86, blue: 1, alpha: 1)
        badge.font = Theme.font(11, true)
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.18, green: 0.35, blue: 0.78, alpha: 0.55)
        badge.layer.cornerRadius = 9
        badge.layer.cornerCurve = .continuous
        badge.layer.masksToBounds = true
        card.addSubview(badge)

        shortId.textColor = Theme.faint
        shortId.font = Theme.font(12)
        card.addSubview(shortId)

        for i in 0..<3 {
            let v = statValues[i]
            v.textColor = Theme.ink
            v.font = Theme.font(18, true)
            v.textAlignment = .center
            card.addSubview(v)
            let n = statNames[i]
            n.textColor = Theme.muted
            n.font = Theme.font(11)
            n.textAlignment = .center
            card.addSubview(n)
        }
        statNames[0].text = "猫币"
        statNames[1].text = "小鱼干"
        statNames[2].text = "连胜"

        rankLabel.textColor = Theme.muted
        rankLabel.font = Theme.font(12)
        card.addSubview(rankLabel)

        rankBar.backgroundColor = UIColor(white: 1, alpha: 0.10)
        rankBar.layer.cornerRadius = 5
        rankBar.layer.masksToBounds = true
        card.addSubview(rankBar)
        rankFill.backgroundColor = Theme.accentLight
        rankFill.layer.cornerRadius = 5
        rankBar.addSubview(rankFill)

        idLabel.textColor = Theme.muted
        idLabel.font = Theme.font(12)
        card.addSubview(idLabel)

        sectionTitle.text = "功能菜单"
        sectionTitle.textColor = Theme.ink
        sectionTitle.font = Theme.font(14, true)
        content.addSubview(sectionTitle)

        sectionBadge.text = "\(menu.count) 项"
        sectionBadge.textColor = Theme.muted
        sectionBadge.font = Theme.font(11)
        sectionBadge.textAlignment = .center
        sectionBadge.backgroundColor = UIColor(white: 1, alpha: 0.06)
        sectionBadge.layer.cornerRadius = 8
        sectionBadge.layer.cornerCurve = .continuous
        sectionBadge.layer.masksToBounds = true
        content.addSubview(sectionBadge)

        content.addSubview(grid)
        for (index, item) in menu.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(item.icon + "  " + item.title, for: .normal)
            b.setTitleColor(Theme.ink, for: .normal)
            b.titleLabel?.font = Theme.font(13)
            b.backgroundColor = Theme.card
            b.layer.cornerRadius = 14
            b.layer.cornerCurve = .continuous
            b.layer.borderWidth = 1
            b.layer.borderColor = Theme.stroke.cgColor
            b.tag = index
            b.addTarget(self, action: #selector(tapMenuItem(_:)), for: .touchUpInside)
            grid.addSubview(b)
        }

        updateProfile()
        Api.refreshProfile { [weak self] _ in
            self?.updateProfile()
        }
    }

    private func updateProfile() {
        let account = AuthStore.account
        let name = account?.nick ?? account?.acc ?? "本地用户"
        welcome.text = "欢迎回来，" + name
        nick.text = name
        badge.text = account?.title?.isEmpty == false ? account?.title : "玩家"
        let acc = account?.acc ?? ""
        shortId.text = acc.isEmpty ? "" : "@" + acc
        statValues[0].text = "\(account?.coin ?? 0)"
        statValues[1].text = "\(account?.fish ?? 0)"
        statValues[2].text = "0"
        avatar.text = String(name.prefix(1))
        rankLabel.text = "当前：新手"
        idLabel.text = "我的 ID    " + (acc.isEmpty ? "--------" : acc)
        setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        barTitle.frame = CGRect(x: 20, y: safeTop + 8, width: 120, height: 24)
        logoutButton.frame = CGRect(x: w - 76, y: safeTop + 8, width: 60, height: 24)
        scroll.frame = view.bounds
        content.frame = CGRect(x: 0, y: 0, width: w, height: 2400)

        var y = safeTop + 44
        welcome.frame = CGRect(x: 20, y: y, width: w - 40, height: 28)
        y += 36

        let cardX: CGFloat = 16
        let cardW = w - 32
        card.frame = CGRect(x: cardX, y: y, width: cardW, height: 250)
        let cw = cardW
        avatar.frame = CGRect(x: 18, y: 16, width: 52, height: 52)
        nick.frame = CGRect(x: 82, y: 18, width: cw - 200, height: 26)
        let nickWidth = (NSString(string: nick.text ?? "")).size(withAttributes: [.font: nick.font as Any]).width
        badge.frame = CGRect(x: 82 + min(nickWidth, cw - 220) + 8, y: 22, width: 78, height: 20)
        shortId.frame = CGRect(x: 82, y: 46, width: cw - 120, height: 18)

        let statY: CGFloat = 86
        let statW = (cw - 48) / 3
        for i in 0..<3 {
            statValues[i].frame = CGRect(x: 18 + CGFloat(i) * statW, y: statY, width: statW, height: 24)
            statNames[i].frame = CGRect(x: 18 + CGFloat(i) * statW, y: statY + 24, width: statW, height: 16)
        }
        rankLabel.frame = CGRect(x: 18, y: 142, width: cw - 36, height: 18)
        rankBar.frame = CGRect(x: 18, y: 166, width: cw - 36, height: 10)
        rankFill.frame = CGRect(x: 0, y: 0, width: (cw - 36) * 0.08, height: 10)
        idLabel.frame = CGRect(x: 18, y: 196, width: cw - 36, height: 20)
        y = card.frame.maxY + 20

        sectionTitle.frame = CGRect(x: 18, y: y, width: 120, height: 22)
        sectionBadge.frame = CGRect(x: 82, y: y + 1, width: 56, height: 20)
        y += 32

        let columns = 3
        let gap: CGFloat = 10
        let cellW = (w - 32 - gap * CGFloat(columns - 1)) / CGFloat(columns)
        let cellH: CGFloat = 46
        let rows = (menu.count + columns - 1) / columns
        grid.frame = CGRect(x: 16, y: y, width: w - 32, height: CGFloat(rows) * (cellH + gap))
        for (index, sub) in grid.subviews.enumerated() {
            let col = index % columns
            let row = index / columns
            sub.frame = CGRect(x: CGFloat(col) * (cellW + gap),
                               y: CGFloat(row) * (cellH + gap),
                               width: cellW, height: cellH)
        }
        y = grid.frame.maxY + 24
        content.frame = CGRect(x: 0, y: 0, width: w, height: max(y + safeBottom + 20, view.bounds.height))
        scroll.contentSize = content.frame.size
    }

    @objc private func tapMenuItem(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < menu.count else { return }
        let item = menu[sender.tag]
        if item.key == "play.chess" {
            navigationController?.pushViewController(ChessFlowViewController(), animated: true)
        } else {
            navigationController?.pushViewController(
                ComingSoonViewController(title: item.title), animated: true)
        }
    }

    @objc private func tapLogout() {
        let sheet = UIAlertController(title: "退出登录", message: "退出后要重新登录才能用云端功能。",
                                      preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        sheet.addAction(UIAlertAction(title: "退出", style: .destructive, handler: { [weak self] _ in
            AuthStore.clear()
            let login = LoginViewController()
            self?.navigationController?.setViewControllers([login], animated: true)
        }))
        present(sheet, animated: true, completion: nil)
    }
}
