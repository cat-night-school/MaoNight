import UIKit

// MARK: - 围棋

final class GoGamePage: MnPage {
    private let vsComputer: Bool
    private let playerFirst: Bool
    private let difficulty: Int
    private let board = GoBoard()
    private let status = UILabel()
    private let capLabel = UILabel()
    private var cells = [Int](repeating: 0, count: 361)   // 0 空 1 黑 2 白
    private var turn = 1
    private var passes = 0
    private var history: [(Int, [Int], Int)] = []          // index, cellsBefore, turn
    private var blackCaps = 0
    private var whiteCaps = 0
    private var over = false
    private var lastIndex = -1
    private var previousHash = ""
    private var boardHeight: NSLayoutConstraint?

    init(vsComputer: Bool, playerFirst: Bool, difficulty: Int) {
        self.vsComputer = vsComputer
        self.playerFirst = playerFirst
        self.difficulty = difficulty
        super.init(title: "围棋", subtitle: vsComputer ? "人机对战" : "本地双人", icon: "⚪")
    }

    required init?(coder: NSCoder) { fatalError() }

    private var humanColor: Int { return playerFirst ? 1 : 2 }

    override func viewDidLoad() {
        super.viewDidLoad()
        board.translatesAutoresizingMaskIntoConstraints = false
        board.onTap = { [weak self] i in self?.place(i) }
        add(board, gap: 10)
        boardHeight = board.heightAnchor.constraint(equalToConstant: 320)
        boardHeight?.isActive = true
        status.textAlignment = .center
        status.font = Theme.font(15, true)
        add(status, gap: 4)
        capLabel.textColor = Theme.faint
        capLabel.font = Theme.font(12)
        capLabel.textAlignment = .center
        add(capLabel, gap: 4)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, sel) in [("停一手", #selector(tapPass)), ("悔棋", #selector(tapUndo)), ("重新开始", #selector(tapReset))] {
            let b = SoftButton()
            b.setTitle(title, for: .normal)
            b.addTarget(self, action: sel, for: .touchUpInside)
            row.addArrangedSubview(b)
        }
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        add(row, gap: 10)
        paragraph("规则：19×19，提子按气计算，禁自杀与立即回提（简单劫争判定）；连续两次停一手进入数子。")
        reset()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let side = min(view.bounds.width - 24, view.bounds.height - 430)
        boardHeight?.constant = max(240, side)
    }

    private func reset() {
        cells = [Int](repeating: 0, count: 361)
        turn = 1; passes = 0; blackCaps = 0; whiteCaps = 0; over = false; lastIndex = -1
        history.removeAll(); previousHash = ""
        sync()
        status.textColor = Theme.ink
        status.text = vsComputer ? (playerFirst ? "你执黑先行" : "电脑执黑先行") : "黑方先行"
        if vsComputer && !playerFirst {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.computerMove() }
        }
    }

    private func sync() {
        board.cells = cells
        board.lastIndex = lastIndex
        board.setNeedsDisplay()
        capLabel.text = "黑提子 \(blackCaps) · 白提子 \(whiteCaps) · 第 \(history.count) 手"
    }

    private func place(_ index: Int) {
        if over || index < 0 || index >= 361 || cells[index] != 0 { return }
        if vsComputer && turn != humanColor { return }
        if !tryPlace(index, turn) { return }
        if over { return }
        if vsComputer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.computerMove() }
        }
    }

    /// 落子（含提子/禁自杀/简单劫争）；返回是否合法。
    @discardableResult
    private func tryPlace(_ index: Int, _ color: Int) -> Bool {
        let before = cells
        var b = cells
        b[index] = color
        let opp = 1 + 2 - color
        var captured = 0
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let nx = index % 19 + dx
            let ny = index / 19 + dy
            if nx < 0 || ny < 0 || nx >= 19 || ny >= 19 { continue }
            let ni = ny * 19 + nx
            if b[ni] == opp {
                let group = groupInfo(b, ni)
                if group.liberties == 0 {
                    for i in group.stones { b[i] = 0 }
                    captured += group.stones.count
                }
            }
        }
        let own = groupInfo(b, index)
        if own.liberties == 0 { return false }
        let hash = b.map { String($0) }.joined()
        if hash == previousHash { return false }   // 简单劫争
        previousHash = before.map { String($0) }.joined()
        history.append((index, before, turn))
        cells = b
        lastIndex = index
        passes = 0
        if color == 1 { blackCaps += captured } else { whiteCaps += captured }
        turn = opp
        over = false
        sync()
        status.textColor = Theme.ink
        status.text = (turn == 1 ? "黑方" : "白方") + "落子"
        if vsComputer { status.text = (turn == humanColor ? "轮到你了" : "电脑思考中…") }
        if vsComputer && turn != humanColor {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.computerMove() }
        }
        return true
    }

    private func groupInfo(_ b: [Int], _ start: Int) -> (stones: [Int], liberties: Int) {
        let color = b[start]
        var stones: [Int] = []
        var libs = Set<Int>()
        var seen = Set<Int>()
        var stack = [start]
        while let cur = stack.popLast() {
            if seen.contains(cur) { continue }
            seen.insert(cur)
            if b[cur] == color { stones.append(cur) } else { continue }
            let x = cur % 19, y = cur / 19
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = x + dx, ny = y + dy
                if nx < 0 || ny < 0 || nx >= 19 || ny >= 19 { continue }
                let ni = ny * 19 + nx
                if b[ni] == 0 { libs.insert(ni) } else if b[ni] == color { stack.append(ni) }
            }
        }
        return (stones, libs.count)
    }

    private func computerMove() {
        guard !over else { return }
        let color = 1 + 2 - humanColor
        var candidates: [Int] = []
        for i in 0..<361 where cells[i] == 0 {
            let x = i % 19, y = i / 19
            var near = false
            for dy in -1...1 {
                for dx in -1...1 {
                    if dx == 0 && dy == 0 { continue }
                    let nx = x + dx, ny = y + dy
                    if nx < 0 || ny < 0 || nx >= 19 || ny >= 19 { continue }
                    if cells[ny * 19 + nx] != 0 { near = true }
                }
            }
            if near { candidates.append(i) }
        }
        if candidates.isEmpty { candidates = [Int](0..<361).filter { cells[$0] == 0 } }
        if candidates.isEmpty { return }
        candidates.shuffle()
        for i in candidates.prefix(30) {
            if isValidPlace(i, color) {
                tryPlace(i, color)
                return
            }
        }
        _ = passMove()
    }

    private func isValidPlace(_ index: Int, _ color: Int) -> Bool {
        if cells[index] != 0 { return false }
        var b = cells
        b[index] = color
        let opp = 1 + 2 - color
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let nx = index % 19 + dx, ny = index / 19 + dy
            if nx < 0 || ny < 0 || nx >= 19 || ny >= 19 { continue }
            let ni = ny * 19 + nx
            if b[ni] == opp {
                let g = groupInfo(b, ni)
                if g.liberties == 0 { for i in g.stones { b[i] = 0 } }
            }
        }
        let own = groupInfo(b, index)
        return own.liberties > 0
    }

    @objc private func tapPass() { _ = passMove() }

    @discardableResult
    private func passMove() -> Bool {
        guard !over else { return true }
        passes += 1
        if passes >= 2 {
            finishByScore()
            return true
        }
        turn = 1 + 2 - turn
        status.text = "轮到" + (turn == 1 ? "黑方" : "白方") + "（已停一手 \(passes) 次）"
        if vsComputer && turn != humanColor {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.computerMove() }
        }
        return false
    }

    private func finishByScore() {
        over = true
        var blackArea = 0
        var whiteArea = 0
        var visited = Set<Int>()
        for i in 0..<361 where !visited.contains(i) {
            if cells[i] != 0 {
                visited.insert(i)
                continue
            }
            var region = [i]
            var borderColors = Set<Int>()
            visited.insert(i)
            var stack = [i]
            while let cur = stack.popLast() {
                let x = cur % 19, y = cur / 19
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let nx = x + dx, ny = y + dy
                    if nx < 0 || ny < 0 || nx >= 19 || ny >= 19 { continue }
                    let ni = ny * 19 + nx
                    if cells[ni] == 0 {
                        if !visited.contains(ni) { visited.insert(ni); stack.append(ni); region.append(ni) }
                    } else {
                        borderColors.insert(cells[ni])
                    }
                }
            }
            if borderColors.count == 1 {
                if borderColors.first == 1 { blackArea += region.count } else { whiteArea += region.count }
            }
        }
        for c in cells {
            if c == 1 { blackArea += 1 } else if c == 2 { whiteArea += 1 }
        }
        over = true
        let result = blackArea > whiteArea ? "黑棋胜 \(blackArea):\(whiteArea)" : (whiteArea > blackArea ? "白棋胜 \(whiteArea):\(blackArea)" : "和棋 \(blackArea):\(whiteArea)")
        status.textColor = Theme.good
        status.text = result
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @objc private func tapUndo() {
        guard let last = history.popLast() else { return }
        cells = last.1
        turn = last.2
        passes = 0
        over = false
        lastIndex = history.last?.0 ?? -1
        sync()
        status.text = "已悔棋"
    }

    @objc private func tapReset() { reset() }
}

final class GoBoard: UIView {
    var cells = [Int](repeating: 0, count: 361)
    var lastIndex = -1
    var onTap: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }

    required init?(coder: NSCoder) { fatalError() }

    private func geom() -> (origin: CGPoint, step: CGFloat) {
        let pad: CGFloat = 16
        let side = min(bounds.width, bounds.height) - pad * 2
        let step = side / 18.0
        return (CGPoint(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2), step)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let g = geom()
        let bg = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 14)
        UIColor(red: 0.91, green: 0.80, blue: 0.56, alpha: 1).setFill()
        bg.fill()
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.26, blue: 0.14, alpha: 1).cgColor)
        ctx.setLineWidth(0.8)
        for i in 0..<19 {
            let x = g.origin.x + CGFloat(i) * g.step
            let y = g.origin.y + CGFloat(i) * g.step
            ctx.move(to: CGPoint(x: x, y: g.origin.y))
            ctx.addLine(to: CGPoint(x: x, y: g.origin.y + 18 * g.step))
            ctx.move(to: CGPoint(x: g.origin.x, y: y))
            ctx.addLine(to: CGPoint(x: g.origin.x + 18 * g.step, y: y))
        }
        ctx.strokePath()
        ctx.setFillColor(UIColor(red: 0.28, green: 0.20, blue: 0.10, alpha: 1).cgColor)
        for (c, r) in [(3, 3), (9, 3), (15, 3), (3, 9), (9, 9), (15, 9), (3, 15), (9, 15), (15, 15)] {
            let p = CGPoint(x: g.origin.x + CGFloat(c) * g.step, y: g.origin.y + CGFloat(r) * g.step)
            ctx.fillEllipse(in: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5))
        }
        let stoneR = g.step * 0.46
        for i in 0..<361 where cells[i] != 0 {
            let p = CGPoint(x: g.origin.x + CGFloat(i % 19) * g.step, y: g.origin.y + CGFloat(i / 19) * g.step)
            let r = CGRect(x: p.x - stoneR, y: p.y - stoneR, width: stoneR * 2, height: stoneR * 2)
            UIColor(white: 0, alpha: 0.15).setFill()
            ctx.fillEllipse(in: r.offsetBy(dx: 1, dy: 1.5))
            if cells[i] == 1 { UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1).setFill() } else { UIColor(white: 0.98, alpha: 1).setFill() }
            ctx.fillEllipse(in: r)
        }
        if lastIndex >= 0 {
            let p = CGPoint(x: g.origin.x + CGFloat(lastIndex % 19) * g.step, y: g.origin.y + CGFloat(lastIndex / 19) * g.step)
            ctx.setStrokeColor(UIColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.4)
            ctx.strokeEllipse(in: CGRect(x: p.x - stoneR, y: p.y - stoneR, width: stoneR * 2, height: stoneR * 2))
        }
    }

    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        let p = gesture.location(in: self)
        let g = geom()
        let col = Int(round((p.x - g.origin.x) / g.step))
        let row = Int(round((p.y - g.origin.y) / g.step))
        if col < 0 || row < 0 || col >= 19 || row >= 19 { return }
        onTap?(row * 19 + col)
    }
}

// MARK: - 象棋

final class XiangqiGamePage: MnPage {
    private let vsComputer: Bool
    private let playerFirst: Bool
    private let difficulty: Int
    private let board = XiangqiBoardView()
    private let status = UILabel()
    private var cells = [Int](repeating: 0, count: 90)
    private var turn = 1          // 1 红 2 黑
    private var over = false
    private var history: [(Int, Int, [Int])] = []
    private var selected: Int = -1
    private var boardHeight: NSLayoutConstraint?

    init(vsComputer: Bool, playerFirst: Bool, difficulty: Int) {
        self.vsComputer = vsComputer
        self.playerFirst = playerFirst
        self.difficulty = difficulty
        super.init(title: "象棋", subtitle: vsComputer ? "人机对战" : "本地双人", icon: "🔴")
    }

    required init?(coder: NSCoder) { fatalError() }

    private var humanColor: Int { return playerFirst ? 1 : 2 }

    override func viewDidLoad() {
        super.viewDidLoad()
        board.translatesAutoresizingMaskIntoConstraints = false
        board.onTap = { [weak self] i in self?.tapCell(i) }
        add(board, gap: 10)
        boardHeight = board.heightAnchor.constraint(equalToConstant: 320)
        boardHeight?.isActive = true
        status.textAlignment = .center
        status.font = Theme.font(15, true)
        add(status, gap: 4)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, sel) in [("悔棋", #selector(tapUndo)), ("重新开始", #selector(tapReset))] {
            let b = SoftButton()
            b.setTitle(title, for: .normal)
            b.addTarget(self, action: sel, for: .touchUpInside)
            row.addArrangedSubview(b)
        }
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        add(row, gap: 10)
        paragraph("规则：马走日（蹩腿）、象走田（塞眼、不过河）、炮隔一子吃、车直行、士/将九宫、兵过河可横走；被将军时必须应将，将死或困毙判负。")
        reset()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width - 24
        boardHeight?.constant = min(w * 1.12, view.bounds.height - 430)
    }

    private func reset() {
        // 红方在下（y 7~9），黑方在上（y 0~2）；编码 1 帥 2 仕 3 相 4 馬 5 車 6 炮 7 兵，黑方 +7
        var b = [Int](repeating: 0, count: 90)
        b[0 * 9 + 0] = 12; b[0 * 9 + 1] = 11; b[0 * 9 + 2] = 10; b[0 * 9 + 3] = 9; b[0 * 9 + 4] = 8
        b[0 * 9 + 5] = 9; b[0 * 9 + 6] = 10; b[0 * 9 + 7] = 11; b[0 * 9 + 8] = 12
        b[2 * 9 + 1] = 13; b[2 * 9 + 7] = 13
        b[3 * 9 + 0] = 14; b[3 * 9 + 2] = 14; b[3 * 9 + 4] = 14; b[3 * 9 + 6] = 14; b[3 * 9 + 8] = 14
        b[9 * 9 + 0] = 5; b[9 * 9 + 1] = 4; b[9 * 9 + 2] = 3; b[9 * 9 + 3] = 2; b[9 * 9 + 4] = 1
        b[9 * 9 + 5] = 2; b[9 * 9 + 6] = 3; b[9 * 9 + 7] = 4; b[9 * 9 + 8] = 5
        b[7 * 9 + 1] = 6; b[7 * 9 + 7] = 6
        b[6 * 9 + 0] = 7; b[6 * 9 + 2] = 7; b[6 * 9 + 4] = 7; b[6 * 9 + 6] = 7; b[6 * 9 + 8] = 7
        cells = b
        turn = 1
        over = false
        selected = -1
        history.removeAll()
        sync()
        status.textColor = Theme.ink
        status.text = vsComputer ? (playerFirst ? "你执红先行" : "电脑执红先行") : "红方先行"
        if vsComputer && !playerFirst {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.computerMove() }
        }
    }

    private func sync() {
        board.cells = cells
        board.selected = selected
        board.setNeedsDisplay()
    }

    private func tapCell(_ index: Int) {
        if over { return }
        if vsComputer && turn != humanColor { return }
        if selected == -1 {
            if cells[index] != 0 && colorOf(cells[index]) == turn {
                selected = index
                sync()
            }
            return
        }
        if selected == index {
            selected = -1
            sync()
            return
        }
        if cells[index] != 0 && colorOf(cells[index]) == turn {
            selected = index
            sync()
            return
        }
        let from = selected
        if legalMoves(from: from).contains(index) {
            selected = -1
            applyMove(from: from, to: index)
        } else {
            status.textColor = Theme.warn
            status.text = "这一步不合规则"
        }
    }

    private func colorOf(_ piece: Int) -> Int {
        if piece == 0 { return 0 }
        return piece <= 7 ? 1 : 2
    }

    private func applyMove(from: Int, to: Int) {
        let before = cells
        let captured = cells[to]
        cells[to] = cells[from]
        cells[from] = 0
        history.append((from, to, before))
        if captured == 1 || captured == 8 {
            over = true
            sync()
            status.textColor = Theme.good
            status.text = captured == 8 ? "红方胜（擒将）" : "黑方胜（擒帅）"
            return
        }
        turn = 1 + 2 - turn
        sync()
        status.textColor = Theme.ink
        if vsComputer {
            status.text = turn == humanColor ? "轮到你了" : "电脑思考中…"
            if turn != humanColor {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.computerMove() }
            }
        } else {
            status.text = turn == 1 ? "轮到红方" : "轮到黑方"
        }
        if legalMovesFor(color: turn).isEmpty {
            over = true
            status.textColor = Theme.good
            status.text = (turn == 1 ? "黑方" : "红方") + "胜（将死/困毙）"
        }
    }

    private func computerMove() {
        guard !over else { return }
        let color = turn
        var moves: [(Int, Int, Int)] = []   // from, to, score
        for from in 0..<90 where cells[from] != 0 && colorOf(cells[from]) == color {
            for to in legalMoves(from: from) {
                var score = 0
                if cells[to] != 0 { score += pieceValue(cells[to]) }
                let x = to % 9, y = to / 9
                score += (4 - abs(x - 4)) + (color == 1 ? (y < 5 ? 4 : 0) : (y > 4 ? 4 : 0))
                moves.append((from, to, score))
            }
        }
        if moves.isEmpty { over = true; status.text = "无棋可走，结束"; return }
        if difficulty >= 3 {
            moves.sort { $0.2 > $1.2 }
            let top = moves.prefix(3)
            if let pick = top.randomElement() {
                applyMove(from: pick.0, to: pick.1)
                return
            }
        }
        if let pick = moves.randomElement() { applyMove(from: pick.0, to: pick.1) }
    }

    private func pieceValue(_ piece: Int) -> Int {
        let base = piece > 7 ? piece - 7 : piece
        switch base {
        case 1: return 1000
        case 2, 3: return 30
        case 4: return 45
        case 5: return 90
        case 6: return 50
        default: return 10
        }
    }

    private func legalMovesFor(color: Int) -> [Int] {
        var result: [Int] = []
        for from in 0..<90 where cells[from] != 0 && colorOf(cells[from]) == color {
            result.append(contentsOf: legalMoves(from: from))
        }
        return result
    }

    /// 某棋子的所有合法走法（含“不能送将/被将时必须应将”）。
    func legalMoves(from: Int) -> [Int] {
        let piece = cells[from]
        if piece == 0 { return [] }
        let color = colorOf(piece)
        let base = color == 1 ? piece : piece - 7
        let x = from % 9
        let y = from / 9
        var targets: [Int] = []
        func add(_ nx: Int, _ ny: Int) {
            if nx < 0 || ny < 0 || nx >= 9 || ny >= 10 { return }
            let ni = ny * 9 + nx
            if cells[ni] != 0 && colorOf(cells[ni]) == color { return }
            targets.append(ni)
        }
        switch base {
        case 1: // 将/帅
            for (dx, dy) in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
                let nx = x + dx, ny = y + dy
                if inPalace(nx, ny, color) { add(nx, ny) }
            }
        case 2: // 士/仕
            for (dx, dy) in [(1, 1), (1, -1), (-1, 1), (-1, -1)] {
                let nx = x + dx, ny = y + dy
                if inPalace(nx, ny, color) { add(nx, ny) }
            }
        case 3: // 象/相
            for (dx, dy) in [(2, 2), (2, -2), (-2, 2), (-2, -2)] {
                let nx = x + dx, ny = y + dy
                if nx < 0 || ny < 0 || nx >= 9 || ny >= 10 { continue }
                if color == 1 && ny < 5 { continue }
                if color == 2 && ny > 4 { continue }
                if cells[(y + dy / 2) * 9 + (x + dx / 2)] != 0 { continue }
                add(nx, ny)
            }
        case 4: // 马
            for (dx, dy, lx, ly) in [(1, 2, 0, 1), (-1, 2, 0, 1), (1, -2, 0, -1), (-1, -2, 0, -1),
                                     (2, 1, 1, 0), (2, -1, 1, 0), (-2, 1, -1, 0), (-2, -1, -1, 0)] {
                let nx = x + dx, ny = y + dy
                if nx < 0 || ny < 0 || nx >= 9 || ny >= 10 { continue }
                if cells[(y + ly) * 9 + (x + lx)] != 0 { continue }
                add(nx, ny)
            }
        case 5: // 车
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                var nx = x + dx, ny = y + dy
                while nx >= 0 && ny >= 0 && nx < 9 && ny < 10 {
                    let ni = ny * 9 + nx
                    if cells[ni] == 0 { targets.append(ni) }
                    else {
                        if colorOf(cells[ni]) != color { targets.append(ni) }
                        break
                    }
                    nx += dx; ny += dy
                }
            }
        case 6: // 炮
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                var nx = x + dx, ny = y + dy
                var screen = false
                while nx >= 0 && ny >= 0 && nx < 9 && ny < 10 {
                    let ni = ny * 9 + nx
                    if !screen {
                        if cells[ni] == 0 { targets.append(ni) }
                        else { screen = true }
                    } else {
                        if cells[ni] != 0 {
                            if colorOf(cells[ni]) != color { targets.append(ni) }
                            break
                        }
                    }
                    nx += dx; ny += dy
                }
            }
        case 7: // 兵/卒
            let forward = color == 1 ? -1 : 1
            add(x, y + forward)
            let crossed = color == 1 ? y <= 4 : y >= 5
            if crossed {
                add(x - 1, y); add(x + 1, y)
            }
        default:
            break
        }
        // 过滤：走完不能让自己被将军
        return targets.filter { to in
            var b = cells
            b[to] = b[from]
            b[from] = 0
            return !isChecked(b, color: color)
        }
    }

    private func inPalace(_ x: Int, _ y: Int, _ color: Int) -> Bool {
        if x < 3 || x > 5 { return false }
        if color == 1 { return y >= 7 && y <= 9 }
        return y >= 0 && y <= 2
    }

    private func generalIndex(_ b: [Int], _ color: Int) -> Int {
        let target = color == 1 ? 1 : 8
        for i in 0..<90 where b[i] == target { return i }
        return -1
    }

    private func isChecked(_ b: [Int], color: Int) -> Bool {
        let gi = generalIndex(b, color)
        if gi < 0 { return false }
        let gx = gi % 9, gy = gi / 9
        let opp = 1 + 2 - color
        // 车 / 炮 / 兵 / 将 / 马 检查（够用）
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            var nx = gx + dx, ny = gy + dy
            var screen = 0
            while nx >= 0 && ny >= 0 && nx < 9 && ny < 10 {
                let ni = ny * 9 + nx
                let p = b[ni]
                if p != 0 {
                    if colorOf(p) == opp {
                        let base = p > 7 ? p - 7 : p
                        if screen == 0 && (base == 5 || base == 1) { return true }
                        if screen == 1 && base == 6 { return true }
                    }
                    screen += 1
                    if screen >= 2 { break }
                }
                nx += dx; ny += dy
            }
        }
        // 兵/卒贴脸
        let forward = color == 1 ? 1 : -1
        for (dx, dy) in [(0, forward), (1, 0), (-1, 0)] {
            let nx = gx + dx, ny = gy + dy
            if nx < 0 || ny < 0 || nx >= 9 || ny >= 10 { continue }
            let p = b[ny * 9 + nx]
            if p == (opp == 1 ? 7 : 14) { return true }
        }
        // 马
        for (dx, dy, lx, ly) in [(1, 2, 0, 1), (-1, 2, 0, 1), (1, -2, 0, -1), (-1, -2, 0, -1),
                                 (2, 1, 1, 0), (2, -1, 1, 0), (-2, 1, -1, 0), (-2, -1, -1, 0)] {
            let nx = gx + dx, ny = gy + dy
            if nx < 0 || ny < 0 || nx >= 9 || ny >= 10 { continue }
            let p = b[ny * 9 + nx]
            let base = p > 7 ? p - 7 : p
            if p != 0 && colorOf(p) == opp && base == 4 {
                if b[(gy + ly) * 9 + (gx + lx)] == 0 { return true }
            }
        }
        return false
    }

    @objc private func tapUndo() {
        guard let last = history.popLast() else { return }
        cells = last.2
        over = false
        selected = -1
        turn = turn == 1 ? 2 : 1
        sync()
        status.text = "已悔棋"
    }

    @objc private func tapReset() { reset() }
}

/// 象棋棋盘：木色 + 楚河汉界 + 九宫斜线 + 棋子（汉字）。
final class XiangqiBoardView: UIView {
    var cells = [Int](repeating: 0, count: 90)
    var selected = -1
    var onTap: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }

    required init?(coder: NSCoder) { fatalError() }

    private func geom() -> (origin: CGPoint, dx: CGFloat, dy: CGFloat) {
        let pad: CGFloat = 20
        let w = bounds.width - pad * 2
        let h = bounds.height - pad * 2
        let dx = w / 8
        let dy = h / 9
        return (CGPoint(x: pad, y: pad), dx, dy)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let g = geom()
        let bg = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 14)
        UIColor(red: 0.89, green: 0.78, blue: 0.55, alpha: 1).setFill()
        bg.fill()
        ctx.setStrokeColor(UIColor(red: 0.36, green: 0.26, blue: 0.13, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        // 横线
        for y in 0..<10 {
            ctx.move(to: CGPoint(x: g.origin.x, y: g.origin.y + CGFloat(y) * g.dy))
            ctx.addLine(to: CGPoint(x: g.origin.x + 8 * g.dx, y: g.origin.y + CGFloat(y) * g.dy))
        }
        // 竖线（河界断开）
        for x in 0..<9 {
            if x == 0 || x == 8 {
                ctx.move(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y))
                ctx.addLine(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y + 9 * g.dy))
            } else {
                ctx.move(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y))
                ctx.addLine(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y + 4 * g.dy))
                ctx.move(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y + 5 * g.dy))
                ctx.addLine(to: CGPoint(x: g.origin.x + CGFloat(x) * g.dx, y: g.origin.y + 9 * g.dy))
            }
        }
        // 九宫斜线
        ctx.move(to: CGPoint(x: g.origin.x + 3 * g.dx, y: g.origin.y))
        ctx.addLine(to: CGPoint(x: g.origin.x + 5 * g.dx, y: g.origin.y + 2 * g.dy))
        ctx.move(to: CGPoint(x: g.origin.x + 5 * g.dx, y: g.origin.y))
        ctx.addLine(to: CGPoint(x: g.origin.x + 3 * g.dx, y: g.origin.y + 2 * g.dy))
        ctx.move(to: CGPoint(x: g.origin.x + 3 * g.dx, y: g.origin.y + 7 * g.dy))
        ctx.addLine(to: CGPoint(x: g.origin.x + 5 * g.dx, y: g.origin.y + 9 * g.dy))
        ctx.move(to: CGPoint(x: g.origin.x + 5 * g.dx, y: g.origin.y + 7 * g.dy))
        ctx.addLine(to: CGPoint(x: g.origin.x + 3 * g.dx, y: g.origin.y + 9 * g.dy))
        ctx.strokePath()

        // 楚河汉界
        let riverY = g.origin.y + 4.5 * g.dy
        let riverAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor(red: 0.36, green: 0.26, blue: 0.13, alpha: 0.9)
        ]
        ("楚 河" as NSString).draw(at: CGPoint(x: g.origin.x + g.dx, y: riverY - 10), withAttributes: riverAttrs)
        ("汉 界" as NSString).draw(at: CGPoint(x: g.origin.x + 5 * g.dx, y: riverY - 10), withAttributes: riverAttrs)

        let stoneR = min(g.dx, g.dy) * 0.42
        for i in 0..<90 where cells[i] != 0 {
            let x = g.origin.x + CGFloat(i % 9) * g.dx
            let y = g.origin.y + CGFloat(i / 9) * g.dy
            let r = CGRect(x: x - stoneR, y: y - stoneR, width: stoneR * 2, height: stoneR * 2)
            let red = cells[i] <= 7
            UIColor(red: 0.98, green: 0.95, blue: 0.86, alpha: 1).setFill()
            ctx.fillEllipse(in: r)
            UIColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 1).setStroke()
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: r)
            let names = ["帥", "仕", "相", "馬", "車", "炮", "兵"]
            let namesBlack = ["將", "士", "象", "馬", "車", "砲", "卒"]
            let base = red ? cells[i] : cells[i] - 7
            let text = red ? names[max(0, min(6, base - 1))] : namesBlack[max(0, min(6, base - 1))]
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: stoneR * 1.15, weight: .bold),
                .foregroundColor: red ? UIColor(red: 0.75, green: 0.18, blue: 0.16, alpha: 1) : UIColor(red: 0.16, green: 0.16, blue: 0.20, alpha: 1)
            ]
            let size = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(at: CGPoint(x: x - size.width / 2, y: y - size.height / 2), withAttributes: attrs)
        }
        if selected >= 0 && selected < 90 {
            let x = g.origin.x + CGFloat(selected % 9) * g.dx
            let y = g.origin.y + CGFloat(selected / 9) * g.dy
            ctx.setStrokeColor(UIColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 0.95).cgColor)
            ctx.setLineWidth(2.4)
            ctx.strokeEllipse(in: CGRect(x: x - stoneR - 2, y: y - stoneR - 2, width: (stoneR + 2) * 2, height: (stoneR + 2) * 2))
        }
    }

    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        let p = gesture.location(in: self)
        let g = geom()
        let col = Int(round((p.x - g.origin.x) / g.dx))
        let row = Int(round((p.y - g.origin.y) / g.dy))
        if col < 0 || row < 0 || col >= 9 || row >= 10 { return }
        onTap?(row * 9 + col)
    }
}
