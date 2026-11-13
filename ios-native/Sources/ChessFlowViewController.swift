import UIKit

/// 棋类训练：照原版五步流程 —— 选棋种 → 模式 → 难度 → 先后手 / 联机房间。
/// 全部原生控件，没有网页。
final class ChessFlowViewController: UIViewController {
    private let header = PageHeader(title: "棋类训练", subtitle: "选择棋种", showBack: true, icon: "♟")
    private let body = UIView()

    private let games: [(icon: String, name: String, spec: String)] = [
        ("⚫", "五子棋", "15×15 · 先手执黑 · 4 档 AI"),
        ("⚪", "围棋", "19×19 · 先手执黑 · 贴 6 目"),
        ("🔴", "象棋", "9×10 · 先手执红 · 楚河汉界")
    ]
    private let modes = ["人机对战", "本地双人", "联机对战"]
    private let diffs = ["简单", "中等", "困难", "超凡"]
    private let sides = ["先手（黑棋）", "后手（白棋）"]
    private let rooms = ["创建房间", "加入房间"]

    private var step = 0          // 0 棋种 1 模式 2 难度 3 先后手 4 房间
    private var game = 0
    private var mode = 0
    private var difficulty = 1
    private var playerFirst = true

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)
        view.addSubview(header)
        view.addSubview(body)
        header.backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        rebuild()
    }

    private var subtitle: String {
        if step == 0 { return "选择棋种" }
        let name = games[game].name
        switch step {
        case 1: return name + " · 选择模式"
        case 2: return name + " · 选择 AI 难度"
        case 3: return name + " · 选择先后手"
        default: return name + " · 联机对战"
        }
    }

    private var rows: [String] {
        switch step {
        case 1: return modes
        case 2: return diffs
        case 3: return sides
        case 4: return rooms
        default: return []
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        header.frame = CGRect(x: 0, y: safeTop + 4, width: w, height: 92)
        body.frame = CGRect(x: 0, y: header.frame.maxY + 6, width: w, height: view.bounds.height - header.frame.maxY - 6)
    }

    private func rebuild() {
        header.titleLabel.text = "棋类训练"
        header.subtitleLabel.text = subtitle
        for sub in body.subviews { sub.removeFromSuperview() }
        let w = body.bounds.width > 0 ? body.bounds.width : UIScreen.main.bounds.width
        let colW = min(w - 32, 560)
        let x0 = (w - colW) / 2
        var y: CGFloat = 12

        if step == 0 {
            for (index, item) in games.enumerated() {
                let card = GlassCard(radius: 20)
                card.frame = CGRect(x: x0, y: y, width: colW, height: 84)
                let icon = UILabel(frame: CGRect(x: 16, y: 20, width: 44, height: 44))
                icon.text = item.icon
                icon.font = Theme.font(26)
                icon.textAlignment = .center
                icon.textColor = Theme.ink
                card.addSubview(icon)
                let name = UILabel(frame: CGRect(x: 70, y: 18, width: colW - 90, height: 24))
                name.text = item.name
                name.textColor = Theme.ink
                name.font = Theme.font(16, true)
                card.addSubview(name)
                let spec = UILabel(frame: CGRect(x: 70, y: 44, width: colW - 90, height: 20))
                spec.text = item.spec
                spec.textColor = Theme.muted
                spec.font = Theme.font(12)
                card.addSubview(spec)
                let tap = UITapGestureRecognizer(target: self, action: #selector(tapGame(_:)))
                card.isUserInteractionEnabled = true
                card.tag = index
                card.addGestureRecognizer(tap)
                body.addSubview(card)
                y += 96
            }
        } else {
            for (index, title) in rows.enumerated() {
                let b = AccentButton()
                b.frame = CGRect(x: x0, y: y, width: colW, height: 50)
                b.setTitle(title, for: .normal)
                b.tag = index
                b.addTarget(self, action: #selector(tapRow(_:)), for: .touchUpInside)
                body.addSubview(b)
                y += 58
            }
            let back = SoftButton()
            back.frame = CGRect(x: x0, y: y + 6, width: colW, height: 44)
            back.setTitle(step == 1 ? "← 返回选棋种" : "← 返回选模式", for: .normal)
            back.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
            body.addSubview(back)
        }
    }

    @objc private func tapBack() {
        if step == 0 {
            navigationController?.popViewController(animated: true)
            return
        }
        if step == 1 { step = 0; game = 0 }
        else if step == 2 { step = 1 }
        else if step == 3 { step = mode == 0 ? 2 : 1 }
        else { step = 1 }
        rebuild()
        view.setNeedsLayout()
    }

    @objc private func tapGame(_ gesture: UITapGestureRecognizer) {
        game = gesture.view?.tag ?? 0
        step = 1
        rebuild()
    }

    @objc private func tapRow(_ sender: UIButton) {
        let index = sender.tag
        switch step {
        case 1:
            mode = index
            if mode == 0 { step = 2 } else if mode == 1 { step = 3 } else { step = 4 }
            rebuild()
        case 2:
            difficulty = index + 1
            step = 3
            rebuild()
        case 3:
            playerFirst = index == 0
            launch()
        default:
            launch()
        }
    }

    private func launch() {
        if mode == 2 {
            showSoon(title: "联机对战")
            return
        }
        if game == 0 {
            let vc = GomokuViewController(playerFirst: playerFirst, difficulty: difficulty,
                                           vsComputer: mode == 0)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            showSoon(title: games[game].name)
        }
    }

    private func showSoon(title: String) {
        navigationController?.pushViewController(ComingSoonViewController(title: title), animated: true)
    }
}
