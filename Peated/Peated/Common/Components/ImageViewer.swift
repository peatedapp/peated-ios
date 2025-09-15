import SwiftUI

struct ImageViewer: View {
  let imageUrl: String
  @Binding var isPresented: Bool
  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero
  @GestureState private var magnifyBy = 1.0
  
  var body: some View {
    // Compute a subtle fade based on vertical pull distance
    let dismissProgress = min(1, max(0, abs(offset.height) / 240))
    let bgOpacity = 1 - (0.6 * dismissProgress)
    
    ZStack {
      // Background: use app standard dark background so edges match the app
      Color.background
        .opacity(bgOpacity)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation {
            isPresented = false
          }
        }
      
      // Image
      if let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              // Render the image over white so transparent pixels appear on white,
              // while the surrounding edges use our dark app background.
              .background(Color.white)
              .scaleEffect(scale * magnifyBy)
              .offset(offset)
              .gesture(
                SimultaneousGesture(
                  // Pinch to zoom
                  MagnificationGesture()
                    .updating($magnifyBy) { currentState, gestureState, _ in
                      gestureState = currentState
                    }
                    .onEnded { value in
                      scale *= value
                      scale = min(max(scale, 1), 4) // Limit zoom between 1x and 4x
                    },
                  
                  // Pan / drag gesture
                  DragGesture()
                    .onChanged { value in
                      if scale == 1 {
                        // When not zoomed, treat vertical drag as a potential dismiss gesture
                        offset = CGSize(width: 0, height: value.translation.height)
                      } else {
                        // When zoomed, allow panning in both directions
                        offset = CGSize(
                          width: lastOffset.width + value.translation.width,
                          height: lastOffset.height + value.translation.height
                        )
                      }
                    }
                    .onEnded { value in
                      if scale == 1 {
                        // Close if dragged down sufficiently
                        if value.translation.height > 120 {
                          withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isPresented = false
                          }
                        } else {
                          withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            offset = .zero
                            lastOffset = .zero
                          }
                        }
                      } else {
                        // Persist panning offset while zoomed
                        lastOffset = offset
                      }
                    }
                )
              )
              .onTapGesture(count: 2) {
                // Double tap to zoom
                withAnimation {
                  if scale > 1 {
                    scale = 1
                    offset = .zero
                    lastOffset = .zero
                  } else {
                    scale = 2
                  }
                }
              }
              
          case .failure:
            VStack(spacing: 16) {
              Image(systemName: "photo.slash")
                .font(.system(size: 50))
                .foregroundColor(.textMuted)
              Text("Failed to load image")
                .foregroundColor(.textSecondary)
            }
            
          case .empty:
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .onStatus))
              .scaleEffect(1.5)
            
          @unknown default:
            EmptyView()
          }
        }
      }
      
      // Close button
      VStack {
        HStack {
          Spacer()
          Button {
            isPresented = false
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.onStatus.opacity(0.85))
              .background(Circle().fill(Color.overlay))
          }
          .padding()
        }
        Spacer()
      }
    }
    .statusBarHidden()
  }
}

// Helper modifier for presenting image viewer
struct ImageViewerModifier: ViewModifier {
  let imageUrl: String?
  @Binding var isPresented: Bool
  
  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isPresented) {
        if let imageUrl = imageUrl {
          ImageViewer(imageUrl: imageUrl, isPresented: $isPresented)
        }
      }
  }
}

extension View {
  func imageViewer(imageUrl: String?, isPresented: Binding<Bool>) -> some View {
    modifier(ImageViewerModifier(imageUrl: imageUrl, isPresented: isPresented))
  }
}
