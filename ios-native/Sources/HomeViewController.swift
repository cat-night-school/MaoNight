import UIKit

/// 首页：和 Windows 原生版同一套结构 —— 顶栏「首页」、欢迎语、用户卡（头像/昵称/头衔/猫币/小鱼干/连胜/进度/ID）、31 项功能菜单。
final class HomeViewController: UIViewController {
    private let scroll = UIScrollView()
    private let content = UIView()
    private let barTitle = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let welcome = UILabel()
    private let card = GlassCard()

    private let avatarRing = UIView()
    private let avatar = UILabel()
    private let avatarYear = UILabel()
    private let nick = UILabel()
    private let badge = UILabel()
    private let shortId = UILabel()
    private let statCards = [GlassCard(fill: Theme.innerCard), GlassCard(fill: Theme.innerCard), GlassCard(fill: Theme.innerCard)]
    private let statValues = [UILabel(), UILabel(), UILabel()]
    private let statNames = [UILabel(), UILabel(), UILabel()]
    private let rankLabel = UILabel()
    private let rankBar = UIView()
    private let rankFill = UIView()
    private let idRow = GlassCard(fill: Theme.innerCard)
    private let idTitle = UILabel()
    private let idValue = UILabel()

    private let sectionTitle = UILabel()
    private let sectionBadge = UILabel()
    private let grid = UIView()
    private var gridButtons: [UIButton] = []

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
        barTitle.font = Theme.font(24, true)
        view.addSubview(barTitle)

        logoutButton.setTitle("退出", for: .normal)
        logoutButton.setTitleColor(Theme.ink, for: .normal)
        logoutButton.titleLabel?.font = Theme.font(13)
        logoutButton.backgroundColor = UIColor(white: 1, alpha: 0.10)
        logoutButton.layer.cornerRadius = 15
        logoutButton.layer.cornerCurve = .continuous
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = Theme.strokeSoft.cgColor
        logoutButton.addTarget(self, action: #selector(tapLogout), for: .touchUpInside)
        view.addSubview(logoutButton)

        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.addSubview(content)

        welcome.text = "欢迎回来"
        welcome.textColor = Theme.ink
        welcome.font = Theme.font(20, true)
        content.addSubview(welcome)

        content.addSubview(card)

        // 头像：白圈 + 猫 + 年份（照搬 Windows 版的头像样式）
        avatarRing.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1)
        avatarRing.layer.cornerRadius = 32
        avatarRing.layer.cornerCurve = .continuous
        avatarRing.layer.borderWidth = 2
        avatarRing.layer.borderColor = UIColor(white: 1, alpha: 0.55).cgColor
        card.addSubview(avatarRing)
        avatar.text = "🐱"
        avatar.font = Theme.font(26)
        avatar.textAlignment = .center
        avatarRing.addSubview(avatar)
        avatarYear.text = "2026"
        avatarYear.textColor = UIColor(red: 0.45, green: 0.40, blue: 0.34, alpha: 1)
        avatarYear.font = Theme.font(8, true)
        avatarYear.textAlignment = .center
        avatarRing.addSubview(avatarYear)

        nick.textColor = Theme.ink
        nick.font = Theme.font(23, true)
        card.addSubview(nick)

        badge.textColor = UIColor(red: 0.80, green: 0.86, blue: 1, alpha: 1)
        badge.font = Theme.font(11, true)
        badge.textAlignment = .center
        badge.backgroundColor = Theme.badgeBg
        badge.layer.cornerRadius = 11
        badge.layer.cornerCurve = .continuous
        badge.layer.masksToBounds = true
        card.addSubview(badge)

        shortId.textColor = Theme.faint
        shortId.font = Theme.font(13)
        card.addSubview(shortId)

        for i in 0..<3 {
            card.addSubview(statCards[i])
            let v = statValues[i]
            v.textColor = Theme.ink
            v.font = Theme.font(22, true)
            v.textAlignment = .center
            statCards[i].addSubview(v)
            let n = statNames[i]
            n.textColor = Theme.faint
            n.font = Theme.font(11)
            n.textAlignment = .center
            statCards[i].addSubview(n)
        }
        statNames[0].text = "猫币"
        statNames[1].text = "小鱼干"
        statNames[2].text = "连胜"

        rankLabel.textColor = Theme.muted
        rankLabel.font = Theme.font(13)
        card.addSubview(rankLabel)

        rankBar.backgroundColor = UIColor(white: 1, alpha: 0.12)
        rankBar.layer.cornerRadius = 4
        rankBar.layer.masksToBounds = true
        card.addSubview(rankBar)
        rankFill.backgroundColor = Theme.accentLight
        rankFill.layer.cornerRadius = 4
        rankBar.addSubview(rankFill)

        card.addSubview(idRow)
        idTitle.text = "我的 ID"
        idTitle.textColor = Theme.muted
        idTitle.font = Theme.font(13)
        idRow.addSubview(idTitle)
        idValue.textColor = Theme.ink
        idValue.font = Theme.mono(14)
        idRow.addSubview(idValue)

        sectionTitle.text = "功能菜单"
        sectionTitle.textColor = Theme.ink
        sectionTitle.font = Theme.font(15, true)
        content.addSubview(sectionTitle)

        sectionBadge.text = "\(menu.count) 项"
        sectionBadge.textColor = Theme.muted
        sectionBadge.font = Theme.font(11)
        sectionBadge.textAlignment = .center
        sectionBadge.backgroundColor = UIColor(white: 1, alpha: 0.10)
        sectionBadge.layer.cornerRadius = 9
        sectionBadge.layer.cornerCurve = .continuous
        sectionBadge.layer.masksToBounds = true
        content.addSubview(sectionBadge)

        content.addSubview(grid)
        for (index, item) in menu.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(item.icon + " " + item.title, for: .normal)
            b.setTitleColor(Theme.ink, for: .normal)
            b.titleLabel?.font = Theme.font(13)
            b.backgroundColor = Theme.card
            b.layer.cornerRadius = Theme.radiusItem
            b.layer.cornerCurve = .continuous
            b.layer.borderWidth = 1
            b.layer.borderColor = Theme.strokeSoft.cgColor
            b.tag = index
            b.addTarget(self, action: #selector(tapMenuItem(_:)), for: .touchUpInside)
            grid.addSubview(b)
            gridButtons.append(b)
        }

        updateProfile()
        Api.refreshProfile { [weak self] _ in
            self?.updateProfile()
        }
    }

    private func updateProfile() {
        let account = AuthStore.account
        let name = account?.nick?.isEmpty == false ? account!.nick! : (account?.loginName.isEmpty == false ? account!.loginName : "本地用户")
        welcome.text = "欢迎回来，" + name
        nick.text = name
        let title = account?.title ?? ""
        badge.text = title.isEmpty ? "玩家" : title
        let acc = account?.loginName ?? ""
        shortId.text = acc.isEmpty ? "" : "@" + acc
        statValues[0].text = "\(account?.coin ?? 0)"
        statValues[1].text = "\(account?.fish ?? 0)"
        statValues[2].text = "0"
        rankLabel.text = "当前：新手"
        idValue.text = acc.isEmpty ? "--------" : acc
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        barTitle.frame = CGRect(x: 20, y: safeTop + 4, width: 160, height: 32)
        logoutButton.frame = CGRect(x: w - 76, y: safeTop + 8, width: 60, height: 30)
        scroll.frame = view.bounds

        var y = safeTop + 50
        welcome.frame = CGRect(x: 18, y: y, width: w - 36, height: 28)
        y += 40

        let cardX: CGFloat = 16
        let cardW = w - 32
        let cardH: CGFloat = 300
        card.frame = CGRect(x: cardX, y: y, width: cardW, height: cardH)
        let cw = cardW

        avatarRing.frame = CGRect(x: 18, y: 18, width: 64, height: 64)
        avatar.frame = CGRect(x: 0, y: 8, width: 64, height: 34)
        avatarYear.frame = CGRect(x: 0, y: 42, width: 64, height: 12)

        nick.font = Theme.font(23, true)
        let nickW = min((nick.text as NSString?)?.size(withAttributes: [.font: nick.font as Any]).width ?? 80, cw - 200)
        nick.frame = CGRect(x: 96, y: 20, width: nickW + 2, height: 30)
        badge.frame = CGRect(x: 96 + nickW + 10, y: 25, width: badgeWidth(), height: 22)
        shortId.frame = CGRect(x: 96, y: 52, width: cw - 120, height: 18)

        let statY: CGFloat = 92
        let gap: CGFloat = 10
        let statW = (cw - 36 - gap * 2) / 3
        for i in 0..<3 {
            statCards[i].frame = CGRect(x: 18 + CGFloat(i) * (statW + gap), y: statY, width: statW, height: 64)
            statValues[i].frame = CGRect(x: 0, y: 10, width: statW, height: 28)
            statNames[i].frame = CGRect(x: 0, y: 40, width: statW, height: 16)
        }
        rankLabel.frame = CGRect(x: 18, y: 172, width: cw - 36, height: 20)
        rankBar.frame = CGRect(x: 18, y: 198, width: cw - 36, height: 8)
        rankFill.frame = CGRect(x: 0, y: 0, width: (cw - 36) * 0.08, height: 8)
        idRow.frame = CGRect(x: 18, y: 220, width: cw - 36, height: 46)
        idTitle.frame = CGRect(x: 14, y: 13, width: 70, height: 20)
        idValue.frame = CGRect(x: 92, y: 12, width: cw - 130, height: 22)
        y = card.frame.maxY + 22

        sectionTitle.frame = CGRect(x: 18, y: y, width: 140, height: 24)
        sectionBadge.frame = CGRect(x: 96, y: y + 2, width: 52, height: 20)
        y += 36

        let columns = 3
        let cellGap: CGFloat = 10
        let cellW = (w - 32 - cellGap * CGFloat(columns - 1)) / CGFloat(columns)
        let cellH: CGFloat = 50
        let rows = (menu.count + columns - 1) / columns
        grid.frame = CGRect(x: 16, y: y, width: w - 32, height: CGFloat(rows) * (cellH + cellGap))
        for (index, sub) in grid.subviews.enumerated() {
            let col = index % columns
            let row = index / columns
            sub.frame = CGRect(x: CGFloat(col) * (cellW + cellGap),
                               y: CGFloat(row) * (cellH + cellGap),
                               width: cellW, height: cellH)
        }
        y = grid.frame.maxY + 26
        content.frame = CGRect(x: 0, y: 0, width: w, height: max(y + safeBottom + 20, view.bounds.height))
        scroll.contentSize = content.frame.size
    }

    private func badgeWidth() -> CGFloat {
        let width = (badge.text as NSString?)?.size(withAttributes: [.font: badge.font as Any]).width ?? 36
        return max(44, width + 18)
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
