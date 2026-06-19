import SwiftUI

struct ModelManagerView: View {
    @ObservedObject var modelManager: ModelManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Built-in") {
                    ForEach(modelManager.availableModels.filter(\.isBuiltIn)) { model in
                        ModelRow(
                            model: model,
                            isActive: modelManager.activeModel == model.name,
                            onSelect: { modelManager.activeModel = model.name }
                        )
                    }
                }

                Section("Downloaded") {
                    let downloaded = modelManager.availableModels.filter { !$0.isBuiltIn && $0.isDownloaded }
                    if downloaded.isEmpty {
                        Text("No downloaded models")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(downloaded) { model in
                            ModelRow(
                                model: model,
                                isActive: modelManager.activeModel == model.name,
                                onSelect: { modelManager.activeModel = model.name },
                                onDelete: { modelManager.deleteModel(model.name) }
                            )
                        }
                    }
                }

                Section("Available for Download") {
                    let notDownloaded = modelManager.availableModels.filter { !$0.isBuiltIn && !$0.isDownloaded }
                    if notDownloaded.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No additional models available")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Core ML models can be downloaded from Hugging Face. Enter a model URL below to add one.")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    } else {
                        ForEach(notDownloaded) { model in
                            ModelRow(
                                model: model,
                                isActive: false,
                                onSelect: {},
                                onDownload: {
                                    if let url = model.remoteURL {
                                        Task { await modelManager.downloadModel(name: model.name, urlString: url) }
                                    }
                                }
                            )
                        }
                    }

                    AddModelView(modelManager: modelManager)
                }

                if modelManager.isDownloading {
                    Section("Download Progress") {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: modelManager.downloadProgress)
                                .tint(.cyan)
                            Text("\(String(format: "%.0f", modelManager.downloadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                if let error = modelManager.downloadError {
                    Section("Error") {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.caution)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.caution)
                        }
                    }
                }
            }
            .navigationTitle("Model Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ModelRow: View {
    let model: ModelEntry
    let isActive: Bool
    var onSelect: () -> Void = {}
    var onDelete: (() -> Void)? = nil
    var onDownload: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if model.isBuiltIn {
                Image(systemName: "chip.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
            } else {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(model.description)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                if model.sizeMB > 0 {
                    Text("\(String(format: "%.0f", model.sizeMB)) MB")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            Spacer()

            if isActive {
                Text("Active")
                    .font(.pillText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.positive)
                    .cornerRadius(4)
            } else if model.isBuiltIn {
                Button("Select") {
                    onSelect()
                }
                .font(.caption)
                .tint(.cyan)
            } else if model.isDownloaded {
                Button("Select") {
                    onSelect()
                }
                .font(.caption)
                .tint(.cyan)
            } else if let download = onDownload {
                Button("Download") {
                    download()
                }
                .font(.caption)
                .tint(.purple)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !model.isBuiltIn && model.isDownloaded, let delete = onDelete {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

struct AddModelView: View {
    @ObservedObject var modelManager: ModelManager
    @State private var modelName = ""
    @State private var modelURL = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add Custom Model")
                .font(.caption)
                .foregroundColor(.gray)

            TextField("Model name", text: $modelName)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .font(.caption)
                .textFieldStyle(.roundedBorder)

            TextField("Hugging Face download URL", text: $modelURL)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .font(.caption)
                .textFieldStyle(.roundedBorder)

            Button("Download & Add") {
                guard !modelName.isEmpty, !modelURL.isEmpty else { return }
                Task {
                    await modelManager.downloadModel(name: modelName, urlString: modelURL)
                    modelName = ""
                    modelURL = ""
                }
            }
            .font(.caption)
            .tint(.purple)
            .disabled(modelName.isEmpty || modelURL.isEmpty || modelManager.isDownloading)
        }
        .padding(.vertical, 4)
    }
}
