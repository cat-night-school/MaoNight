import UIKit

/// 五子棋棋盘：CoreGraphics 原生绘制（木色盘 + 线 + 棋子），不用任何网页/图片。
final class GomokuBoardView: UIView {
    static let lines = 15
    var cells = [Int](repeating: 0, count: lines * lines)   // 0 空 1 黑 2 白
    var lastIndex = -1
    var onTap: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var grid: CGFloat {
        return min(bounds.width, bounds.height)
    }

    private func origin() -> CGPoint {
        return CGPoint(x: (bounds.width - grid) / 2, y: (bounds.height - grid) / 2)
    }

    private func point(col: Int, row: Int) -> CGPoint {
        let o = origin()
        let step = grid / CGFloat(GomokuBoardView.lines - 1)
        return CGPoint(x: o.x + CGFloat(col) * step, y: o.y + CGFloat(row) * step)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let rad: CGFloat = 14
        let bg = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: rad)
        UIColor(red: 0.90, green: 0.82, blue: 0.60, alpha: 1).setFill()
        bg.fill()

        let o = origin()
        let step = grid / CGFloat(GomokuBoardView.lines - 1)
        ctx.setStrokeColor(UIColor(red: 0.36, green: 0.27, blue: 0.14, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        for i in 0..<GomokuBoardView.lines {
            let p = o.x + CGFloat(i) * step
            ctx.move(to: CGPoint(x: p, y: o.y))
            ctx.addLine(to: CGPoint(x: p, y: o.y + grid))
            let q = o.y + CGFloat(i) * step
            ctx.move(to: CGPoint(x: o.x, y: q))
            ctx.addLine(to: CGPoint(x: o.x + grid, y: q))
        }
        ctx.strokePath()

        // 天元
        let center = point(col: 7, row: 7)
        ctx.setFillColor(UIColor(red: 0.30, green: 0.22, blue: 0.10, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5))

        let stoneR = step * 0.42
        for index in 0..<cells.count {
            let v = cells[index]
            if v == 0 { continue }
            let col = index % GomokuBoardView.lines
            let row = index / GomokuBoardView.lines
            let p = point(col: col, row: row)
            let r = CGRect(x: p.x - stoneR, y: p.y - stoneR, width: stoneR * 2, height: stoneR * 2)
            if v == 1 {
                UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1).setFill()
            } else {
                UIColor(white: 0.97, alpha: 1).setFill()
            }
            ctx.fillEllipse(in: r)
            ctx.setStrokeColor(UIColor(white: 0.35, alpha: 0.5).cgColor)
            ctx.setLineWidth(0.8)
            ctx.strokeEllipse(in: r)
        }

        if lastIndex >= 0 && lastIndex < cells.count {
            let col = lastIndex % GomokuBoardView.lines
            let row = lastIndex / GomokuBoardView.lines
            let p = point(col: col, row: row)
            ctx.setStrokeColor(UIColor.red.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(1.6)
            ctx.strokeEllipse(in: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8))
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let p = gesture.location(in: self)
        let o = origin()
        let step = grid / CGFloat(GomokuBoardView.lines - 1)
        let col = Int(round((p.x - o.x) / step))
        let row = Int(round((p.y - o.y) / step))
        if col < 0 || row < 0 || col >= GomokuBoardView.lines || row >= GomokuBoardView.lines { return }
        let index = row * GomokuBoardView.lines + col
        onTap?(index)
    }
}

/// 五子棋对局：原生棋盘 + 本地 AI（人机/双人），规则和 Windows 版一致。
final class GomokuViewController: UIViewController {
    private let header = PageHeader(title: "五子棋 · 人机对局", subtitle: "你执黑先行", showBack: true)
    private let board = GomokuBoardView()
    private let status = UILabel()
    private let restart = SoftButton()
    private let undo = SoftButton()

    private let playerFirst: Bool
    private let difficulty: Int
    private let vsComputer: Bool

    private var turn = 1
    private var over = false
    private var history: [Int] = []

    init(playerFirst: Bool, difficulty: Int, vsComputer: Bool) {
        self.playerFirst = playerFirst
        self.difficulty = difficulty
        self.vsComputer = vsComputer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        header.backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        view.addSubview(header)
        view.addSubview(board)
        view.addSubview(status)
        view.addSubview(restart)
        view.addSubview(undo)

        status.textColor = Theme.muted
        status.font = Theme.font(13)
        status.textAlignment = .center

        restart.setTitle("重新开始", for: .normal)
        restart.addTarget(self, action: #selector(tapRestart), for: .touchUpInside)
        undo.setTitle("悔棋", for: .normal)
        undo.addTarget(self, action: #selector(tapUndo), for: .touchUpInside)

        board.onTap = { [weak self] index in
            self?.humanPlace(index)
        }

        header.titleLabel.text = vsComputer ? "五子棋 · 人机对局" : "五子棋 · 双人对局"
        reset()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        header.frame = CGRect(x: 0, y: safeTop + 6, width: w, height: 60)
        let side = min(w - 24, view.bounds.height - safeTop - safeBottom - 260)
        board.frame = CGRect(x: (w - side) / 2, y: header.frame.maxY + 10, width: side, height: side)
        status.frame = CGRect(x: 20, y: board.frame.maxY + 10, width: w - 40, height: 22)
        let btnW = (w - 52) / 2
        restart.frame = CGRect(x: 16, y: status.frame.maxY + 10, width: btnW, height: 44)
        undo.frame = CGRect(x: 16 + btnW + 8, y: status.frame.maxY + 10, width: btnW, height: 44)
    }

    private func say(_ text: String, _ color: UIColor = Theme.muted) {
        status.textColor = color
        status.text = text
    }

    private func reset() {
        board.cells = [Int](repeating: 0, count: GomokuBoardView.lines * GomokuBoardView.lines)
        board.lastIndex = -1
        board.setNeedsDisplay()
        history.removeAll()
        over = false
        turn = 1
        if !vsComputer {
            say("双人模式：黑先白后，轮流落子。")
            return
        }
        if !playerFirst {
            say("电脑先手…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.computerMove(color: 1)
            }
        } else {
            say("你执黑先行，点棋盘落子。")
        }
    }

    private func humanColor() -> Int {
        if !vsComputer { return turn }
        return playerFirst ? 1 : 2
    }

    private func computerColor() -> Int { return 1 + 2 - humanColor0() }

    private func humanColor0() -> Int { return playerFirst ? 1 : 2 }

    private func humanPlace(_ index: Int) {
        if over || index < 0 || index >= board.cells.count { return }
        if board.cells[index] != 0 { return }
        if vsComputer && turn != humanColor0() { return }
        assign(index: index, color: turn)
        if over { return }
        if vsComputer {
            say("电脑正在想…")
            let cpu = 1 + 2 - humanColor0()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.computerMove(color: cpu)
            }
        }
    }

    private func computerMove(color: Int) {
        if over { return }
        let index = pickAiMove(color: color)
        if index < 0 { return }
        assign(index: index, color: color)
    }

    private func assign(index: Int, color: Int) {
        board.cells[index] = color
        board.lastIndex = index
        board.setNeedsDisplay()
        history.append(index)
        if isWin(index: index, color: color) {
            over = true
            if vsComputer {
                say(color == humanColor0() ? "你赢了！点「重新开始」再来。" : "电脑赢了。点「重新开始」再来。",
                    color == humanColor0() ? Theme.good : Theme.error)
            } else {
                say((color == 1 ? "黑棋" : "白棋") + "五连，本局结束。", Theme.good)
            }
            return
        }
        if history.count >= board.cells.count {
            over = true
            say("棋盘满了，和棋。", Theme.warn)
            return
        }
        turn = 1 + 2 - color
        if vsComputer {
            if turn == humanColor0() {
                say("轮到你了。")
            }
        } else {
            say("轮到" + (turn == 1 ? "黑方" : "白方") + "落子。")
        }
    }

    private func isWin(index: Int, color: Int) -> Bool {
        let n = GomokuBoardView.lines
        let x = index % n
        let y = index / n
        let dirs = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for (dx, dy) in dirs {
            var count = 1
            for sign in [1, -1] {
                var cx = x + dx * sign
                var cy = y + dy * sign
                while cx >= 0 && cy >= 0 && cx < n && cy < n && board.cells[cy * n + cx] == color {
                    count += 1
                    cx += dx * sign
                    cy += dy * sign
                }
            }
            if count >= 5 { return true }
        }
        return false
    }

    /// AI：先找自己能赢的点，再堵对方五连，剩下按难度随机/就近。
    private func pickAiMove(color: Int) -> Int {
        let opp = 1 + 2 - color
        let n = GomokuBoardView.lines
        var empties: [Int] = []
        for i in 0..<board.cells.count where board.cells[i] == 0 {
            empties.append(i)
        }
        if empties.isEmpty { return -1 }
        for i in empties {
            board.cells[i] = color
            let win = isWin(index: i, color: color)
            board.cells[i] = 0
            if win { return i }
        }
        for i in empties {
            board.cells[i] = opp
            let lose = isWin(index: i, color: opp)
            board.cells[i] = 0
            if lose { return i }
        }
        if difficulty <= 1 {
            return empties.randomElement() ?? -1
        }
        // 中等/困难/超凡：在已有棋子周围挑一个
        var near: [Int] = []
        for i in empties {
            let x = i % n
            let y = i / n
            var touch = false
            for dy in -1...1 {
                for dx in -1...1 {
                    if dx == 0 && dy == 0 { continue }
                    let nx = x + dx, ny = y + dy
                    if nx < 0 || ny < 0 || nx >= n || ny >= n { continue }
                    if board.cells[ny * n + nx] != 0 { touch = true }
                }
            }
            if touch { near.append(i) }
        }
        let pool = near.isEmpty ? empties : near
        if difficulty >= 3 && pool.contains(112) { return 112 }
        return pool.randomElement() ?? -1
    }

    @objc private func tapRestart() { reset() }

    @objc private func tapUndo() {
        if history.isEmpty { say("还没有可以悔的棋。", Theme.warn); return }
        let steps = vsComputer ? 2 : 1
        for _ in 0..<steps where !history.isEmpty {
            let last = history.removeLast()
            board.cells[last] = 0
        }
        board.lastIndex = history.last ?? -1
        board.setNeedsDisplay()
        over = false
        turn = 1
        say(vsComputer ? "已悔棋，轮到你。" : "已悔棋。")
    }

    @objc private func tapBack() {
        navigationController?.popViewController(animated: true)
    }
}
