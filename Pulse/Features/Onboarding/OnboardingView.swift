import SwiftUI
import UserNotifications
import Photos

struct OnboardingView: View {
    @Binding var didOnboard: Bool
    @State private var page: Int = 0
    @State private var notifRequested = false
    @State private var photoRequested = false

    // Profile state
    @State private var selectedModel: String = DeviceModel.displayName
    @State private var ownershipAge: OwnershipAge?
    @State private var selectedConcerns: Set<UserConcern> = []
    @State private var cleaningHabit: CleaningHabit?

    @AppStorage("pulse.weeklyReminder") private var weeklyReminder = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 7

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    valuePropsPage.tag(1)
                    profilePhonePage.tag(2)
                    profileNeedsPage.tag(3)
                    photoPage.tag(4)
                    notificationPage.tag(5)
                    firstScanPage.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .smooth(duration: 0.55), value: page)

                Spacer(minLength: 0)
                indicator
                cta
                skipLink
            }
            .padding(.bottom, PulseSpace.xxl)
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        ParallaxPage(page: page, index: 0) {
            VStack(spacing: PulseSpace.xl) {
                Spacer()
                glyph(systemName: "waveform.path.ecg")
                VStack(spacing: PulseSpace.s) {
                    Text("Know your phone's\nhealth in seconds.")
                        .font(PulseFont.titleXL)
                        .foregroundStyle(PulseColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Real cleaning. Honest diagnostics. No fake metrics.")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, PulseSpace.xxl)
                Spacer()
            }
        }
    }

    private var valuePropsPage: some View {
        ParallaxPage(page: page, index: 1) {
            VStack(spacing: PulseSpace.xxl) {
                Spacer()
                Text("Built like a doctor for your phone")
                    .font(PulseFont.titleL)
                    .foregroundStyle(PulseColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PulseSpace.xxl)
                VStack(spacing: PulseSpace.l) {
                    valueProp("waveform.path.ecg", "Diagnose", "One score from real iOS signals.")
                    valueProp("wand.and.stars",   "Clean", "Real deletion with iOS confirmation.")
                    valueProp("chart.xyaxis.line", "Track", "Watch your phone over time.")
                }
                .padding(.horizontal, PulseSpace.xxl)
                Spacer()
            }
        }
    }

    // MARK: - Profile A: about the phone

    private var profilePhonePage: some View {
        ParallaxPage(page: page, index: 2) {
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About your phone")
                            .font(PulseFont.titleXL)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text("Quick — and skippable. Helps us tailor suggestions.")
                            .font(PulseFont.body)
                            .foregroundStyle(PulseColor.textSecondary)
                    }
                    .padding(.top, PulseSpace.xxxl)

                    section(title: "Your iPhone model") {
                        modelPicker
                    }

                    section(title: "How long have you had it?") {
                        ownershipPicker
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, PulseSpace.xl)
            }
        }
    }

    private var modelPicker: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8),
                      GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(DeviceModel.pickerList, id: \.self) { model in
                chipButton(label: model, selected: selectedModel == model) {
                    selectedModel = model
                }
            }
        }
    }

    private var ownershipPicker: some View {
        VStack(spacing: 8) {
            ForEach(OwnershipAge.allCases) { age in
                rowButton(label: age.label, selected: ownershipAge == age) {
                    ownershipAge = age
                }
            }
        }
    }

    // MARK: - Profile B: about needs

    private var profileNeedsPage: some View {
        ParallaxPage(page: page, index: 3) {
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About you")
                            .font(PulseFont.titleXL)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text("Still skippable — these just shape your first scan's tone.")
                            .font(PulseFont.body)
                            .foregroundStyle(PulseColor.textSecondary)
                    }
                    .padding(.top, PulseSpace.xxxl)

                    section(title: "What brings you here? (pick any)") {
                        concernPicker
                    }

                    section(title: "How often do you clean your phone?") {
                        cleaningPicker
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, PulseSpace.xl)
            }
        }
    }

    private var concernPicker: some View {
        VStack(spacing: 8) {
            ForEach(UserConcern.allCases) { c in
                emojiRowButton(emoji: c.emoji, label: c.label, selected: selectedConcerns.contains(c)) {
                    if selectedConcerns.contains(c) {
                        selectedConcerns.remove(c)
                    } else {
                        selectedConcerns.insert(c)
                    }
                }
            }
        }
    }

    private var cleaningPicker: some View {
        VStack(spacing: 8) {
            ForEach(CleaningHabit.allCases) { h in
                emojiRowButton(emoji: h.emoji, label: h.label, selected: cleaningHabit == h) {
                    cleaningHabit = h
                }
            }
        }
    }

    // MARK: - Permissions

    private var photoPage: some View {
        ParallaxPage(page: page, index: 4) {
            VStack(spacing: PulseSpace.xxl) {
                Spacer()
                glyph(systemName: "photo.on.rectangle.angled")
                VStack(spacing: PulseSpace.s) {
                    Text("Allow photo access")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Pulse needs read+write access to find duplicates, big videos, and Live Photos. Nothing is uploaded.")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PulseSpace.xxl)
                    permissionStatusLine(
                        granted: photoRequested && photoAuthGranted,
                        requested: photoRequested
                    )
                }
                Spacer()
            }
        }
    }

    private var notificationPage: some View {
        ParallaxPage(page: page, index: 5) {
            VStack(spacing: PulseSpace.xxl) {
                Spacer()
                glyph(systemName: "bell.badge")
                VStack(spacing: PulseSpace.s) {
                    Text("Smart alerts")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Get a weekly check-in and timely heads-up when storage fills or your phone runs hot.")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PulseSpace.xxl)
                    permissionStatusLine(
                        granted: notifRequested && notifAuthGranted,
                        requested: notifRequested
                    )
                }
                Spacer()
            }
        }
    }

    private var firstScanPage: some View {
        ParallaxPage(page: page, index: 6) {
            VStack(spacing: PulseSpace.xl) {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(PulseColor.stroke, lineWidth: 14)
                        .frame(width: 240, height: 240)
                    Image(systemName: "play.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(PulseColor.blue500)
                        .offset(x: 4)
                        .shadow(color: PulseColor.blue500.opacity(0.35), radius: 12, y: 4)
                }
                VStack(spacing: PulseSpace.s) {
                    Text("Ready when you are")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Everything runs on your device.")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, PulseSpace.xxl)
                Spacer()
            }
        }
    }

    // MARK: - Reusable bits

    private func section<C: View>(title: LocalizedStringKey, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PulseColor.textSecondary)
            content()
        }
    }

    private func chipButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(0.3)
            action()
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(selected ? .white : PulseColor.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, PulseSpace.m)
            .padding(.vertical, PulseSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AnyShapeStyle(PulseColor.ringGradient) : AnyShapeStyle(PulseColor.card))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? .clear : PulseColor.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func rowButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(0.3)
            action()
        } label: {
            HStack(spacing: PulseSpace.m) {
                Text(label)
                    .font(PulseFont.body)
                    .foregroundStyle(selected ? .white : PulseColor.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, PulseSpace.l)
            .padding(.vertical, PulseSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(PulseColor.ringGradient) : AnyShapeStyle(PulseColor.card))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? .clear : PulseColor.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emojiRowButton(emoji: String, label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(0.3)
            action()
        } label: {
            HStack(spacing: PulseSpace.m) {
                Text(emoji).font(.system(size: 22))
                Text(label)
                    .font(PulseFont.body)
                    .foregroundStyle(selected ? .white : PulseColor.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, PulseSpace.l)
            .padding(.vertical, PulseSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(PulseColor.ringGradient) : AnyShapeStyle(PulseColor.card))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? .clear : PulseColor.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func glyph(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(
                LinearGradient(
                    colors: [PulseColor.blue500, PulseColor.blue300],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .padding(PulseSpace.xxxl)
            .background(Circle().fill(PulseColor.blue50))
            .shadow(color: PulseColor.blue500.opacity(0.25), radius: 30, y: 12)
    }

    private func valueProp(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: PulseSpace.l) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(colors: [PulseColor.blue500, PulseColor.blue300],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: PulseColor.blue500.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PulseFont.titleM).foregroundStyle(PulseColor.textPrimary)
                Text(subtitle).font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
    }

    private func permissionStatusLine(granted: Bool, requested: Bool) -> some View {
        Group {
            if requested {
                HStack(spacing: 6) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    Text(granted ? String(localized: "Granted") : String(localized: "Not granted — you can enable later in Settings"))
                }
                .font(PulseFont.footnote)
                .foregroundStyle(granted ? PulseColor.excellent : PulseColor.fair)
                .padding(.top, PulseSpace.s)
            }
        }
    }

    // MARK: - Indicator + CTA + Skip

    private var indicator: some View {
        HStack(spacing: PulseSpace.s) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? PulseColor.blue500 : PulseColor.stroke)
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .padding(.bottom, PulseSpace.l)
    }

    private var cta: some View {
        PrimaryButton(
            title: ctaTitle,
            systemImage: "arrow.right"
        ) {
            handleCTA()
        }
        .padding(.horizontal, PulseSpace.xl)
    }

    private var ctaTitle: LocalizedStringKey {
        switch page {
        case 2, 3: return "Continue"
        case 4:    return photoRequested ? "Continue" : "Allow photo access"
        case 5:    return notifRequested ? "Continue" : "Enable smart alerts"
        case 6:    return "Run my first scan"
        default:   return "Continue"
        }
    }

    private var skipLink: some View {
        Group {
            if shouldShowSkip {
                Button {
                    Haptics.tap(0.2)
                    advance()
                } label: {
                    Text(page == 4 || page == 5 ? "Skip — I'll decide later" : "Skip this")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(PulseColor.textTertiary)
                        .padding(.top, PulseSpace.m)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(height: PulseSpace.l)
            }
        }
    }

    private var shouldShowSkip: Bool {
        switch page {
        case 2, 3: return true
        case 4:    return !photoRequested
        case 5:    return !notifRequested
        default:   return false
        }
    }

    // MARK: - Actions

    private func handleCTA() {
        switch page {
        case 2, 3:
            saveProfile()
            advance()
        case 4 where !photoRequested:
            Task { await requestPhotoPermission() }
        case 5 where !notifRequested:
            Task { await requestNotificationPermission() }
        default:
            advance()
        }
    }

    private func advance() {
        if page < totalPages - 1 {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.45)) { page += 1 }
        } else {
            didOnboard = true
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            detectedModel: DeviceModel.displayName,
            selectedModel: selectedModel,
            ownershipAge: ownershipAge,
            concerns: Array(selectedConcerns),
            cleaningHabit: cleaningHabit
        )
        UserProfileStore.save(profile)
    }

    @State private var photoAuthGranted = false
    @State private var notifAuthGranted = false

    @MainActor
    private func requestPhotoPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoAuthGranted = (status == .authorized || status == .limited)
        photoRequested = true
        advance()
    }

    @MainActor
    private func requestNotificationPermission() async {
        let granted = await NotificationScheduler.requestAuthorization()
        notifAuthGranted = granted
        notifRequested = true
        if granted {
            NotificationScheduler.scheduleWeeklyReminder()
            weeklyReminder = true
        }
        advance()
    }
}

private struct ParallaxPage<Content: View>: View {
    var page: Int
    var index: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let mid = frame.midX
            let screen = UIScreen.main.bounds.width
            let offset = (mid - screen / 2) / screen
            let opacity = 1 - min(1, abs(offset) * 1.4)
            let scale = 0.96 + (1 - min(1, abs(offset))) * 0.04

            content()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                .opacity(opacity)
                .scaleEffect(scale)
                .offset(y: abs(offset) * 8)
        }
    }
}
