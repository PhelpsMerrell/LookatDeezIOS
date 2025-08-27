// Concentricity.swift
// Drop-in styling primitives for “concentric” Apple-like continuous corners


import SwiftUI

// MARK: - Tokens
public struct ConcentricTokens {
    public var grid: CGFloat = 8
    /// Ratio of device short-edge used to derive a base corner radius (squircle-ish feel)
    public var baseHardwareRatio: CGFloat = 0.048 // ~4.8% feels right on modern iPhones

    public init(grid: CGFloat = 8, baseHardwareRatio: CGFloat = 0.048) {
        self.grid = grid
        self.baseHardwareRatio = baseHardwareRatio
    }

    public func baseHardwareRadius(_ size: CGSize) -> CGFloat {
        min(size.width, size.height) * baseHardwareRatio
    }

    public func radii(for size: CGSize) -> ConcentricRadii {
        let r = baseHardwareRadius(size)
        return ConcentricRadii(xs: r * 0.35, sm: r * 0.55, md: r * 0.75, lg: r * 1.00, xl: r * 1.25)
    }
}

public struct ConcentricRadii: Equatable {
    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
}

// MARK: - Environment
private struct ConcentricTokensKey: EnvironmentKey { static let defaultValue = ConcentricTokens() }
private struct ConcentricRadiiKey: EnvironmentKey { static let defaultValue = ConcentricRadii(xs: 8, sm: 12, md: 16, lg: 22, xl: 28) }

public extension EnvironmentValues {
    var concentricTokens: ConcentricTokens {
        get { self[ConcentricTokensKey.self] }
        set { self[ConcentricTokensKey.self] = newValue }
    }
    var concentricRadii: ConcentricRadii {
        get { self[ConcentricRadiiKey.self] }
        set { self[ConcentricRadiiKey.self] = newValue }
    }
}

/// Provides radii based on current container size. Place high in the view tree (e.g., screen root).
public struct ConcentricLayout<Content: View>: View {
    @Environment(\.concentricTokens) private var tokens
    private let content: (CGSize, ConcentricRadii) -> Content
    public init(@ViewBuilder content: @escaping (CGSize, ConcentricRadii) -> Content) {
        self.content = content
    }
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let radii = tokens.radii(for: size)
            content(size, radii)
                .environment(\.concentricRadii, radii)
                .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - Core modifiers
public extension View {
    /// Clips and sets the hit region to a continuous rounded rectangle.
    func concentricCorner(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Glassy background + subtle white stroke; keep corners continuous.
    func concentricGlass(radius: CGFloat, material: Material = .ultraThinMaterial, strokeOpacity: Double = 0.25) -> some View {
        background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 0.5)
            )
    }

    /// One consistent shadow language.
    func concentricShadow(level: ConcentricShadowLevel) -> some View {
        switch level {
        case .card:
            return shadow(color: Color.black.opacity(0.10), radius: 10, y: 4)
        case .pill:
            return shadow(radius: 4, y: 2)
        case .modal:
            return shadow(color: Color.black.opacity(0.15), radius: 20, y: 8)
        }
    }

    /// Convenience for cards (material, corner, stroke, shadow) in one shot.
    func concentricCard(_ radius: CGFloat, material: Material = .regularMaterial) -> some View {
        self
            .concentricGlass(radius: radius, material: material, strokeOpacity: 0.18)
            .concentricCorner(radius)
            .concentricShadow(level: .card)
    }
}

public enum ConcentricShadowLevel { case card, pill, modal }

// MARK: - Ready‑made components
public struct ConcentricCard<Content: View>: View {
    public var radius: CGFloat
    public var material: Material
    @ViewBuilder public var content: Content

    public init(radius: CGFloat, material: Material = .regularMaterial, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.material = material
        self.content = content()
    }

    public var body: some View {
        content
            .padding(12)
            .concentricCard(radius, material: material)
    }
}

public struct ConcentricPillButton: View {
    public enum Role { case normal, destructive }
    public var systemName: String
    public var role: Role
    public var radius: CGFloat
    public var action: () -> Void

    public init(systemName: String, role: Role = .normal, radius: CGFloat, action: @escaping () -> Void) {
        self.systemName = systemName
        self.role = role
        self.radius = radius
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .padding(14)
                .foregroundStyle(role == .destructive ? Color.red : Color.primary)
                .concentricGlass(radius: radius, material: .ultraThinMaterial, strokeOpacity: role == .destructive ? 0.40 : 0.25)
                .concentricCorner(radius)
                .concentricShadow(level: .pill)
        }
        .buttonStyle(.plain)
    }
}

/// Wrap modal content to match your radius language (handy inside .sheet).
public struct ConcentricModalContainer<Content: View>: View {
    public var radius: CGFloat
    @ViewBuilder public var content: Content

    public init(radius: CGFloat, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(20)
            .background(.thinMaterial)
            .concentricCorner(radius)
            .concentricShadow(level: .modal)
            .padding(.horizontal, 16)
    }
}

// MARK: - Extras
public struct ConcentricTappedScale: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - Convenience previews
struct Concentricity_Previews: PreviewProvider {
    static var previews: some View {
        ConcentricLayout { _, R in
            VStack(spacing: 16) {
                ConcentricCard(radius: R.md) {
                    VStack(alignment: .leading) {
                        Text("Concentric Card").font(.headline)
                        Text("Continuous corners, glass, subtle stroke, shadow.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    ConcentricPillButton(systemName: "play.fill", radius: R.sm) {}
                    ConcentricPillButton(systemName: "trash", role: .destructive, radius: R.sm) {}
                }

                ConcentricModalContainer(radius: R.lg) {
                    VStack(spacing: 8) {
                        Text("Modal Container").font(.headline)
                        Text("Use inside .sheet to keep the same radius language.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
        }
    }
}
