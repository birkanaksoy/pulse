import SwiftUI
import AppKit

// MARK: - Brand

let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)
let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
let fair = Color(red: 0.961, green: 0.647, blue: 0.141)
let critical = Color(red: 0.937, green: 0.267, blue: 0.267)
let textPrimary = Color(red: 0.043, green: 0.071, blue: 0.125)
let textSecondary = Color(red: 0.361, green: 0.392, blue: 0.451)
let textTertiary = Color(red: 0.565, green: 0.596, blue: 0.651)
let stroke = Color(red: 0.933, green: 0.941, blue: 0.957)
let muted = Color(red: 0.969, green: 0.973, blue: 0.980)

let ringGrad = LinearGradient(colors: [blue500, blue300], startPoint: .topLeading, endPoint: .bottomTrailing)

// MARK: - Screenshot frame (1290x2796 — iPhone 6.9")

struct Screenshot<Scene: View>: View {
    var caption: String
    var subtitle: String
    var tint: Color = blue500
    @ViewBuilder var scene: () -> Scene

    var body: some View {
        ZStack {
            // Ambient backdrop
            LinearGradient(
                colors: [tint.opacity(0.08), Color.white, tint.opacity(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 120)
                VStack(spacing: 16) {
                    Text(caption)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                    Text(subtitle)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)
                }
                Spacer().frame(height: 80)
                deviceFrame {
                    scene()
                }
                Spacer()
            }
        }
        .frame(width: 1290, height: 2796)
    }

    @ViewBuilder
    private func deviceFrame<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 92, style: .continuous)
                .fill(Color.black)
                .frame(width: 1020, height: 2070)
                .shadow(color: .black.opacity(0.18), radius: 60, y: 30)
            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(Color.white)
                .frame(width: 990, height: 2040)
            content()
                .frame(width: 990, height: 2040)
                .clipShape(RoundedRectangle(cornerRadius: 80, style: .continuous))
        }
    }
}

// MARK: - Pulse Ring helper

struct BigRing: View {
    var score: Int
    var size: CGFloat = 480
    var body: some View {
        let progress = Double(score) / 100.0
        ZStack {
            Circle().stroke(stroke, lineWidth: 22)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringGrad, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: blue500.opacity(0.25), radius: 20, y: 8)
            VStack(spacing: 6) {
                Text("\(score)").font(.system(size: 130, weight: .semibold, design: .rounded))
                    .foregroundStyle(textPrimary)
                Text("PULSE").font(.system(size: 18, weight: .semibold)).tracking(4)
                    .foregroundStyle(textTertiary)
                Text(statusLabel(score)).font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(statusColor(score))
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(Capsule().fill(statusColor(score).opacity(0.12)))
            }
        }
        .frame(width: size, height: size)
    }
}

func statusLabel(_ s: Int) -> String {
    switch s { case 85...: return "Excellent"; case 65...: return "Good"; case 40...: return "Fair"; default: return "Critical" }
}
func statusColor(_ s: Int) -> Color {
    switch s { case 85...: return excellent; case 65...: return blue500; case 40...: return fair; default: return critical }
}

// MARK: - Mock screens

struct MetricCard: View {
    var icon: String, title: String, value: String, status: String, color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon).font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(ringGrad, in: RoundedRectangle(cornerRadius: 16))
                Spacer()
                Circle().fill(color).frame(width: 12, height: 12)
            }
            Text(value).font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(textPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 22, weight: .regular)).foregroundStyle(textSecondary)
                Text(status).font(.system(size: 18)).foregroundStyle(textTertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(stroke))
    }
}

struct HomeMock: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 140)
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning").font(.system(size: 22)).foregroundStyle(textTertiary)
                Text("Your Pulse").font(.system(size: 46, weight: .bold)).foregroundStyle(textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 60)
            BigRing(score: 86)
            HStack(spacing: 18) {
                MetricCard(icon: "internaldrive", title: "Storage", value: "54%", status: "Used", color: blue500)
                MetricCard(icon: "thermometer.medium", title: "Temperature", value: "Normal", status: "System thermal", color: excellent)
            }
            .padding(.horizontal, 60)
            Spacer()
        }
        .background(muted)
    }
}

struct MetricsMock: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 200)
            HStack(spacing: 22) {
                MetricCard(icon: "internaldrive", title: "Storage", value: "54%", status: "Used", color: blue500)
                MetricCard(icon: "thermometer.medium", title: "Temperature", value: "Normal", status: "System thermal", color: excellent)
            }
            HStack(spacing: 22) {
                MetricCard(icon: "battery.75percent", title: "Battery", value: "82%", status: "Charging", color: blue500)
                MetricCard(icon: "leaf", title: "Low Power", value: "Off", status: "iOS power saver", color: excellent)
            }
            Spacer()
        }
        .padding(.horizontal, 60)
        .background(muted)
    }
}

struct InsightsMock: View {
    let rows: [(String, String)] = [
        ("internaldrive", "Storage at 54% — comfortable"),
        ("leaf", "Low Power Mode is on"),
        ("arrow.up.right", "Score rose 7 over your last 3 scans"),
        ("checkmark.circle", "Thermal state normal")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer().frame(height: 200)
            HStack(spacing: 14) {
                Capsule().fill(ringGrad).frame(width: 6, height: 36)
                Text("Today's insights").font(.system(size: 38, weight: .semibold)).foregroundStyle(textPrimary)
            }
            VStack(spacing: 0) {
                ForEach(0..<rows.count, id: \.self) { i in
                    if i > 0 { Divider().background(stroke) }
                    HStack(spacing: 22) {
                        Image(systemName: rows[i].0).font(.system(size: 22))
                            .foregroundStyle(blue500).frame(width: 40)
                        Text(rows[i].1).font(.system(size: 24)).foregroundStyle(textPrimary)
                        Spacer()
                    }.padding(.vertical, 22)
                }
            }
            .padding(.horizontal, 28)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(stroke))
            Spacer()
        }
        .padding(.horizontal, 60)
        .background(muted)
    }
}

struct HealthMock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer().frame(height: 200)
            Text("Health").font(.system(size: 56, weight: .bold)).foregroundStyle(textPrimary)
            // Fake area chart
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [blue500.opacity(0.3), blue500.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .mask(
                        Path { p in
                            let w: CGFloat = 870, h: CGFloat = 240
                            let pts: [CGFloat] = [180, 168, 175, 195, 205, 215, 220]
                            p.move(to: .init(x: 0, y: h))
                            for (i, v) in pts.enumerated() {
                                p.addLine(to: .init(x: w * CGFloat(i) / 6, y: h - (v - 150) * 1.5))
                            }
                            p.addLine(to: .init(x: w, y: h))
                            p.closeSubpath()
                        }
                    )
                Path { p in
                    let w: CGFloat = 870, h: CGFloat = 240
                    let pts: [CGFloat] = [180, 168, 175, 195, 205, 215, 220]
                    p.move(to: .init(x: 0, y: h - (pts[0] - 150) * 1.5))
                    for (i, v) in pts.enumerated().dropFirst() {
                        p.addLine(to: .init(x: w * CGFloat(i) / 6, y: h - (v - 150) * 1.5))
                    }
                }.stroke(blue500, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            .frame(height: 240)
            .padding(28)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(stroke))

            HStack(alignment: .top, spacing: 22) {
                Text("🟢").font(.system(size: 56))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stable & Healthy").font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(textPrimary)
                    Text("Cool, roomy, and calm.").font(.system(size: 22)).foregroundStyle(textSecondary)
                }
                Spacer()
            }
            .padding(28)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(stroke))
            Spacer()
        }
        .padding(.horizontal, 50)
        .background(muted)
    }
}

struct WidgetMock: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer().frame(height: 160)
            // Lock screen circular widget
            HStack(spacing: 36) {
                ZStack {
                    Circle().fill(Color.black.opacity(0.6))
                        .frame(width: 130, height: 130)
                    Circle().trim(from: 0, to: 0.86)
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 110, height: 110)
                    Text("86").font(.system(size: 32, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lock Screen").font(.system(size: 22)).foregroundStyle(.white.opacity(0.7))
                    Text("Pulse at a glance").font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(40)
            .background(.black, in: RoundedRectangle(cornerRadius: 36))
            // Home screen medium widget
            HStack(spacing: 30) {
                BigRing(score: 86, size: 220)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pulse").font(.system(size: 22, weight: .semibold)).foregroundStyle(textTertiary)
                    Text("86").font(.system(size: 72, weight: .semibold, design: .rounded)).foregroundStyle(textPrimary)
                    Text("Excellent").font(.system(size: 24)).foregroundStyle(excellent)
                }
                Spacer()
            }
            .padding(40)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 36))
            .overlay(RoundedRectangle(cornerRadius: 36).strokeBorder(stroke))
            Spacer()
        }
        .padding(.horizontal, 60)
        .background(muted)
    }
}

struct ProMock: View {
    let bullets: [(String, String)] = [
        ("calendar", "Weekly health reports"),
        ("battery.100.bolt", "Battery diagnostics"),
        ("chart.xyaxis.line", "Full scan history"),
        ("rectangle.stack.badge.plus", "Home & Lock Screen widgets"),
        ("heart.text.square", "Support a tiny, honest app"),
    ]
    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 180)
            BigRing(score: 100, size: 340)
            Text("Unlock Pulse Pro").font(.system(size: 44, weight: .bold)).foregroundStyle(textPrimary)
            Text("Deeper diagnostics. Honest data.").font(.system(size: 22)).foregroundStyle(textSecondary)
            VStack(alignment: .leading, spacing: 18) {
                ForEach(0..<bullets.count, id: \.self) { i in
                    HStack(spacing: 18) {
                        Image(systemName: bullets[i].0).font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(blue500).frame(width: 34)
                        Text(bullets[i].1).font(.system(size: 24)).foregroundStyle(textPrimary)
                        Spacer()
                        Image(systemName: "checkmark").foregroundStyle(excellent)
                    }
                }
            }
            .padding(30)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 32))
            .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(stroke))
            Spacer()
        }
        .padding(.horizontal, 60)
        .background(muted)
    }
}

// MARK: - Renderer

@MainActor
func render<V: View>(_ view: V, name: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    guard let cg = renderer.cgImage else { print("FAIL \(name)"); return }
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: 1290, height: 2796)
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    let dir = "/Users/birkanaksoy/Desktop/pulseapp/docs/screenshots"
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let url = URL(fileURLWithPath: "\(dir)/\(name).png")
    try? data.write(to: url)
    print("WROTE \(url.path)")
}

MainActor.assumeIsolated {
    render(Screenshot(
        caption: "Know your phone's\nhealth in seconds.",
        subtitle: "One honest score from real iOS signals.",
        tint: blue500
    ) { HomeMock() }, name: "1-home")

    render(Screenshot(
        caption: "Only what iOS\nactually measures.",
        subtitle: "No fake battery cycles. No invented metrics.",
        tint: excellent
    ) { MetricsMock() }, name: "2-metrics")

    render(Screenshot(
        caption: "Insights from\nyour real data.",
        subtitle: "Dynamic suggestions based on this scan.",
        tint: blue500
    ) { InsightsMock() }, name: "3-insights")

    render(Screenshot(
        caption: "Watch your phone\nover time.",
        subtitle: "Trend, stats, and a personality summary.",
        tint: fair
    ) { HealthMock() }, name: "4-health")

    render(Screenshot(
        caption: "On your Home Screen.\nOn your Lock Screen.",
        subtitle: "Five widget sizes including interactive scan.",
        tint: blue300
    ) { WidgetMock() }, name: "5-widgets")

    render(Screenshot(
        caption: "Pulse Pro —\ndeeper diagnostics.",
        subtitle: "Weekly reports, full history, widgets.",
        tint: excellent
    ) { ProMock() }, name: "6-pro")
}
