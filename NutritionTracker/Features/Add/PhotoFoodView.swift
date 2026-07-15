import PhotosUI
import SwiftUI
import UIKit

struct PhotoFoodView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var recognizedFood: FoodReference?
    @State private var recognitionNotice: String?
    @State private var isRecognizing = false
    @State private var presentsCamera = false
    @State private var errorMessage: String?

    private let bundle: Bundle
    private let foods: [FoodReference]
    private let recognitionService: any FoodRecognitionService
    private let initialMealType: MealType
    private let saveDate: Date
    private let onSaved: (() -> Void)?

    init(
        bundle: Bundle = .main,
        recognitionService: any FoodRecognitionService = MockFoodRecognitionService(),
        initialMealType: MealType = .breakfast,
        saveDate: Date = Date(),
        onSaved: (() -> Void)? = nil
    ) {
        self.bundle = bundle
        foods = (try? FoodDatabaseService.loadBundled(bundle: bundle).foods) ?? []
        self.recognitionService = recognitionService
        self.initialMealType = initialMealType
        self.saveDate = saveDate
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("选择一张清晰的食物照片")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 35)
                }
            }

            Section("选择图片") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo")
                }
                Button {
                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        errorMessage = "当前设备无法使用相机"
                        return
                    }
                    presentsCamera = true
                } label: {
                    Label("使用相机拍照", systemImage: "camera")
                }
            }

            if isRecognizing {
                Section {
                    HStack {
                        ProgressView()
                        Text("正在生成模拟候选……")
                    }
                }
            } else if image != nil {
                Section("识别结果") {
                    if let recognitionNotice {
                        Label(recognitionNotice, systemImage: "info.circle")
                            .foregroundStyle(.orange)
                    }
                    if let recognizedFood {
                        HStack {
                            Text("模拟候选")
                            Spacer()
                            Text(recognizedFood.name)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("未匹配到内置食物，请在下一步手动填写。")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        AddFoodView(
                            bundle: bundle,
                            initialFood: recognizedFood,
                            initialMealType: initialMealType,
                            saveDate: saveDate,
                            inputMethod: .photo,
                            onSaved: onSaved
                        )
                    } label: {
                        Text("确认食物名称和重量")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle("照片添加")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                do {
                    guard
                        let data = try await item.loadTransferable(type: Data.self),
                        let selectedImage = UIImage(data: data)
                    else {
                        throw FoodRecognitionError.unreadableImage
                    }
                    await MainActor.run {
                        image = selectedImage
                    }
                    await recognize(data)
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .sheet(isPresented: $presentsCamera) {
            CameraPicker { selectedImage in
                image = selectedImage
                guard let data = selectedImage.jpegData(compressionQuality: 0.85) else {
                    errorMessage = FoodRecognitionError.unreadableImage.localizedDescription
                    return
                }
                Task { await recognize(data) }
            }
            .ignoresSafeArea()
        }
        .alert(
            "图片处理失败",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func recognize(_ data: Data) async {
        isRecognizing = true
        defer { isRecognizing = false }
        do {
            let result = try await recognitionService.recognize(imageData: data)
            recognitionNotice = result.notice
            let candidateName = result.candidates.first?.foodName
            recognizedFood = candidateName.flatMap { name in
                foods.first { $0.name == name }
                    ?? foods.first { $0.aliases.contains(name) }
            }
        } catch {
            recognizedFood = nil
            recognitionNotice = "识别未完成，请手动确认"
            errorMessage = error.localizedDescription
        }
    }
}
