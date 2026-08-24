import SwiftUI

struct DeviceAccessView: View {

    @Environment(\.dismiss)
    private var dismiss

    @EnvironmentObject
    private var appState: AppState

    @State
    private var capabilities = DeviceCapabilities.current

    @State
    private var isChecking = false

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                capabilitySection
                actionsSection
            }
            .navigationTitle("Device Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isChecking)
                }
            }
            .onAppear {
                refresh()
            }
        }
    }

    private var overviewSection: some View {
        Section {
            VStack(spacing: 14) {
                Image(systemName: capabilities.overall.icon)
                    .font(.system(size: 42))
                    .symbolRenderingMode(.hierarchical)

                Text(capabilities.overall.title)
                    .font(.title3.weight(.semibold))

                Text("iOS \(capabilities.systemVersionString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(descriptionForOverall)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var capabilitySection: some View {
        Section("Capabilities") {
            ForEach(capabilities.capabilities, id: \.0.id) { item in
                CapabilityRow(
                    capability: item.0,
                    support: item.1
                )
            }
        }
    }

    private var actionsSection: some View {
        Section("Device Access") {
            Button {
                refresh()
            } label: {
                HStack {
                    Label("Check Device", systemImage: "iphone")

                    Spacer()

                    if isChecking {
                        ProgressView()
                    }
                }
            }
            .disabled(isChecking)

            if appState.deviceAccessActive {
                Label(
                    "Device Access Active",
                    systemImage: "checkmark.shield.fill"
                )
                .foregroundStyle(.green)
            } else {
                Label(
                    "Capability check required",
                    systemImage: "info.circle"
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    private var descriptionForOverall: String {
        switch capabilities.overall {
        case .full:
            return "All currently defined capabilities are available."

        case .partial:
            return "Some features are available on this iOS version. Unsupported operations remain disabled."

        case .unsupported:
            return "This iOS version does not provide any supported operation in this build."
        }
    }

    private func refresh() {
        isChecking = true

        DispatchQueue.main.async {
            capabilities = DeviceCapabilities.current

            // Capability detection does NOT grant privileged filesystem access.
            // Keep the existing Device Access state unchanged.
            isChecking = false
        }
    }
}

private struct CapabilityRow: View {

    let capability: DeviceCapability
    let support: CapabilitySupport

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: support.icon)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(capability.title)
                    .font(.body)

                Text(support.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(support.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(iconColor)
        }
        .padding(.vertical, 3)
    }

    private var iconColor: Color {
        switch support {
        case .full:
            return .green

        case .partial:
            return .orange

        case .unsupported:
            return .red
        }
    }
}

#Preview {
    DeviceAccessView()
        .environmentObject(AppState())
}
