import SwiftUI

struct ColorsView: View {
    @StateObject private var viewModel = ColorViewModel()
    @State private var showingConnectivityPopup = false
    @State private var connectivityMessage = ""
    @State private var isGenerating = false
    @State private var hasInitializedConnectivity = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Computed properties for responsive design
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    private var gridColumns: [GridItem] {
        let columnCount: Int
        if horizontalSizeClass == .regular {
            // iPad or large screen
            columnCount = isLandscape ? 4 : 3
        } else {
            // iPhone
            columnCount = isLandscape ? 2 : 1
        }
        return Array(repeating: GridItem(.flexible(), spacing: adaptiveSpacing), count: columnCount)
    }
    
    private var adaptiveSpacing: CGFloat {
        if horizontalSizeClass == .regular {
            return 16 // iPad
        } else {
            return isLandscape ? 12 : 8 // iPhone
        }
    }
    
    private var adaptivePadding: CGFloat {
        if horizontalSizeClass == .regular {
            return 24 // iPad
        } else {
            return 16 // iPhone
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Color count below title
                    HStack {
                        Text("\(viewModel.colorCards.count) colors")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, adaptivePadding)
                    .padding(.top, 8)
                    
                    // Error message with better styling
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                            Spacer()
                        }
                        .padding(.horizontal, adaptiveSpacing)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, adaptivePadding)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Color Cards List or Empty State
                    if viewModel.colorCards.isEmpty {
                        emptyStateView
                    } else {
                        colorsList
                    }
                    
                    // Enhanced Generate Button
                    generateButton
                }
                
                // Connectivity Status Popup
                if showingConnectivityPopup {
                    connectivityPopup
                }
            }
            .navigationTitle("Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Connectivity indicator only
                    HStack(spacing: 3) {
                        Circle()
                            .fill(viewModel.isOnline ? Color.green : Color.red)
                            .frame(width: 5, height: 5)
                            .scaleEffect(viewModel.isOnline ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isOnline)
                        Text(viewModel.isOnline ? "Online" : "Offline")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: viewModel.isOnline) { _, newValue in
                showConnectivityPopup(isOnline: newValue)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures proper behavior on iPad
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: isCompact ? 20 : 30) {
            Spacer()
            
            Image(systemName: "paintpalette")
                .font(.system(size: horizontalSizeClass == .regular ? 80 : (isLandscape ? 50 : 60)))
                .foregroundColor(.secondary)
            
            VStack(spacing: isCompact ? 8 : 12) {
                Text("No Colors Yet")
                    .font(horizontalSizeClass == .regular ? .largeTitle : .title2)
                    .fontWeight(.semibold)
                
                Text("Tap the button below to generate your first color")
                    .font(horizontalSizeClass == .regular ? .title3 : .body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, isCompact ? 20 : 40)
            }
            
            Spacer()
        }
        .padding(adaptivePadding)
    }
    
    private var colorsList: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: adaptiveSpacing * 1.5) {
                ForEach(viewModel.colorCards) { card in
                    ColorCardView(
                        card: card, 
                        isCompactLayout: isCompact && !isLandscape,
                        onDelete: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                viewModel.deleteColor(card)
                            }
                        }
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .top)),
                        removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .leading))
                    ))
                    .contextMenu {
                        Button("Copy Hex Code") {
                            UIPasteboard.general.string = "#\(card.hexCode)"
                        }
                        Button("Delete", role: .destructive) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                viewModel.deleteColor(card)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, adaptivePadding)
            .padding(.top, adaptiveSpacing)
        }
        .refreshable {
            if viewModel.isOnline {
                viewModel.syncWithFirebase()
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            generateColorWithHaptics()
        }) {
            HStack(spacing: isCompact ? 8 : 12) {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(horizontalSizeClass == .regular ? 1.0 : 0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(horizontalSizeClass == .regular ? .title2 : .title3)
                }
                Text(isGenerating ? "Generating..." : "Generate New Color")
                    .font(horizontalSizeClass == .regular ? .title3 : .headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
            .frame(height: horizontalSizeClass == .regular ? 64 : (isLandscape ? 48 : 56))
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(horizontalSizeClass == .regular ? 20 : 16)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isGenerating)
        .scaleEffect(isGenerating ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGenerating)
        .padding(.horizontal, adaptivePadding)
        .padding(.bottom, isLandscape ? adaptiveSpacing : adaptivePadding)
    }
    
    private var connectivityPopup: some View {
        VStack {
            HStack(spacing: isCompact ? 8 : 12) {
                Image(systemName: viewModel.isOnline ? "wifi" : "wifi.slash")
                    .foregroundColor(viewModel.isOnline ? .green : .red)
                    .font(horizontalSizeClass == .regular ? .title3 : .body)
                Text(connectivityMessage)
                    .font(horizontalSizeClass == .regular ? .headline : .subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(horizontalSizeClass == .regular ? 20 : 16)
            .background(
                RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 16 : 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, adaptivePadding)
            .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1)
    }
    
    // MARK: - Methods
    
    private func generateColorWithHaptics() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isGenerating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Generate the color with enhanced animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
                viewModel.generateRandomColor()
            }
            
            // Add a slight delay before stopping the loading state for smoother transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isGenerating = false
                }
                
                // Add a success haptic feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            }
        }
    }
    
    private func showConnectivityPopup(isOnline: Bool) {
        // Only show popup if connectivity has been initialized (not on first load)
        guard hasInitializedConnectivity else {
            hasInitializedConnectivity = true
            return
        }
        
        connectivityMessage = isOnline ? "Connected to Internet" : "No Internet Connection"
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingConnectivityPopup = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showingConnectivityPopup = false
            }
        }
    }
}

struct ColorCardView: View {
    let card: ColorCard
    let isCompactLayout: Bool
    let onDelete: () -> Void
    @State private var isPressed = false
    @State private var showingCopiedFeedback = false
    @State private var dragOffset = CGSize.zero
    @State private var showingDeleteButton = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Adaptive sizing properties
    private var adaptiveColorHeight: CGFloat {
        if horizontalSizeClass == .regular {
            return isCompactLayout ? 100 : 140
        } else {
            return isCompactLayout ? 80 : 120
        }
    }
    
    private var adaptiveCardSpacing: CGFloat {
        if horizontalSizeClass == .regular {
            return isCompactLayout ? 8 : 16
        } else {
            return isCompactLayout ? 6 : 12
        }
    }
    
    private var adaptiveCornerRadius: CGFloat {
        horizontalSizeClass == .regular ? 20 : 16
    }
    
    private var adaptiveCardCornerRadius: CGFloat {
        horizontalSizeClass == .regular ? 24 : 20
    }
    
    private var adaptiveCardPadding: CGFloat {
        if horizontalSizeClass == .regular {
            return isCompactLayout ? 12 : 20
        } else {
            return isCompactLayout ? 8 : 16
        }
    }
    
    private var adaptiveInfoSpacing: CGFloat {
        horizontalSizeClass == .regular ? 8 : 6
    }
    
    private var adaptiveHexFont: Font {
        if horizontalSizeClass == .regular {
            return .title2
        } else {
            return isCompactLayout ? .headline : .title3
        }
    }
    
    private var adaptiveCopyButtonFont: Font {
        horizontalSizeClass == .regular ? .body : .caption
    }
    
    private var adaptiveCopyButtonPadding: CGFloat {
        horizontalSizeClass == .regular ? 8 : 6
    }
    
    private var adaptiveDetailFont: Font {
        horizontalSizeClass == .regular ? .body : .caption
    }
    
    private var adaptiveRGBFont: Font {
        horizontalSizeClass == .regular ? .caption : .caption2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveCardSpacing) {
            // Color Display with gradient overlay
            ZStack {
                Rectangle()
                    .fill(card.color)
                    .frame(height: adaptiveColorHeight)
                    .cornerRadius(adaptiveCornerRadius)
                
                // Subtle gradient overlay for better text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(adaptiveCornerRadius)
                
                // Copy feedback overlay
                if showingCopiedFeedback {
                    ZStack {
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                            .fill(Color.black.opacity(0.7))
                        
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(horizontalSizeClass == .regular ? .title : .title2)
                                .foregroundColor(.white)
                            Text("Copied!")
                                .font(horizontalSizeClass == .regular ? .body : .caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .onTapGesture {
                copyHexCode()
            }
            
            // Color Information
            if !isCompactLayout || horizontalSizeClass == .regular {
                VStack(alignment: .leading, spacing: adaptiveInfoSpacing) {
                    HStack {
                        Text("#\(card.hexCode)")
                            .font(adaptiveHexFont)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            copyHexCode()
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(adaptiveCopyButtonFont)
                                .foregroundColor(.secondary)
                                .padding(adaptiveCopyButtonPadding)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(card.timestamp, format: .dateTime.hour().minute())
                                .font(adaptiveDetailFont)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // RGB Values
                        Text(rgbString)
                            .font(adaptiveRGBFont)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, horizontalSizeClass == .regular ? 10 : 8)
                            .padding(.vertical, horizontalSizeClass == .regular ? 4 : 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            } else {
                // Compact layout - minimal info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(card.hexCode)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            copyHexCode()
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Timestamp in compact layout
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(card.timestamp, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(adaptiveCardPadding)
        .background(
            RoundedRectangle(cornerRadius: adaptiveCardCornerRadius)
                .fill(Color.clear)
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.15 : 0.08),
                    radius: isPressed ? (horizontalSizeClass == .regular ? 16 : 12) : (horizontalSizeClass == .regular ? 12 : 8),
                    x: 0,
                    y: isPressed ? (horizontalSizeClass == .regular ? 8 : 6) : (horizontalSizeClass == .regular ? 6 : 4)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .offset(x: dragOffset.width)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingDeleteButton)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Only respond to predominantly horizontal swipes
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    // Must be more horizontal than vertical and significant horizontal movement
                    if horizontalMovement > verticalMovement && horizontalMovement > 20 {
                        if value.translation.width < 0 {
                            // Left swipe - show delete
                            dragOffset = CGSize(width: max(value.translation.width, -80), height: 0)
                        } else if showingDeleteButton {
                            // Right swipe - hide delete only if delete is showing
                            dragOffset = CGSize(width: min(value.translation.width, 0), height: 0)
                        }
                    }
                }
                .onEnded { value in
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    // Only process if it was a horizontal gesture
                    if horizontalMovement > verticalMovement && horizontalMovement > 20 {
                        if value.translation.width < -40 {
                            // Show delete button
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = CGSize(width: -80, height: 0)
                                showingDeleteButton = true
                            }
                        } else {
                            // Hide delete button
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = .zero
                                showingDeleteButton = false
                            }
                        }
                    } else {
                        // If it was a vertical gesture, reset to original state
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = showingDeleteButton ? CGSize(width: -80, height: 0) : .zero
                        }
                    }
                }
        )
        .background(
            // Delete button background
            HStack {
                Spacer()
                if dragOffset.width < 0 || showingDeleteButton {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .frame(width: 80)
                            .frame(maxHeight: .infinity)
                            .background(Color.red)
                    }
                    .opacity(showingDeleteButton ? 1.0 : 0.7)
                }
            }
        )
        .clipped()
        .onTapGesture {
            if showingDeleteButton {
                // Hide delete button when tapping elsewhere
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = .zero
                    showingDeleteButton = false
                }
            } else {
                // Normal tap behavior (copy)
                copyHexCode()
            }
        }
        .simultaneousGesture(
            // Add press feedback
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    private var rgbString: String {
        let color = UIColor(card.color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return "RGB(\(r), \(g), \(b))"
    }
    
    private func copyHexCode() {
        UIPasteboard.general.string = "#\(card.hexCode)"
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingCopiedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingCopiedFeedback = false
            }
        }
    }
}

#Preview {
    ColorsView()
}
