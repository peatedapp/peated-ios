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
    ZStack {
      // Background
      Color.black
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
                  
                  // Pan gesture
                  DragGesture()
                    .onChanged { value in
                      offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                      )
                    }
                    .onEnded { _ in
                      lastOffset = offset
                      
                      // Reset to center if zoomed out
                      if scale == 1 {
                        withAnimation {
                          offset = .zero
                          lastOffset = .zero
                        }
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
                .foregroundColor(.gray)
              Text("Failed to load image")
                .foregroundColor(.gray)
            }
            
          case .empty:
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
              .foregroundColor(.white.opacity(0.7))
              .background(Circle().fill(Color.black.opacity(0.3)))
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