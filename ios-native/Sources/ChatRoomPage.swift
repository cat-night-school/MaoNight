import UIKit

// MARK: - 聊天室（照 Win 原生版原版布局）

final class ChatRoomPage: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    private let back = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let refreshButton = SoftButton()
    private let autoButton = SoftButton()
    private let table = UITableView(frame: .zero, style: .plain)
    private let toolsRow = UIStackView()
    private let inputBar = UIView()
    private let input = UITextField()
    private let sendButton = UIButton(type: .system)
    private let countLabel = UILabel()
    private let emojiRow = UIScrollView()
    private let emojiStack = UIStackView()

    private var messages: [[String: Any]] = []
    private var lastSeenId: String = ""
    private var autoRefresh = true
    private var timer: Timer?
    private var status: String = ""
    private let emojis = ["😺", "😻", "😹", "🐱", "🐾", "🐟", "🌙", "✨", "🎮", "♟", "🏝", "❤️", "😆", "😭", "👍", "🔥"]
    private var emojiOpen = false

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)

        back.setTitle("← 返回", for: .normal)
        back.setTitleColor(Theme.ink, for: .normal)
        back.titleLabel?.font = Theme.font(13)
        back.backgroundColor = UIColor(white: 1, alpha: 0.12)
        back.layer.cornerRadius = 16
        back.layer.cornerCurve = .continuous
        back.layer.borderWidth = 1
        back.layer.borderColor = Theme.strokeSoft.cgColor
        back.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        view.addSubview(back)

        titleLabel.text = "💬 聊天室"
        titleLabel.textColor = Theme.ink
        titleLabel.font = Theme.font(22, true)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        subLabel.textColor = Theme.muted
        subLabel.font = Theme.font(12)
        subLabel.textAlignment = .center
        subLabel.text = "新增 0 条"
        view.addSubview(subLabel)

        refreshButton.setTitle("刷新", for: .normal)
        refreshButton.titleLabel?.font = Theme.font(13)
        refreshButton.addTarget(self, action: #selector(tapRefresh), for: .touchUpInside)
        view.addSubview(refreshButton)
        autoButton.setTitle("自动刷新：开", for: .normal)
        autoButton.titleLabel?.font = Theme.font(13)
        autoButton.addTarget(self, action: #selector(tapToggleAuto), for: .touchUpInside)
        view.addSubview(autoButton)

        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.allowsSelection = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "msg")
        view.addSubview(table)

        toolsRow.axis = .horizontal
        toolsRow.spacing = 8
        toolsRow.distribution = .fillEqually
        for title in ["表情", "图片", "画板"] {
            let b = SoftButton()
            b.setTitle(title, for: .normal)
            b.titleLabel?.font = Theme.font(13)
            b.addTarget(self, action: #selector(tapTool(_:)), for: .touchUpInside)
            toolsRow.addArrangedSubview(b)
        }
        view.addSubview(toolsRow)

        emojiRow.showsHorizontalScrollIndicator = false
        emojiRow.backgroundColor = UIColor(white: 1, alpha: 0.06)
        emojiRow.layer.cornerRadius = 14
        emojiRow.layer.cornerCurve = .continuous
        emojiRow.isHidden = true
        emojiStack.axis = .horizontal
        emojiStack.spacing = 6
        emojiStack.isLayoutMarginsRelativeArrangement = true
        emojiStack.layoutMargins = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        emojiRow.addSubview(emojiStack)
        for e in emojis {
            let b = UIButton(type: .system)
            b.setTitle(e, for: .normal)
            b.titleLabel?.font = Theme.font(22)
            b.addTarget(self, action: #selector(tapEmoji(_:)), for: .touchUpInside)
            emojiStack.addArrangedSubview(b)
        }
        view.addSubview(emojiRow)

        inputBar.backgroundColor = UIColor(white: 1, alpha: 0.10)
        inputBar.layer.cornerRadius = 20
        inputBar.layer.cornerCurve = .continuous
        inputBar.layer.borderWidth = 1
        inputBar.layer.borderColor = Theme.strokeSoft.cgColor
        view.addSubview(inputBar)

        input.backgroundColor = .clear
        input.textColor = Theme.ink
        input.font = Theme.font(15)
        input.attributedPlaceholder = NSAttributedString(string: "说点什么…", attributes: [.foregroundColor: Theme.faint])
        input.delegate = self
        input.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        inputBar.addSubview(input)

        countLabel.textColor = Theme.faint
        countLabel.font = Theme.font(10)
        countLabel.textAlignment = .right
        countLabel.text = "0/200"
        inputBar.addSubview(countLabel)

        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = Theme.font(14, true)
        sendButton.backgroundColor = Theme.accent
        sendButton.layer.cornerRadius = 16
        sendButton.layer.cornerCurve = .continuous
        sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        view.addSubview(sendButton)

        load(announce: true)
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            if self?.autoRefresh == true { self?.load(announce: false) }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate(); timer = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let top = view.safeAreaInsets.top
        let bottom = view.safeAreaInsets.bottom
        back.frame = CGRect(x: 16, y: top + 8, width: 78, height: 32)
        titleLabel.frame = CGRect(x: 100, y: top + 6, width: w - 200, height: 28)
        subLabel.frame = CGRect(x: 100, y: top + 34, width: w - 200, height: 18)
        let btnW: CGFloat = 96
        autoButton.frame = CGRect(x: w - 16 - btnW, y: top + 10, width: btnW, height: 32)
        refreshButton.frame = CGRect(x: w - 16 - btnW * 2 - 8, y: top + 10, width: 64, height: 32)
        let toolsY = view.bounds.height - bottom - 56
        toolsRow.frame = CGRect(x: 16, y: toolsY, width: w - 32, height: 44)
        let emojiY = toolsY - 54
        emojiRow.frame = CGRect(x: 16, y: emojiY, width: w - 32, height: 48)
        emojiStack.frame = CGRect(x: 0, y: 0, width: max(w - 32, CGFloat(emojis.count) * 44), height: 48)
        emojiRow.contentSize = emojiStack.frame.size
        inputBar.frame = CGRect(x: 16, y: view.bounds.height - bottom - 108 + (emojiOpen ? -54 : 0), width: w - 32, height: 44)
        input.frame = CGRect(x: 14, y: 0, width: w - 32 - 14 - 74 - 60, height: 44)
        countLabel.frame = CGRect(x: input.frame.maxX - 4, y: 22, width: 60, height: 16)
        sendButton.frame = CGRect(x: inputBar.frame.maxX - 74, y: inputBar.frame.minY + 5, width: 62, height: 34)
        table.frame = CGRect(x: 0, y: top + 60, width: w, height: max(80, (emojiOpen ? emojiY : inputBar.frame.minY) - (top + 60) - 8))
    }

    private func load(announce: Bool) {
        Api.chat { [weak self] list, error in
            guard let self = self else { return }
            if let error = error {
                self.subLabel.text = "加载失败：" + error
                return
            }
            let old = self.messages
            self.messages = list ?? []
            var newCount = 0
            for m in self.messages {
                let id = Api.string(m, "id")
                if !id.isEmpty && !id.isEmpty {
                    if old.contains(where: { Api.string($0, "id") == id }) { continue }
                }
                newCount += 1
            }
            if announce { newCount = self.messages.count }
            self.subLabel.text = "新增 \(max(0, min(newCount, self.messages.count))) 条 · 共 \(self.messages.count) 条"
            self.table.reloadData()
            if !self.messages.isEmpty {
                let last = IndexPath(row: self.messages.count - 1, section: 0)
                self.table.scrollToRow(at: last, at: .bottom, animated: false)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "msg")
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let m = messages[indexPath.row]
        let time = Api.string(m, "time")
        let nick = Api.string(m, "nick").isEmpty ? Api.string(m, "acc") : Api.string(m, "nick")
        let title = Api.string(m, "title")
        let me = AuthStore.account?.loginName ?? ""
        let isMe = !me.isEmpty && Api.string(m, "acc") == me
        let prefix = (time.isEmpty ? "" : time + " ") + nick + (title.isEmpty ? "" : "「\(title)」") + "："
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: prefix, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: isMe ? Theme.accentLight : Theme.muted
        ]))
        text.append(NSAttributedString(string: Api.string(m, "text"), attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: Theme.ink
        ]))
        cell.textLabel?.attributedText = text
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    @objc private func tapBack() { navigationController?.popViewController(animated: true) }

    @objc private func tapRefresh() { load(announce: true) }

    @objc private func tapToggleAuto() {
        autoRefresh = !autoRefresh
        autoButton.setTitle(autoRefresh ? "自动刷新：开" : "自动刷新：关", for: .normal)
    }

    @objc private func tapTool(_ sender: UIButton) {
        switch sender.title(for: .normal) {
        case "表情":
            emojiOpen = !emojiOpen
            emojiRow.isHidden = !emojiOpen
        case "图片":
            let a = UIAlertController(title: "图片", message: "图片发送正在接入（需要先在后端开放上传），先用表情吧。", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(a, animated: true, completion: nil)
        default:
            let a = UIAlertController(title: "画板", message: "画板下一版接入。", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(a, animated: true, completion: nil)
        }
        view.setNeedsLayout()
    }

    @objc private func tapEmoji(_ sender: UIButton) {
        guard let e = sender.title(for: .normal) else { return }
        input.text = (input.text ?? "") + e
        textChanged()
    }

    @objc private func textChanged() {
        let n = input.text?.count ?? 0
        countLabel.text = "\(n)/200"
        countLabel.textColor = n > 200 ? Theme.error : Theme.faint
    }

    @objc private func tapSend() {
        var text = input.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty { return }
        if text.count > 200 { text = String(text.prefix(200)) }
        input.text = ""
        textChanged()
        sendButton.isEnabled = false
        Api.sendChat(text: text) { [weak self] ok, error in
            guard let self = self else { return }
            self.sendButton.isEnabled = true
            if !ok {
                self.subLabel.text = "发送失败：" + (error ?? "未知错误")
                return
            }
            self.load(announce: false)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { tapSend(); return true }
}

// MARK: - 联机五子棋

final class GomokuRoomPage: MnPage, UITextFieldDelegate {
    private let board = GomokuBoard()
    private let status = UILabel()
    private var codeField: UITextField!
    private var timer: Timer?
    private var room: [String: Any]?
    private var myColor = 0

    init() { super.init(title: "联机对战", subtitle: "五子棋房间", icon: "🌐") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        board.onTap = { [weak self] index in self?.tapBoard(index) }
        board.translatesAutoresizingMaskIntoConstraints = false
        board.heightAnchor.constraint(equalToConstant: 320).isActive = true
        add(board, gap: 8)
        status.textAlignment = .center
        status.font = Theme.font(14, true)
        status.textColor = Theme.ink
        add(status, gap: 4)
        codeField = textField(placeholder: "输入房间号加入")
        codeField.delegate = self
        primaryButton("创建房间", action: #selector(tapCreate))
        softButton("加入房间", action: #selector(tapJoin))
        softButton("刷新房间状态", action: #selector(tapRefresh))
        paragraph("联机为轮询同步（1.5 秒一次）。创建后把房间号发给好友，对方输入房间号加入；黑棋先行。")
        status.text = "创建房间，或输入房间号加入"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate(); timer = nil
    }

    @objc private func tapCreate() {
        Api.roomCreate { [weak self] room, err in
            guard let self = self else { return }
            if let err = err { self.status.text = err; return }
            self.enter(room)
        }
    }

    @objc private func tapJoin() {
        let id = codeField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if id.isEmpty { status.text = "先输入房间号"; return }
        Api.roomJoin(id: id) { [weak self] room, err in
            guard let self = self else { return }
            if let err = err { self.status.text = err; return }
            self.enter(room)
        }
    }

    private func enter(_ room: [String: Any]?) {
        guard let room = room else { status.text = "房间数据为空"; return }
        self.room = room
        let me = AuthStore.account?.loginName ?? ""
        myColor = Api.string(room, "host") == me ? 1 : 2
        updateBoard()
        let short = String(Api.string(room, "id").prefix(8))
        status.text = "房间 \(short) · " + (myColor == 1 ? "你执黑先行" : "你执白")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in self?.poll() }
        poll()
    }

    private func poll() {
        let id = room.map { Api.string($0, "id") } ?? ""
        if id.isEmpty { return }
        Api.roomState(id: id) { [weak self] updated, err in
            guard let self = self else { return }
            if let err = err { self.status.text = err; return }
            if let updated = updated { self.room = updated; self.updateBoard() }
        }
    }

    private func updateBoard() {
        guard let room = room else { return }
        let raw = room["board"] as? [Any] ?? []
        var cells = [Int](repeating: 0, count: 225)
        for (i, v) in raw.enumerated() where i < 225 {
            if let n = v as? NSNumber { cells[i] = n.intValue }
        }
        board.cells = cells
        board.setNeedsDisplay()
        let state = Api.string(room, "state")
        let winner = Api.int(room, "winner")
        let turn = Api.int(room, "turn")
        if state == "open" {
            status.text = "等待对手加入… 房间号 " + String(Api.string(room, "id").prefix(8))
        } else if state == "playing" {
            status.text = turn == myColor ? "轮到你落子" : "等待对手落子…"
        } else if state == "done" {
            status.text = winner == 0 ? "对局结束（和棋）" : (winner == myColor ? "你赢了！" : "你输了")
        }
    }

    private func tapBoard(_ index: Int) {
        guard let room = room, Api.string(room, "state") == "playing" else { return }
        if Api.int(room, "turn") != myColor { status.text = "还没轮到你"; return }
        let id = Api.string(room, "id")
        Api.roomMove(id: id, x: index % 15, y: index / 15) { [weak self] updated, err in
            guard let self = self else { return }
            if let err = err { self.status.text = err; return }
            if let updated = updated { self.room = updated; self.updateBoard() }
        }
    }

    @objc private func tapRefresh() { poll() }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { tapJoin(); return true }
}