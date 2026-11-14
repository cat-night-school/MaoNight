import UIKit

// MARK: - 棋类训练（五步流程，照 Win 原生版）

final class ChessTrainingPage: MnPage {
    private let body = UIView()
    private var bodyHeight: NSLayoutConstraint?
    private var step = 0
    private var game = 0          // 0 五子棋 1 围棋 2 象棋
    private var mode = 0          // 0 人机 1 本地双人 2 联机
    private var difficulty = 1    // 1..4
    private var playerFirst = true

    private let games: [(String, String, String)] = [
        ("黑", "五子棋", "15×15 · 先手执黑 · 4 档 AI"),
        ("白", "围棋", "19×19 · 先手执黑 · 贴 6 目"),
        ("红", "象棋", "9×10 · 先手执红 · 楚河汉界")
    ]
    private let modes = ["人机对战", "本地双人", "联机对战"]
    private let diffs = ["简单", "中等", "困难", "超凡"]
    private let sides = ["先手（执黑/红）", "后手（执白/黑）"]

    init() { super.init(title: "棋类训练", subtitle: "选择棋种", icon: "♟") }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        body.tag = 88001
        add(body, gap: 0)
        bodyHeight = body.heightAnchor.constraint(equalToConstant: 200)
        bodyHeight?.isActive = true
        rebuild()
    }

    private func rebuild() {
        for sub in body.subviews { sub.removeFromSuperview() }
        header.subtitleLabel.text = subtitle
        let w = min(view.bounds.width - 32, 560)
        var y: CGFloat = 8

        if step == 0 {
            for (i, g) in games.enumerated() {
                let card = GlassCard(radius: 20)
                card.translatesAutoresizingMaskIntoConstraints = false
                body.addSubview(card)
                card.leadingAnchor.constraint(equalTo: body.leadingAnchor).isActive = true
                card.trailingAnchor.constraint(equalTo: body.trailingAnchor).isActive = true
                card.topAnchor.constraint(equalTo: body.topAnchor, constant: y).isActive = true
                card.heightAnchor.constraint(equalToConstant: 88).isActive = true

                let piece = PieceDot(color: i == 0 ? .black : (i == 1 ? .white : .red))
                piece.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(piece)
                piece.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18).isActive = true
                piece.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
                piece.widthAnchor.constraint(equalToConstant: 46).isActive = true
                piece.heightAnchor.constraint(equalToConstant: 46).isActive = true

                let title = UILabel()
                title.text = g.1
                title.textColor = Theme.ink
                title.font = Theme.font(17, true)
                title.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(title)
                title.leadingAnchor.constraint(equalTo: piece.trailingAnchor, constant: 16).isActive = true
                title.topAnchor.constraint(equalTo: card.topAnchor, constant: 20).isActive = true

                let sub = UILabel()
                sub.text = g.2
                sub.textColor = Theme.muted
                sub.font = Theme.font(12)
                sub.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(sub)
                sub.leadingAnchor.constraint(equalTo: title.leadingAnchor).isActive = true
                sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4).isActive = true

                let tap = TapTarget(action: #selector(tapGame(_:)), target: self)
                card.addGestureRecognizer(tap.gesture)
                card.accessibilityIdentifier = "\(i)"
                y += 100
            }
        } else {
            let titles = step == 1 ? modes : (step == 2 ? diffs : sides)
            for (i, t) in titles.enumerated() {
                let b = AccentButton()
                b.translatesAutoresizingMaskIntoConstraints = false
                b.setTitle(t, for: .normal)
                b.tag = i
                b.accessibilityIdentifier = "\(step)"
                b.addTarget(self, action: #selector(tapChoice(_:)), for: .touchUpInside)
                body.addSubview(b)
                b.leadingAnchor.constraint(equalTo: body.leadingAnchor).isActive = true
                b.trailingAnchor.constraint(equalTo: body.trailingAnchor).isActive = true
                b.topAnchor.constraint(equalTo: body.topAnchor, constant: y).isActive = true
                b.heightAnchor.constraint(equalToConstant: 50).isActive = true
                y += 60
            }
            let back = SoftButton()
            back.translatesAutoresizingMaskIntoConstraints = false
            back.setTitle("← 上一步", for: .normal)
            back.addTarget(self, action: #selector(previousStep), for: .touchUpInside)
            body.addSubview(back)
            back.leadingAnchor.constraint(equalTo: body.leadingAnchor).isActive = true
            back.trailingAnchor.constraint(equalTo: body.trailingAnchor).isActive = true
            back.topAnchor.constraint(equalTo: body.topAnchor, constant: y + 4).isActive = true
            back.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        bodyHeight?.constant = y + 60
        view.setNeedsLayout()
    }

    private var subtitle: String {
        if step == 0 { return "选择棋种" }
        let name = games[game].1
        switch step {
        case 1: return name + " · 选择模式"
        case 2: return name + " · 选择 AI 难度"
        default: return name + " · 选择先后手"
        }
    }

    @objc private func tapGame(_ g: UITapGestureRecognizer) {
        game = Int(g.view?.accessibilityIdentifier ?? "0") ?? 0
        step = 1
        rebuild()
    }

    @objc private func tapChoice(_ sender: UIButton) {
        let index = sender.tag
        if step == 1 {
            mode = index
            if mode == 2 {
                startOnline()
            } else if mode == 0 {
                step = 2
                rebuild()
            } else {
                step = 3
                rebuild()
            }
        } else if step == 2 {
            difficulty = index + 1
            step = 3
            rebuild()
        } else {
            playerFirst = index == 0
            start()
        }
    }

    @objc private func previousStep() {
        step = max(0, step - 1)
        rebuild()
    }

    private func start() {
        var vc: UIViewController
        if game == 0 {
            vc = GomokuGamePage(vsComputer: mode == 0, playerFirst: playerFirst, difficulty: difficulty)
        } else if game == 1 {
            vc = GoGamePage(vsComputer: mode == 0, playerFirst: playerFirst, difficulty: difficulty)
        } else {
            vc = XiangqiGamePage(vsComputer: mode == 0, playerFirst: playerFirst, difficulty: difficulty)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func startOnline() {
        if game != 0 {
            let alert = UIAlertController(title: "联机对战", message: "目前联机只开放五子棋，其它棋种下一版接入。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        navigationController?.pushViewController(GomokuRoomPage(), animated: true)
    }
}

/// 棋子圆点：黑/白/红，带高光（照 Win 版棋子样式）。
final class PieceDot: UIView {
    enum Kind { case black, white, red }
    private let kind: Kind

    init(color: Kind) {
        self.kind = color
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let d = min(bounds.width, bounds.height) - 4
        let r = CGRect(x: (bounds.width - d) / 2, y: (bounds.height - d) / 2, width: d, height: d)
        switch kind {
        case .black:
            UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1).setFill()
        case .white:
            UIColor(white: 0.97, alpha: 1).setFill()
        case .red:
            UIColor(red: 0.86, green: 0.24, blue: 0.24, alpha: 1).setFill()
        }
        ctx.fillEllipse(in: r)
        ctx.setStrokeColor(UIColor(white: 0.35, alpha: 0.4).cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: r)
        // 高光
        UIColor(white: 1, alpha: kind == .white ? 0.9 : 0.28).setFill()
        ctx.fillEllipse(in: CGRect(x: r.minX + d * 0.18, y: r.minY + d * 0.14, width: d * 0.28, height: d * 0.22))
    }
}

// MARK: - 五子棋

final class GomokuGamePage: MnPage {
    private let vsComputer: Bool
    private let playerFirst: Bool
    private let difficulty: Int

    private let board = GomokuBoard()
    private let status = UILabel()
    private let moveLabel = UILabel()
    private let undoButton = SoftButton()
    private let restartButton = SoftButton()
    private let hint = UILabel()

    private var turn = 1
    private var over = false
    private var history: [Int] = []
    private var boardHeight: NSLayoutConstraint?

    init(vsComputer: Bool, playerFirst: Bool, difficulty: Int) {
        self.vsComputer = vsComputer
        self.playerFirst = playerFirst
        self.difficulty = difficulty
        super.init(title: "五子棋", subtitle: vsComputer ? "人机对战" : "本地双人", icon: "⚫")
    }

    required init?(coder: NSCoder) { fatalError() }

    private var humanColor: Int { return playerFirst ? 1 : 2 }
    private var computerColor: Int { return playerFirst ? 2 : 1 }

    override func viewDidLoad() {
        super.viewDidLoad()
        board.translatesAutoresizingMaskIntoConstraints = false
        board.onTap = { [weak self] index in self?.humanPlace(index) }
        add(board, gap: 12)
        boardHeight = board.heightAnchor.constraint(equalToConstant: 300)
        boardHeight?.isActive = true

        status.textAlignment = .center
        status.font = Theme.font(15, true)
        add(status, gap: 6)

        moveLabel.textColor = Theme.faint
        moveLabel.font = Theme.font(12)
        moveLabel.textAlignment = .center
        add(moveLabel, gap: 4)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        undoButton.setTitle("悔棋", for: .normal)
        undoButton.addTarget(self, action: #selector(tapUndo), for: .touchUpInside)
        restartButton.setTitle("重新开始", for: .normal)
        restartButton.addTarget(self, action: #selector(tapRestart), for: .touchUpInside)
        row.addArrangedSubview(undoButton)
        row.addArrangedSubview(restartButton)
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true
        add(row, gap: 12)

        hint.textColor = Theme.faint
        hint.font = Theme.font(11)
        hint.numberOfLines = 0
        hint.textAlignment = .center
        hint.text = "点棋盘落子 · 五连获胜 · 当前 \(difficultyName(difficulty)) AI"
        add(hint, gap: 6)

        reset()
    }

    private func difficultyName(_ d: Int) -> String {
        return ["简单", "中等", "困难", "超凡"][max(0, min(3, d - 1))]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let side = min(view.bounds.width - 24, view.bounds.height - 420)
        boardHeight?.constant = max(240, side)
    }

    private func say(_ t: String, _ c: UIColor = Theme.ink) {
        status.textColor = c
        status.text = t
    }

    private func reset() {
        board.cells = [Int](repeating: 0, count: 225)
        board.lastIndex = -1
        board.winLine = []
        board.setNeedsDisplay()
        history.removeAll()
        turn = 1
        over = false
        moveLabel.text = "第 0 手"
        if !vsComputer {
            say("黑方先手，轮流落子")
            return
        }
        if playerFirst {
            say("你执黑先行")
        } else {
            say("电脑执黑，思考中…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.computerMove()
            }
        }
    }

    private func humanPlace(_ index: Int) {
        if over || index < 0 || index >= board.cells.count { return }
        if board.cells[index] != 0 { return }
        let color = vsComputer ? humanColor : turn
        if vsComputer && turn != humanColor { return }
        place(index, color)
        if over { return }
        if vsComputer {
            say("电脑思考中…", Theme.muted)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.computerMove()
            }
        }
    }

    private func computerMove() {
        guard !over else { return }
        let index = GomokuAI.pick(board: board.cells, color: computerColor, level: difficulty)
        if index < 0 { return }
        place(index, computerColor)
    }

    private func place(_ index: Int, _ color: Int) {
        board.cells[index] = color
        board.lastIndex = index
        history.append(index)
        moveLabel.text = "第 \(history.count) 手"
        board.setNeedsDisplay()

        if let line = GomokuAI.winLine(board: board.cells, index: index, color: color) {
            over = true
            board.winLine = line
            board.setNeedsDisplay()
            if vsComputer {
                say(color == humanColor ? "你赢了！" : "电脑赢了", color == humanColor ? Theme.good : Theme.error)
            } else {
                say((color == 1 ? "黑棋" : "白棋") + "五连获胜！", Theme.good)
            }
            return
        }
        if history.count >= 225 {
            over = true
            say("棋盘下满，和棋", Theme.warn)
            return
        }
        turn = 1 + 2 - color
        if vsComputer {
            if turn == humanColor { say("轮到你了") }
        } else {
            say(turn == 1 ? "轮到黑方" : "轮到白方")
        }
    }

    @objc private func tapUndo() {
        guard !history.isEmpty else { say("还没有可以悔的棋", Theme.warn); return }
        let steps = vsComputer ? 2 : 1
        for _ in 0..<steps where !history.isEmpty {
            let last = history.removeLast()
            board.cells[last] = 0
        }
        board.lastIndex = history.last ?? -1
        board.winLine = []
        board.setNeedsDisplay()
        moveLabel.text = "第 \(history.count) 手"
        over = false
        turn = vsComputer ? humanColor : ((history.count % 2 == 0) ? 1 : 2)
        say(vsComputer ? "已悔棋，轮到你了" : "已悔棋")
    }

    @objc private func tapRestart() { reset() }
}

/// 五子棋棋盘（木色 + 星位 + 坐标 + 最后一手 + 胜利连线高亮）。
final class GomokuBoard: UIView {
    static let lines = 15
    var cells = [Int](repeating: 0, count: lines * lines)
    var lastIndex = -1
    var winLine: [Int] = []
    var onTap: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }

    required init?(coder: NSCoder) { fatalError() }

    private func geom() -> (origin: CGPoint, step: CGFloat) {
        let pad: CGFloat = 18
        let side = min(bounds.width, bounds.height) - pad * 2
        let step = side / CGFloat(GomokuBoard.lines - 1)
        let ox = (bounds.width - side) / 2
        let oy = (bounds.height - side) / 2
        return (CGPoint(x: ox, y: oy), step)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let g = geom()
        // 木色底
        let bg = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 16)
        UIColor(red: 0.90, green: 0.80, blue: 0.57, alpha: 1).setFill()
        bg.fill()
        UIColor(red: 0.80, green: 0.68, blue: 0.44, alpha: 0.35).setFill()
        UIBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 8), cornerRadius: 12).fill()

        // 网格
        ctx.setStrokeColor(UIColor(red: 0.38, green: 0.28, blue: 0.15, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        for i in 0..<GomokuBoard.lines {
            let x = g.origin.x + CGFloat(i) * g.step
            let y = g.origin.y + CGFloat(i) * g.step
            ctx.move(to: CGPoint(x: x, y: g.origin.y))
            ctx.addLine(to: CGPoint(x: x, y: g.origin.y + CGFloat(GomokuBoard.lines - 1) * g.step))
            ctx.move(to: CGPoint(x: g.origin.x, y: y))
            ctx.addLine(to: CGPoint(x: g.origin.x + CGFloat(GomokuBoard.lines - 1) * g.step, y: y))
        }
        ctx.strokePath()
        // 星位
        ctx.setFillColor(UIColor(red: 0.30, green: 0.22, blue: 0.10, alpha: 1).cgColor)
        for (c, r) in [(3, 3), (11, 3), (7, 7), (3, 11), (11, 11)] {
            let p = CGPoint(x: g.origin.x + CGFloat(c) * g.step, y: g.origin.y + CGFloat(r) * g.step)
            ctx.fillEllipse(in: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
        }
        // 坐标
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor(red: 0.42, green: 0.32, blue: 0.18, alpha: 0.85)
        ]
        for i in 0..<GomokuBoard.lines {
            let p = CGPoint(x: g.origin.x + CGFloat(i) * g.step, y: g.origin.y - 9)
            ("\(i + 1)" as NSString).draw(at: CGPoint(x: p.x - 4, y: p.y), withAttributes: attrs)
            let q = CGPoint(x: g.origin.x - 13, y: g.origin.y + CGFloat(i) * g.step - 5)
            (String(Character(UnicodeScalar(65 + i)!)) as NSString).draw(at: q, withAttributes: attrs)
        }

        // 棋子
        let stoneR = g.step * 0.43
        for index in 0..<cells.count where cells[index] != 0 {
            let col = index % GomokuBoard.lines
            let row = index / GomokuBoard.lines
            let p = CGPoint(x: g.origin.x + CGFloat(col) * g.step, y: g.origin.y + CGFloat(row) * g.step)
            let r = CGRect(x: p.x - stoneR, y: p.y - stoneR, width: stoneR * 2, height: stoneR * 2)
            // 阴影
            UIColor(white: 0, alpha: 0.18).setFill()
            ctx.fillEllipse(in: r.offsetBy(dx: 1.5, dy: 2))
            if cells[index] == 1 {
                UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1).setFill()
            } else {
                UIColor(white: 0.98, alpha: 1).setFill()
            }
            ctx.fillEllipse(in: r)
            UIColor(white: 0.4, alpha: 0.35).setStroke()
            ctx.setLineWidth(0.8)
            ctx.strokeEllipse(in: r)
            UIColor(white: 1, alpha: cells[index] == 1 ? 0.18 : 0.9).setFill()
            ctx.fillEllipse(in: CGRect(x: r.minX + stoneR * 0.35, y: r.minY + stoneR * 0.3, width: stoneR * 0.7, height: stoneR * 0.5))
        }

        // 最后一手
        if lastIndex >= 0 && lastIndex < cells.count {
            let col = lastIndex % GomokuBoard.lines
            let row = lastIndex / GomokuBoard.lines
            let p = CGPoint(x: g.origin.x + CGFloat(col) * g.step, y: g.origin.y + CGFloat(row) * g.step)
            ctx.setStrokeColor(UIColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 0.95).cgColor)
            ctx.setLineWidth(1.8)
            ctx.strokeEllipse(in: CGRect(x: p.x - stoneR + 1, y: p.y - stoneR + 1, width: stoneR * 2 - 2, height: stoneR * 2 - 2))
        }

        // 胜利连线
        if winLine.count >= 2 {
            ctx.setStrokeColor(UIColor(red: 0.95, green: 0.85, blue: 0.2, alpha: 0.9).cgColor)
            ctx.setLineWidth(3)
            ctx.setLineCap(.round)
            let first = winLine[0]
            let last = winLine[winLine.count - 1]
            let p1 = CGPoint(x: g.origin.x + CGFloat(first % GomokuBoard.lines) * g.step,
                             y: g.origin.y + CGFloat(first / GomokuBoard.lines) * g.step)
            let p2 = CGPoint(x: g.origin.x + CGFloat(last % GomokuBoard.lines) * g.step,
                             y: g.origin.y + CGFloat(last / GomokuBoard.lines) * g.step)
            ctx.move(to: p1)
            ctx.addLine(to: p2)
            ctx.strokePath()
        }
    }

    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        let p = gesture.location(in: self)
        let g = geom()
        let col = Int(round((p.x - g.origin.x) / g.step))
        let row = Int(round((p.y - g.origin.y) / g.step))
        if col < 0 || row < 0 || col >= GomokuBoard.lines || row >= GomokuBoard.lines { return }
        onTap?(row * GomokuBoard.lines + col)
    }
}

/// 五子棋规则 + AI（1 随机、2 攻防、3 棋型评分、4 更强评分）。
enum GomokuAI {
    static let n = 15

    static func winLine(board: [Int], index: Int, color: Int) -> [Int]? {
        let x = index % n
        let y = index / n
        let dirs = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for (dx, dy) in dirs {
            var line = [index]
            for sign in [1, -1] {
                var cx = x + dx * sign
                var cy = y + dy * sign
                while cx >= 0 && cy >= 0 && cx < n && cy < n && board[cy * n + cx] == color {
                    line.append(cy * n + cx)
                    cx += dx * sign
                    cy += dy * sign
                }
            }
            if line.count >= 5 {
                return line.sorted()
            }
        }
        return nil
    }

    static func isWin(board: [Int], index: Int, color: Int) -> Bool {
        return winLine(board: board, index: index, color: color) != nil
    }

    static func pick(board: [Int], color: Int, level: Int) -> Int {
        let opp = 1 + 2 - color
        var empties: [Int] = []
        for i in 0..<board.count where board[i] == 0 { empties.append(i) }
        if empties.isEmpty { return -1 }

        // 能赢就直接赢
        for i in empties {
            var b = board
            b[i] = color
            if isWin(board: b, index: i, color: color) { return i }
        }
        // 对方能赢就堵
        for i in empties {
            var b = board
            b[i] = opp
            if isWin(board: b, index: i, color: opp) { return i }
        }
        if level <= 1 {
            return empties.randomElement() ?? -1
        }
        if level == 2 {
            return bestByScore(board: board, candidates: adjacent(board: board, empties: empties), color: color, opp: opp)
        }
        let cands = adjacent(board: board, empties: empties)
        let pool = cands.isEmpty ? empties : cands
        return bestByScore(board: board, candidates: pool, color: color, opp: opp)
    }

    private static func adjacent(board: [Int], empties: [Int]) -> [Int] {
        var set = Set<Int>()
        for i in empties {
            let x = i % n
            let y = i / n
            for dy in -2...2 {
                for dx in -2...2 {
                    if dx == 0 && dy == 0 { continue }
                    let nx = x + dx
                    let ny = y + dy
                    if nx < 0 || ny < 0 || nx >= n || ny >= n { continue }
                    if board[ny * n + nx] != 0 { set.insert(i); break }
                }
            }
        }
        return Array(set)
    }

    private static func bestByScore(board: [Int], candidates: [Int], color: Int, opp: Int) -> Int {
        var best = -1
        var bestScore = Int.min
        for i in candidates {
            var attack = 0
            var defense = 0
            var b = board
            b[i] = color
            attack = scorePoint(b, i, color)
            b[i] = opp
            defense = scorePoint(b, i, opp)
            let total = attack + defense * 9 / 10
            if total > bestScore {
                bestScore = total
                best = i
            }
        }
        return best
    }

    /// 棋型评分：五连 > 活四 > 冲四 > 活三 > 眠三 > 活二 > 眠二。
    static func scorePoint(_ board: [Int], _ index: Int, _ color: Int) -> Int {
        let x = index % n
        let y = index / n
        let dirs = [(1, 0), (0, 1), (1, 1), (1, -1)]
        var total = 0
        for (dx, dy) in dirs {
            var count = 1
            var openEnds = 0
            var gap = 0
            for sign in [1, -1] {
                var cx = x + dx * sign
                var cy = y + dy * sign
                while cx >= 0 && cy >= 0 && cx < n && cy < n {
                    let v = board[cy * n + cx]
                    if v == color {
                        count += 1
                        cx += dx * sign
                        cy += dy * sign
                    } else if v == 0 {
                        openEnds += 1
                        break
                    } else {
                        break
                    }
                }
            }
            total += patternScore(count: count, openEnds: openEnds)
        }
        return total
    }

    private static func patternScore(count: Int, openEnds: Int) -> Int {
        if count >= 5 { return 10_000_000 }
        if openEnds == 0 { return 0 }
        switch count {
        case 4: return openEnds >= 2 ? 1_000_000 : 120_000
        case 3: return openEnds >= 2 ? 30_000 : 4_000
        case 2: return openEnds >= 2 ? 1_200 : 200
        default: return openEnds >= 2 ? 120 : 30
        }
    }
}
