import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

struct ImageSplitterView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var processedImages: [UIImage] = []
    @State private var splitMode: SplitMode = .grid
    @State private var gridRows: Int = 2
    @State private var gridColumns: Int = 2
    @State private var isShowingImagePicker = false
    @State private var isShowingPreview = false
    @State private var previewImage: UIImage? = nil
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    
    enum SplitMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case horizontal = "Horizontal"
        case vertical = "Vertical"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Split an image into multiple parts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Selected Image
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Image")
                            .font(.headline)
                        
                        Spacer()
                        
                        if selectedImage != nil {
                            Button(action: {
                                selectedImage = nil
                                processedImages = []
                            }) {
                                Label("Clear", systemImage: "xmark.circle")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    
                    if selectedImage == nil {
                        emptyStateView
                    } else {
                        selectedImageView
                    }
                }
                
                if let selectedImage = selectedImage {
                    // Split Options
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Split Options")
                            .font(.headline)
                        
                        Picker("Split Mode", selection: $splitMode) {
                            ForEach(SplitMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: splitMode) { _ in
                            // Reset processed images when changing mode
                            processedImages = []
                        }
                        
                        if splitMode == .grid {
                            // Grid Options
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rows: \(gridRows)")
                                        .font(.subheadline)
                                    
                                    Slider(value: Binding(
                                        get: { Double(gridRows) },
                                        set: { gridRows = max(1, min(10, Int($0))) }
                                    ), in: 1...10, step: 1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Columns: \(gridColumns)")
                                        .font(.subheadline)
                                    
                                    Slider(value: Binding(
                                        get: { Double(gridColumns) },
                                        set: { gridColumns = max(1, min(10, Int($0))) }
                                    ), in: 1...10, step: 1)
                                }
                            }
                        } else if splitMode == .horizontal {
                            // Horizontal Split Options
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Number of slices: \(gridRows)")
                                    .font(.subheadline)
                                
                                Slider(value: Binding(
                                    get: { Double(gridRows) },
                                    set: { gridRows = max(2, min(10, Int($0))) }
                                ), in: 2...10, step: 1)
                            }
                        } else if splitMode == .vertical {
                            // Vertical Split Options
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Number of slices: \(gridColumns)")
                                    .font(.subheadline)
                                
                                Slider(value: Binding(
                                    get: { Double(gridColumns) },
                                    set: { gridColumns = max(2, min(10, Int($0))) }
                                ), in: 2...10, step: 1)
                            }
                        }
                        
                        Button(action: {
                            splitImage()
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Split Image")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                        .padding(.top, 10)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
                
                if !processedImages.isEmpty {
                    // Split Results
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Split Results")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(processedImages.count) images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
                        ], spacing: 16) {
                            ForEach(0..<processedImages.count, id: \.self) { index in
                                imageResultCell(image: processedImages[index], index: index)
                            }
                        }
                        
                        Button(action: {
                            saveAllImages()
                        }) {
                            Label("Save All Images", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 10)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $isShowingPreview) {
            if let previewImage = previewImage {
                ImagePreviewView(image: previewImage)
            }
        }
        .navigationTitle("Image Splitter")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("No Image Selected")
                .font(.headline)
            
            Text("Tap \"Select Image\" to choose an image to split")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                isShowingImagePicker = true
            }) {
                Text("Select Image")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var selectedImageView: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Size: \(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Text("Change")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func imageResultCell(image: UIImage, index: Int) -> some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .cornerRadius(4)
                .onTapGesture {
                    previewImage = image
                    isShowingPreview = true
                }
            
            HStack {
                Text("Part \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    saveImage(image)
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func splitImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Use background thread for processing
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result: [UIImage]
                
                switch splitMode {
                case .grid:
                    result = try splitImageIntoGrid(image, rows: gridRows, columns: gridColumns)
                case .horizontal:
                    result = try splitImageHorizontally(image, slices: gridRows)
                case .vertical:
                    result = try splitImageVertically(image, slices: gridColumns)
                }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    processedImages = result
                    isProcessing = false
                }
            } catch {
                // Handle error on main thread
                DispatchQueue.main.async {
                    errorMessage = "Failed to split image: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    private func splitImageIntoGrid(_ image: UIImage, rows: Int, columns: Int) throws -> [UIImage] {
        var result: [UIImage] = []
        
        let width = image.size.width
        let height = image.size.height
        let tileWidth = width / CGFloat(columns)
        let tileHeight = height / CGFloat(rows)
        
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "com.llmbuddy.ios", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get CGImage from UIImage"
            ])
        }
        
        for row in 0..<rows {
            for column in 0..<columns {
                let x = CGFloat(column) * tileWidth
                let y = CGFloat(row) * tileHeight
                
                if let tileImage = cgImage.cropping(to: CGRect(x: x, y: y, width: tileWidth, height: tileHeight)) {
                    let uiImage = UIImage(cgImage: tileImage, scale: image.scale, orientation: image.imageOrientation)
                    result.append(uiImage)
                }
            }
        }
        
        return result
    }
    
    private func splitImageHorizontally(_ image: UIImage, slices: Int) throws -> [UIImage] {
        var result: [UIImage] = []
        
        let width = image.size.width
        let height = image.size.height
        let sliceHeight = height / CGFloat(slices)
        
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "com.llmbuddy.ios", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get CGImage from UIImage"
            ])
        }
        
        for slice in 0..<slices {
            let y = CGFloat(slice) * sliceHeight
            
            if let sliceImage = cgImage.cropping(to: CGRect(x: 0, y: y, width: width, height: sliceHeight)) {
                let uiImage = UIImage(cgImage: sliceImage, scale: image.scale, orientation: image.imageOrientation)
                result.append(uiImage)
            }
        }
        
        return result
    }
    
    private func splitImageVertically(_ image: UIImage, slices: Int) throws -> [UIImage] {
        var result: [UIImage] = []
        
        let width = image.size.width
        let height = image.size.height
        let sliceWidth = width / CGFloat(slices)
        
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "com.llmbuddy.ios", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get CGImage from UIImage"
            ])
        }
        
        for slice in 0..<slices {
            let x = CGFloat(slice) * sliceWidth
            
            if let sliceImage = cgImage.cropping(to: CGRect(x: x, y: 0, width: sliceWidth, height: height)) {
                let uiImage = UIImage(cgImage: sliceImage, scale: image.scale, orientation: image.imageOrientation)
                result.append(uiImage)
            }
        }
        
        return result
    }
    
    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func saveAllImages() {
        for image in processedImages {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        // Show a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// Image Picker using PHPickerViewController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// Image Preview View
struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Button(action: {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    
                    // Show a haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .navigationTitle("Image Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ImageSplitterView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSplitterView()
    }
}
