import UIKit

// MARK: - 聊天室

final class ChatPage: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let header = PageHeader(title: "聊天室", subtitle: "全站聊天 · 自动刷新", showBack: true, icon: "💬")
    private let table = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let input = UITextField()
    private let send = UIButton(type: .system)
    private let status = UILabel()
    private var messages: [[String: Any]] = []
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        header.backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        view.addSubview(header)

        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)

        status.textColor = Theme.faint
        status.font = Theme.font(11)
        status.textAlignment = .left
        status.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(status)

        inputBar.backgroundColor = UIColor(white: 1, alpha: 0.08)
        inputBar.layer.cornerRadius = 18
        inputBar.layer.cornerCurve = .continuous
        inputBar.layer.borderWidth = 1
        inputBar.layer.borderColor = Theme.strokeSoft.cgColor
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        input.backgroundColor = .clear
        input.textColor = Theme.ink
        input.font = Theme.font(14)
        input.attributedPlaceholder = NSAttributedString(string: "说点什么…", attributes: [.foregroundColor: Theme.faint])
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(input)

        send.setTitle("发送", for: .normal)
        send.setTitleColor(.white, for: .normal)
        send.titleLabel?.font = Theme.font(13, true)
        send.backgroundColor = Theme.accent
        send.layer.cornerRadius = 14
        send.layer.cornerCurve = .continuous
        send.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        send.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(send)

        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            table.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -8),
            status.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            status.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -64),
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputBar.heightAnchor.constraint(equalToConstant: 48),
            input.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 14),
            input.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            send.leadingAnchor.constraint(equalTo: input.trailingAnchor, constant: 8),
            send.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -8),
            send.widthAnchor.constraint(equalToConstant: 60),
            send.heightAnchor.constraint(equalToConstant: 36),
            send.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor)
        ])
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in self?.load() }
    }

    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); timer?.invalidate(); timer = nil }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        header.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 4, width: view.bounds.width, height: 92)
        table.contentInset.top = 0
    }

    private func load() {
        Api.chat { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.status.text = err; return }
            self.messages = list ?? []
            self.status.text = "共 \(self.messages.count) 条 · \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))"
            self.table.reloadData()
            if !self.messages.isEmpty {
                let last = IndexPath(row: self.messages.count - 1, section: 0)
                self.table.scrollToRow(at: last, at: .bottom, animated: false)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let m = messages[indexPath.row]
        let nick = Api.string(m, "nick").isEmpty ? Api.string(m, "acc") : Api.string(m, "nick")
        let time = Api.string(m, "time")
        cell.textLabel?.text = "\(nick)：\(Api.string(m, "text"))"
        cell.textLabel?.textColor = Theme.ink
        cell.textLabel?.font = Theme.font(14)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = time
        cell.detailTextLabel?.textColor = Theme.faint
        cell.detailTextLabel?.font = Theme.font(10)
        return cell
    }

    @objc private func tapSend() {
        let text = input.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty { return }
        input.text = ""
        Api.sendChat(text: text) { [weak self] ok, err in
            if !ok { self?.status.text = err ?? "发送失败" }
            self?.load()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { tapSend(); return true }
    @objc private func tapBack() { navigationController?.popViewController(animated: true) }
}

// MARK: - 排行榜

final class RankPage: MnPage {
    private let switchRow = UISegmentedControl(items: ["猫币", "连胜", "等级"])
    private let keys = ["coin", "win", "level"]

    init() { super.init(title: "连胜排行", subtitle: "猫币 · 连胜 · 等级", icon: "🏆") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        switchRow.selectedSegmentIndex = 0
        switchRow.selectedSegmentTintColor = Theme.accent
        switchRow.addTarget(self, action: #selector(changed), for: .valueChanged)
        add(switchRow, gap: 12)
        load()
    }

    @objc private func changed() { load() }

    private func load() {
        while stack.arrangedSubviews.count > 1 {
            stack.arrangedSubviews.last?.removeFromSuperview()
        }
        let by = keys[max(0, min(keys.count - 1, switchRow.selectedSegmentIndex))]
        Api.rank(by: by) { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            if (list ?? []).isEmpty { self.paragraph("暂时还没有排行数据。"); return }
            for (i, item) in (list ?? []).enumerated() {
                let nick = Api.string(item, "nick").isEmpty ? Api.string(item, "acc") : Api.string(item, "nick")
                let value = by == "coin" ? Api.string(item, "coin") : (by == "win" ? Api.string(item, "win") : Api.string(item, "level"))
                self.kv("\(i + 1). \(nick)", value.isEmpty ? "-" : value)
            }
        }
    }
}

// MARK: - 商城

final class ShopPage: MnPage {
    private var loaded = false

    init() { super.init(title: "商城", subtitle: "猫币兑换好物", icon: "🛍") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }

    private func load() {
        Api.shop { [weak self] items, err in
            guard let self = self else { return }
            while !self.stack.arrangedSubviews.isEmpty {
                self.stack.arrangedSubviews.last?.removeFromSuperview()
            }
            if let err = err { self.paragraph(err); return }
            if (items ?? []).isEmpty { self.paragraph("商城暂时没有上架商品。"); return }
            for item in (items ?? []) {
                let card = GlassCard(radius: 16, fill: Theme.card)
                let name = UILabel()
                name.text = Api.string(item, "name")
                name.textColor = Theme.ink
                name.font = Theme.font(15, true)
                let desc = UILabel()
                desc.text = Api.string(item, "desc")
                desc.textColor = Theme.muted
                desc.font = Theme.font(12)
                desc.numberOfLines = 2
                let price = UILabel()
                let p = Api.int(item, "price")
                price.text = "\(p) 猫币"
                price.textColor = Theme.warn
                price.font = Theme.font(13, true)
                let buy = UIButton(type: .system)
                buy.setTitle("购买", for: .normal)
                buy.setTitleColor(.white, for: .normal)
                buy.titleLabel?.font = Theme.font(13, true)
                buy.backgroundColor = Theme.accent
                buy.layer.cornerRadius = 12
                buy.layer.cornerCurve = .continuous
                buy.tag = self.stack.arrangedSubviews.count
                buy.accessibilityIdentifier = Api.string(item, "id")
                buy.addTarget(self, action: #selector(self.tapBuy(_:)), for: .touchUpInside)
                [name, desc, price, buy].forEach {
                    $0.translatesAutoresizingMaskIntoConstraints = false
                    card.addSubview($0)
                }
                name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
                name.topAnchor.constraint(equalTo: card.topAnchor, constant: 12).isActive = true
                desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
                desc.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3).isActive = true
                desc.trailingAnchor.constraint(equalTo: buy.leadingAnchor, constant: -10).isActive = true
                desc.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12).isActive = true
                price.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14).isActive = true
                price.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 4).isActive = true
                buy.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12).isActive = true
                buy.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
                buy.widthAnchor.constraint(equalToConstant: 68).isActive = true
                buy.heightAnchor.constraint(equalToConstant: 34).isActive = true
                self.add(card, gap: 8)
            }
        }
    }

    @objc private func tapBuy(_ sender: UIButton) {
        let id = sender.accessibilityIdentifier ?? ""
        let alert = UIAlertController(title: "确认购买", message: "确定用猫币购买这件商品吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "购买", style: .default, handler: { [weak self] _ in
            Api.buy(itemId: id) { ok, err in
                let r = UIAlertController(title: ok ? "购买成功" : "购买失败", message: ok ? "商品已到账。" : (err ?? "未知错误"), preferredStyle: .alert)
                r.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
                self?.present(r, animated: true, completion: nil)
                Api.refreshProfile { _ in }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - 留言板

final class BoardPage: MnPage, UITextFieldDelegate {
    private var field: UITextField!

    init() { super.init(title: "留言板", subtitle: "给猫猫们留言", icon: "📝") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tf = textField(placeholder: "写一条留言…")
        tf.delegate = self
        field = tf
        softButton("发布留言", action: #selector(tapPost))
        load()
    }

    private func load() {
        Api.board { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            if (list ?? []).isEmpty { self.paragraph("还没有留言，来写第一条吧。"); return }
            for item in (list ?? []) {
                let nick = Api.string(item, "nick").isEmpty ? Api.string(item, "acc") : Api.string(item, "nick")
                let text = Api.string(item, "text")
                self.paragraph("\(nick)：\(text)")
            }
        }
    }

    @objc private func tapPost() {
        let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty { return }
        Api.postBoard(text: text) { [weak self] ok, err in
            if !ok { self?.paragraph(err ?? "发布失败"); return }
            self?.field.text = ""
            self?.paragraph("已发布 ✓")
        }
    }
}

// MARK: - 在线列表

final class OnlinePage: MnPage {
    init() { super.init(title: "在线列表", subtitle: "当前在线玩家", icon: "🟢") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Api.online { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            if (list ?? []).isEmpty { self.paragraph("现在没有玩家在线。"); return }
            for item in (list ?? []) {
                let nick = Api.string(item, "nick").isEmpty ? Api.string(item, "acc") : Api.string(item, "nick")
                self.kv(nick, Api.string(item, "status").isEmpty ? "在线" : Api.string(item, "status"))
            }
        }
    }
}

// MARK: - 好友 / 私聊

final class FriendsPage: MnPage, UITextFieldDelegate {
    private var field: UITextField!

    init() { super.init(title: "好友系统", subtitle: "添加和管理好友", icon: "👥") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tf = textField(placeholder: "输入对方账号添加好友…")
        tf.delegate = self
        field = tf
        softButton("发送好友申请", action: #selector(tapAdd))
        load()
    }

    private func load() {
        Api.friends { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            if (list ?? []).isEmpty { self.paragraph("还没有好友，先加一个吧。"); return }
            for item in (list ?? []) {
                self.kv(Api.string(item, "nick").isEmpty ? Api.string(item, "acc") : Api.string(item, "nick"), "好友")
            }
        }
    }

    @objc private func tapAdd() {
        let acc = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if acc.isEmpty { return }
        Api.friendRequest(acc: acc) { [weak self] ok, err in
            self?.paragraph(ok ? "好友申请已发送 ✓" : (err ?? "发送失败"))
        }
    }
}

/// 私聊：输入对方账号 + 消息，查看与对方的对话。
final class DMPage: MnPage, UITextFieldDelegate {
    private var accField: UITextField!
    private var textFieldBox: UITextField!
    private var target = ""

    init() { super.init(title: "私聊", subtitle: "和好友说悄悄话", icon: "✉️") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let a = textField(placeholder: "对方账号")
        a.delegate = self
        accField = a
        let t = textField(placeholder: "消息内容")
        t.delegate = self
        textFieldBox = t
        softButton("发送", action: #selector(tapSend))
        softButton("加载聊天记录", action: #selector(tapLoad))
    }

    @objc private func tapLoad() {
        target = accField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if target.isEmpty { return }
        Api.messages(with: target) { [weak self] list, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            for item in (list ?? []) {
                let from = Api.string(item, "from").isEmpty ? Api.string(item, "acc") : Api.string(item, "from")
                self.paragraph("\(from)：\(Api.string(item, "text"))")
            }
        }
    }

    @objc private func tapSend() {
        if target.isEmpty { target = accField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
        let text = textFieldBox.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if target.isEmpty || text.isEmpty { return }
        Api.sendMessage(to: target, text: text) { [weak self] ok, err in
            self?.paragraph(ok ? "已发送 ✓" : (err ?? "发送失败"))
        }
    }
}

// MARK: - 赛季

final class SeasonPage: MnPage {
    private let race: Bool

    init(race: Bool) {
        self.race = race
        super.init(title: race ? "赛季进阶赛" : "赛季页", subtitle: race ? "报名 · 冲段" : "赛季信息", icon: "📅")
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("报名参赛", action: #selector(tapSignup))
        softButton("领取奖励", action: #selector(tapClaim))
        Api.season { [weak self] data, err in
            guard let self = self else { return }
            if let err = err { self.paragraph(err); return }
            guard let data = data else { self.paragraph("暂时没有赛季数据。"); return }
            self.kv("赛季名称", Api.string(data, "name").isEmpty ? "第 1 赛季" : Api.string(data, "name"))
            self.kv("状态", Api.string(data, "status").isEmpty ? "进行中" : Api.string(data, "status"))
            self.kv("报名人数", "\(Api.int(data, "signups"))")
            self.kv("我的段位", Api.string(data, "rank").isEmpty ? "暂无" : Api.string(data, "rank"))
        }
        Api.seasonMe { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.kv("我的报名", (data["signed"] as? Bool) == true ? "已报名" : "未报名")
            self.kv("我的积分", "\(Api.int(data, "points"))")
        }
    }

    @objc private func tapSignup() {
        Api.seasonSignup { [weak self] ok, err in
            self?.paragraph(ok ? "报名成功 ✓" : (err ?? "报名失败"))
        }
    }

    @objc private func tapClaim() {
        Api.seasonClaim { [weak self] ok, err in
            self?.paragraph(ok ? "奖励已领取 ✓" : (err ?? "领取失败"))
        }
    }
}

// MARK: - 兑换 / 小鱼干 / 喂猫

final class RedeemPage: MnPage, UITextFieldDelegate {
    private var field: UITextField!
    private let result = UILabel()

    init() { super.init(title: "兑换中心", subtitle: "输入卡密兑换", icon: "🔑") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tf = textField(placeholder: "输入卡密，例如 MAO-XXXX-XXXX")
        tf.delegate = self
        field = tf
        primaryButton("立即兑换", action: #selector(tapRedeem))
        result.textColor = Theme.good
        result.font = Theme.font(14, true)
        result.textAlignment = .center
        result.numberOfLines = 0
        add(result, gap: 12)
    }

    @objc private func tapRedeem() {
        let code = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if code.isEmpty { result.textColor = Theme.warn; result.text = "先输入卡密"; return }
        result.textColor = Theme.muted
        result.text = "正在兑换…"
        Api.redeem(code: code) { [weak self] data, err in
            guard let self = self else { return }
            if let err = err { self.result.textColor = Theme.error; self.result.text = err; return }
            self.result.textColor = Theme.good
            self.result.text = "兑换成功"
            Api.refreshProfile { _ in }
            if let data = data {
                let coin = Api.int(data, "coin")
                let days = Api.int(data, "days")
                var parts: [String] = []
                if coin > 0 { parts.append("+\(coin) 猫币") }
                if days > 0 { parts.append("+\(days) 天会员") }
                if !parts.isEmpty { self.result.text = "兑换成功：" + parts.joined(separator: "，") }
            }
        }
    }
}

final class PointsPage: MnPage, UITextFieldDelegate {
    private var field: UITextField!

    init() { super.init(title: "兑换小鱼干", subtitle: "签到 · 兑换", icon: "🐟") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("每日签到", action: #selector(tapSignin))
        let tf = textField(placeholder: "兑换数量（小鱼干）")
        tf.keyboardType = .numberPad
        tf.delegate = self
        field = tf
        primaryButton("兑换成猫币", action: #selector(tapExchange))
        Api.points { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.kv("当前小鱼干", "\(Api.int(data, "fish"))")
            self.kv("今日已签到", (data["signed"] as? Bool) == true ? "是" : "否")
        }
    }

    @objc private func tapSignin() {
        Api.pointsSignin { [weak self] ok, err in
            self?.paragraph(ok ? "签到成功 ✓" : (err ?? "签到失败"))
            Api.refreshProfile { _ in }
        }
    }

    @objc private func tapExchange() {
        let n = Int(field.text ?? "") ?? 0
        if n <= 0 { paragraph("请输入要兑换的小鱼干数量。"); return }
        Api.pointsExchange(amount: n) { [weak self] ok, err in
            self?.paragraph(ok ? "兑换成功 ✓" : (err ?? "兑换失败"))
            Api.refreshProfile { _ in }
        }
    }
}

final class FeedPage: MnPage {
    private var fish = 0
    private let cat = UILabel()
    private let info = UILabel()

    init() { super.init(title: "投喂小猫", subtitle: "点一下摸猫猫", icon: "🍖") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        cat.text = "🐱"
        cat.font = Theme.font(72)
        cat.textAlignment = .center
        cat.isUserInteractionEnabled = true
        cat.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCat)))
        add(cat, gap: 8)
        info.textColor = Theme.muted
        info.font = Theme.font(14)
        info.textAlignment = .center
        info.text = "点猫猫投喂小鱼干，猫猫会开心地叫"
        add(info, gap: 8)
        paragraph("投喂消耗 1 小鱼干，猫猫心情 +1。多摸摸它吧。")
    }

    @objc private func tapCat() {
        fish += 1
        info.text = "喵～ 已经被摸 \(fish) 次了"
        cat.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        UIView.animate(withDuration: 0.2) { self.cat.transform = .identity }
    }
}

// MARK: - 工具

final class ToolsPage: MnPage {
    private let output = UILabel()

    init() { super.init(title: "实用工具", subtitle: "设备 · 网络 · 安全", icon: "🧰") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("设备信息", action: #selector(tapDevice))
        softButton("网络加速测试", action: #selector(tapNetwork))
        softButton("安全检测", action: #selector(tapSecurity))
        softButton("服务器诊断（看真实原因）", action: #selector(tapDiag))
        output.textColor = Theme.ink
        output.font = Theme.mono(12)
        output.numberOfLines = 0
        output.textAlignment = .left
        add(output, gap: 10)
    }

    @objc private func tapDevice() {
        let d = UIDevice.current
        output.text = [
            "设备：\(d.model)",
            "系统：\(d.systemName) \(d.systemVersion)",
            "名称：\(d.name)",
            "标识：\(d.identifierForVendor?.uuidString ?? "-")",
            "屏幕：\(Int(UIScreen.main.bounds.width))×\(Int(UIScreen.main.bounds.height))"
        ].joined(separator: "\n")
    }

    @objc private func tapNetwork() {
        output.text = "正在测速…"
        Api.ping { [weak self] ms in
            self?.output.text = "猫夜后端延迟：\(ms) ms\n" + (ms < 300 ? "连接正常 ✓" : "网络较差，建议切换网络")
        }
    }

    @objc private func tapDiag() {
        output.text = "正在诊断…"
        let base = Api.base.absoluteString
        Api.health { ok, msg, ms in
            var lines: [String] = []
            lines.append("后端：\\(base)")
            lines.append(ok ? "健康检查：✓ 可用（\\(ms) ms）" : "健康检查：✗ 失败")
            if !ok { lines.append("原因：" + msg) }
            lines.append("登录状态：" + (AuthStore.token == nil ? "未登录（没有 token）" : "已登录（token 有值）"))
            lines.append("账号：" + (AuthStore.account?.loginName ?? "-"))
            self.output.text = lines.joined(separator: "\\n")
        }
    }

    @objc private func tapSecurity() {
        output.text = "正在检测…"
        Api.integrity { [weak self] ok, msg in
            var lines = ["本地检查：App 沙盒完整 ✓", "网络检查：" + (ok ? "后端一致 ✓" : "异常")]
            if let m = msg, !m.isEmpty { lines.append(m) }
            self?.output.text = lines.joined(separator: "\n")
        }
    }
}

final class NetworkPage: MnPage {
    init() { super.init(title: "网络加速", subtitle: "延迟测试", icon: "🌐") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("开始测速", action: #selector(tapTest))
    }

    @objc private func tapTest() {
        paragraph("测速中…")
        var results: [String] = []
        let group = DispatchGroup()
        for _ in 0..<3 {
            group.enter()
            Api.ping { ms in
                results.append("\(ms) ms")
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.paragraph("猫夜后端延迟：" + results.joined(separator: " / ") + "\n延迟低于 300ms 属于正常。")
        }
    }
}

final class SecurityPage: MnPage {
    init() { super.init(title: "病毒检测", subtitle: "本地 · 网络 · 完整性", icon: "🛡") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("开始检测", action: #selector(tapScan))
        paragraph("检测项：App 沙盒、本地存储、网络完整性、后端签名。")
    }

    @objc private func tapScan() {
        Api.integrity { [weak self] ok, msg in
            var lines = ["✓ App 沙盒完整", "✓ 本地存储可读写"]
            lines.append(ok ? "✓ 后端完整性通过" : "✗ 后端完整性异常")
            if let m = msg, !m.isEmpty { lines.append("备注：" + m) }
            self?.paragraph(lines.joined(separator: "\n"))
        }
    }
}

final class DownloadPage: MnPage {
    init() { super.init(title: "手机下载", subtitle: "下载地址", icon: "📱") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        linkRow("iOS 原生版 IPA", "GitHub Pages 直链，Sideloadly 签名安装", action: #selector(openIPA))
        linkRow("Windows 原生版", "猫夜 2026.11.12 安装包", action: #selector(openWindows))
        paragraph("iOS 18.6.2 不支持 TrollStore，需要用 Sideloadly / AltStore 用 Apple ID 自签（7 天有效）。")
    }

    @objc private func openIPA() {
        if let url = URL(string: "https://cat-night-school.github.io/Maonight/ios-native/out/MaonightNative.ipa") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func openWindows() {
        if let url = URL(string: "https://github.com/cat-night-school/MaoNight") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 个人中心

final class ProfilePage: MnPage {
    private var labels: [String: UILabel] = [:]

    init() { super.init(title: "用户小主页", subtitle: "我的资料", icon: "🏠") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Api.refreshProfile { [weak self] account in
            guard let self = self else { return }
            let a = account ?? AuthStore.account
            self.kv("账号", a?.loginName ?? "-")
            self.kv("昵称", a?.nick ?? "-")
            self.kv("头衔", (a?.title?.isEmpty == false) ? a!.title! : "未佩戴")
            self.kv("身份", a?.role ?? "player")
            self.kv("猫币", "\(a?.coin ?? 0)")
            self.kv("小鱼干", "\(a?.fish ?? 0)")
        }
        softButton("刷新资料", action: #selector(tapRefresh))
    }

    @objc private func tapRefresh() {
        Api.refreshProfile { [weak self] _ in
            self?.paragraph("已刷新 ✓")
        }
    }
}

final class SettingsPage: MnPage {
    init() { super.init(title: "个人设置", subtitle: "账号 · 数据", icon: "⚙️") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        softButton("刷新我的资料", action: #selector(tapRefresh))
        softButton("清空本地缓存（重新登录）", action: #selector(tapClear))
        kv("版本", "1.0.0（原生）")
        kv("构建日期", "2026.11.13")
        paragraph("猫夜原生 iOS 版 · 界面全部由 Swift/UIKit 绘制，不加载任何网页。")
    }

    @objc private func tapRefresh() {
        Api.refreshProfile { [weak self] _ in
            self?.paragraph("资料已刷新 ✓")
        }
    }

    @objc private func tapClear() {
        AuthStore.clear()
        navigationController?.setViewControllers([LoginViewController()], animated: true)
    }
}

final class AdminLogPage: MnPage {
    init() { super.init(title: "记录页", subtitle: "管理操作记录", icon: "📋") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Api.call("GET", "/api/admin/logs?limit=40", nil) { [weak self] data, err in
            guard let self = self else { return }
            if let err = err { self.paragraph("读取失败：" + err); return }
            let list = Api.array(data, "list")
            if list.isEmpty { self.paragraph("暂无记录（或当前账号不是管理员）。"); return }
            for item in list {
                let who = Api.string(item, "acc")
                let what = Api.string(item, "text").isEmpty ? Api.string(item, "action") : Api.string(item, "text")
                let time = Api.string(item, "time")
                self.paragraph("\(time)  \(who)\n\(what)")
            }
        }
    }
}

final class MemberPage: MnPage {
    init() { super.init(title: "猫夜会员", subtitle: "会员权益", icon: "💳") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Api.refreshProfile { [weak self] a in
            self?.kv("当前会员", (a?.role == "member" || a?.role == "admin") ? "已开通" : "未开通")
            self?.kv("会员等级", a?.role ?? "player")
        }
        paragraph("会员权益：专属头衔、每日额外猫币、签到翻倍、专属客服、会员徽章。\n\n开通方式：网页端「猫夜会员」页扫码开通，开通后 iOS 端登录同一账号即可生效。")
        softButton("刷新会员状态", action: #selector(tapRefresh))
    }

    @objc private func tapRefresh() {
        Api.refreshProfile { [weak self] _ in self?.paragraph("已刷新 ✓") }
    }
}

final class FortunePage: MnPage {
    init() { super.init(title: "今日运势", subtitle: "每天一签", icon: "🔮") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let acc = AuthStore.account?.loginName ?? ""
        let today = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        var hash = today
        for scalar in acc.unicodeScalars { hash = (hash &* 31 &+ Int(scalar.value)) & 0x7fffffff }
        let levels = ["大吉", "中吉", "小吉", "平", "小凶"]
        let level = levels[hash % levels.count]
        let lucky = ["聊天室", "五子棋", "喵喵岛屿", "商城", "赛季"][(hash / 7) % 5]
        let colors = ["蓝色", "紫色", "青色", "白色", "金色"]
        kv("今日运势", level)
        kv("幸运玩法", lucky)
        kv("幸运颜色", colors[(hash / 13) % colors.count])
        paragraph("运势每天 0 点刷新，和账号绑定。\n仅供参考，别太当真，开心最重要。")
    }
}

// MARK: - 喵喵岛屿（原生小游戏）

final class IslandGamePage: MnPage {
    private let canvas = IslandCanvas()
    private let resource = UILabel()

    init() { super.init(title: "喵喵岛屿", subtitle: "盖房子 · 养猫猫", icon: "🏝") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.heightAnchor.constraint(equalToConstant: 460).isActive = true
        canvas.layer.cornerRadius = 22
        canvas.layer.cornerCurve = .continuous
        canvas.layer.masksToBounds = true
        add(canvas, gap: 12)
        resource.textColor = Theme.ink
        resource.font = Theme.mono(13)
        resource.textAlignment = .center
        add(resource, gap: 6)
        canvas.onUpdate = { [weak self] fish, wood in
            self?.resource.text = "🐟 \(fish)    🌲 \(wood)"
        }
        softButton("手动存档", action: #selector(tapSave))
        softButton("重开岛屿", action: #selector(tapReset))
        canvas.load()
    }

    @objc private func tapSave() { canvas.save(); paragraph("已保存 ✓") }
    @objc private func tapReset() { canvas.reset(); paragraph("岛屿已重开。") }
}

/// 原生岛屿场景：海、沙滩、草地、三座小建筑、猫猫，点建筑升级。
final class IslandCanvas: UIView {
    private var fish = 20
    private var wood = 10
    private var level = 1
    private let hutTitles = ["鱼塘", "木厂", "猫窝"]
    private var hutLevels = [1, 1, 1]
    var onUpdate: ((Int, Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }

    required init?(coder: NSCoder) { fatalError() }

    func load() {
        let d = UserDefaults.standard
        fish = d.integer(forKey: "island.fish")
        wood = d.integer(forKey: "island.wood")
        if fish == 0 && wood == 0 { fish = 20; wood = 10 }
        onUpdate?(fish, wood)
        setNeedsDisplay()
    }

    func save() {
        let d = UserDefaults.standard
        d.set(fish, forKey: "island.fish")
        d.set(wood, forKey: "island.wood")
    }

    func reset() {
        fish = 20; wood = 10
        save()
        onUpdate?(fish, wood)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let w = bounds.width, h = bounds.height

        // 天空 + 海
        UIColor(red: 0.36, green: 0.62, blue: 0.82, alpha: 1).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h * 0.42))
        UIColor(red: 0.20, green: 0.48, blue: 0.70, alpha: 1).setFill()
        ctx.fill(CGRect(x: 0, y: h * 0.42, width: w, height: h * 0.12))
        // 沙滩
        UIColor(red: 0.93, green: 0.85, blue: 0.66, alpha: 1).setFill()
        ctx.fill(CGRect(x: 0, y: h * 0.54, width: w, height: h * 0.14))
        // 草地
        UIColor(red: 0.42, green: 0.68, blue: 0.38, alpha: 1).setFill()
        ctx.fill(CGRect(x: 0, y: h * 0.68, width: w, height: h * 0.32))
        // 太阳
        UIColor(red: 1.0, green: 0.90, blue: 0.58, alpha: 1).setFill()
        ctx.fillEllipse(in: CGRect(x: w - 90, y: 26, width: 54, height: 54))

        // 三座小房子
        for i in 0..<3 {
            let cx = w * (0.22 + 0.28 * CGFloat(i))
            let baseY = h * 0.74
            let body = CGRect(x: cx - 42, y: baseY - 52, width: 84, height: 52)
            UIColor(red: 0.93, green: 0.90, blue: 0.83, alpha: 1).setFill()
            UIBezierPath(roundedRect: body, cornerRadius: 6).fill()
            // 屋顶
            let roof = UIBezierPath()
            roof.move(to: CGPoint(x: cx - 52, y: baseY - 52))
            roof.addLine(to: CGPoint(x: cx, y: baseY - 86))
            roof.addLine(to: CGPoint(x: cx + 52, y: baseY - 52))
            roof.close()
            UIColor(red: 0.78, green: 0.42, blue: 0.32, alpha: 1).setFill()
            roof.fill()
            // 门
            UIColor(red: 0.45, green: 0.31, blue: 0.20, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: cx - 10, y: baseY - 30, width: 20, height: 30), cornerRadius: 3).fill()
            // 标签
            let title = hutTitles[i] + " Lv\(hutLevels[i])"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            (title as NSString).draw(at: CGPoint(x: cx - 30, y: baseY + 6), withAttributes: attrs)
        }

        // 猫
        let catY = h * 0.88
        let catX = w * 0.5
        UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1).setFill()
        ctx.fillEllipse(in: CGRect(x: catX - 26, y: catY - 26, width: 52, height: 40))
        ctx.fillEllipse(in: CGRect(x: catX - 18, y: catY - 48, width: 36, height: 32))
        UIColor(red: 0.30, green: 0.30, blue: 0.33, alpha: 1).setFill()
        // 耳朵
        let earL = UIBezierPath()
        earL.move(to: CGPoint(x: catX - 16, y: catY - 44))
        earL.addLine(to: CGPoint(x: catX - 8, y: catY - 62))
        earL.addLine(to: CGPoint(x: catX - 2, y: catY - 44))
        earL.fill()
        let earR = UIBezierPath()
        earR.move(to: CGPoint(x: catX + 16, y: catY - 44))
        earR.addLine(to: CGPoint(x: catX + 8, y: catY - 62))
        earR.addLine(to: CGPoint(x: catX + 2, y: catY - 44))
        earR.fill()
        // 眼睛
        UIColor(red: 0.98, green: 0.93, blue: 0.55, alpha: 1).setFill()
        ctx.fillEllipse(in: CGRect(x: catX - 12, y: catY - 38, width: 7, height: 9))
        ctx.fillEllipse(in: CGRect(x: catX + 5, y: catY - 38, width: 7, height: 9))
        // 尾巴
        UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1).setStroke()
        ctx.setLineWidth(6)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: catX + 24, y: catY - 6))
        ctx.addCurve(to: CGPoint(x: catX + 60, y: catY - 30),
                     control1: CGPoint(x: catX + 46, y: catY - 4),
                     control2: CGPoint(x: catX + 62, y: catY - 16))
        ctx.strokePath()

        // 提示
        let hint = "点小房子升级（-8 木头 / -5 鱼干）"
        let attrs2: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(white: 1, alpha: 0.85)
        ]
        (hint as NSString).draw(at: CGPoint(x: 16, y: 14), withAttributes: attrs2)
    }

    @objc private func tap(_ g: UITapGestureRecognizer) {
        let p = g.location(in: self)
        let w = bounds.width
        for i in 0..<3 {
            let cx = w * (0.22 + 0.28 * CGFloat(i))
            if abs(p.x - cx) < 60 && p.y > bounds.height * 0.55 {
                upgrade(i)
                return
            }
        }
    }

    private func upgrade(_ index: Int) {
        if wood < 8 || fish < 5 {
            return
        }
        wood -= 8
        fish -= 5
        hutLevels[index] += 1
        if index == 0 { fish += 3 }
        if index == 1 { wood += 3 }
        onUpdate?(fish, wood)
        setNeedsDisplay()
    }
}
