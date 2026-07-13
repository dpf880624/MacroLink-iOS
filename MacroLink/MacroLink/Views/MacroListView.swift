import SwiftUI

struct MacroListView: View {
    @StateObject private var viewModel = MacroViewModel()
    @State private var showingEditor: Bool = false
    @State private var editingMacro: Macro? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.macros.isEmpty {
                    emptyState
                } else {
                    macroList
                }
            }
            .navigationTitle("宏管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.10), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditor = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isRecording {
                        Button(action: { viewModel.stopRecording() }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("停止录制")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button(action: { viewModel.startRecording() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "record.circle")
                                Text("录制")
                                    .font(.caption)
                            }
                            .foregroundColor(Color.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                MacroEditorView(macro: editingMacro ?? Macro(name: "新宏"), onSave: { macro in
                    if editingMacro != nil {
                        viewModel.updateMacro(macro)
                    } else {
                        viewModel.addMacro(macro)
                    }
                    editingMacro = nil
                })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.2))
            Text("暂无宏")
                .font(.headline)
                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
            Text("点击 + 创建新宏，或点击录制按钮录制操作")
                .font(.caption)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
        }
    }

    private var macroList: some View {
        List {
            ForEach(viewModel.macros) { macro in
                MacroRowView(macro: macro, isPlaying: viewModel.currentPlayingMacro?.id == macro.id)
                    .listRowBackground(Color(red: 0.10, green: 0.10, blue: 0.12))
                    .onTapGesture {
                        if viewModel.isPlaying && viewModel.currentPlayingMacro?.id == macro.id {
                            viewModel.stopPlaying()
                        } else {
                            viewModel.playMacro(macro)
                        }
                    }
                    .contextMenu {
                        Button(action: { editingMacro = macro; showingEditor = true }) {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(action: { viewModel.toggleFavorite(macro) }) {
                            Label(macro.isFavorite ? "取消收藏" : "收藏", systemImage: macro.isFavorite ? "star.slash" : "star")
                        }
                        Button(role: .destructive, action: { viewModel.deleteMacro(macro) }) {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct MacroRowView: View {
    let macro: Macro
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPlaying ? "play.circle.fill" : (macro.isFavorite ? "star.fill" : "list.bullet.rectangle"))
                .font(.system(size: 24))
                .foregroundColor(isPlaying ? Color(red: 1.0, green: 0.75, blue: 0.3) : Color(red: 0.7, green: 0.65, blue: 0.5))

            VStack(alignment: .leading, spacing: 4) {
                Text(macro.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                HStack(spacing: 8) {
                    Text("\(macro.actionCount) 步")
                    Text("×\(macro.loopCount)")
                    Text("\(macro.totalDuration)ms")
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
            }

            Spacer()

            if isPlaying {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.9, green: 0.75, blue: 0.3)))
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

struct MacroEditorView: View {
    @State var macro: Macro
    let onSave: (Macro) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showingActionEditor: Bool = false
    @State private var editingActionIndex: Int? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                    TextField("宏名称", text: $macro.name)
                        .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                    TextField("描述", text: $macro.description)
                        .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                    Stepper("循环次数: \(macro.loopCount)", value: $macro.loopCount, in: 1...100)
                        .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                }

                Section(header: Text("动作列表 (\(macro.actions.count))").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                    ForEach(macro.actions) { action in
                        HStack {
                            Image(systemName: action.type.icon)
                                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                            Text(action.displayText)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Spacer()
                            Text("\(action.delay)ms")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                        }
                    }
                    .onDelete { indexSet in
                        macro.actions.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        macro.actions.move(fromOffsets: from, toOffset: to)
                    }

                    Button(action: { addKeyboardAction() }) {
                        Label("添加键盘动作", systemImage: "keyboard")
                    }
                    Button(action: { addMouseClickAction() }) {
                        Label("添加鼠标点击", systemImage: "cursorarrow.click")
                    }
                    Button(action: { addDelayAction() }) {
                        Label("添加延时", systemImage: "clock")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.08, green: 0.08, blue: 0.10))
            .navigationTitle("编辑宏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(macro)
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                    .disabled(macro.name.isEmpty)
                }
            }
        }
    }

    private func addKeyboardAction() {
        let action = MacroAction(type: .keyboard, keyCode: 65, keyName: "A", delay: 50)
        macro.actions.append(action)
    }

    private func addMouseClickAction() {
        let action = MacroAction(type: .mouseClick, x: 0, y: 0, mouseButton: "left", delay: 50)
        macro.actions.append(action)
    }

    private func addDelayAction() {
        let action = MacroAction(type: .delay, delay: 100)
        macro.actions.append(action)
    }
}