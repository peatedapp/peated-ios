#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// Usage: recolor-png.swift <input.png> <output.png> <HEX>
// Sets RGB of all non-transparent pixels to target hex color, preserves alpha.

func hexToRGB(_ hex: String) -> (UInt8, UInt8, UInt8)? {
  var h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
  if h.count == 3 { // short form RGB
    h = h.map { "\($0)\($0)" }.joined()
  }
  guard h.count == 6, let v = Int(h, radix: 16) else { return nil }
  let r = UInt8((v >> 16) & 0xFF)
  let g = UInt8((v >> 8) & 0xFF)
  let b = UInt8(v & 0xFF)
  return (r, g, b)
}

guard CommandLine.arguments.count == 4 else {
  fputs("Usage: recolor-png.swift <input.png> <output.png> <HEX>\n", stderr)
  exit(2)
}
let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
let hex = CommandLine.arguments[3]

guard let (tr, tg, tb) = hexToRGB(hex) else {
  fputs("Invalid hex color: \(hex)\n", stderr)
  exit(2)
}

let url = URL(fileURLWithPath: inputPath)
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
  fputs("Failed to read image: \(inputPath)\n", stderr)
  exit(1)
}

let width = image.width
let height = image.height
let bitsPerComponent = 8
let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
  fputs("Failed to create CGContext\n", stderr)
  exit(1)
}

ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
guard let data = ctx.data else {
  fputs("Failed to access pixel data\n", stderr)
  exit(1)
}

let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: Int(bytesPerRow * height))
for y in 0..<height {
  for x in 0..<width {
    let idx = (y * bytesPerRow) + (x * bytesPerPixel)
    let r = pixelBuffer[idx]
    let g = pixelBuffer[idx + 1]
    let b = pixelBuffer[idx + 2]
    let a = pixelBuffer[idx + 3]
    if a > 0 { // non-transparent
      // Set to target color, keep alpha
      pixelBuffer[idx] = tr
      pixelBuffer[idx + 1] = tg
      pixelBuffer[idx + 2] = tb
      pixelBuffer[idx + 3] = a
    } else {
      // leave transparent pixel as-is
      _ = (r, g, b) // no-op to silence warnings
    }
  }
}

guard let outImage = ctx.makeImage() else {
  fputs("Failed to create output image\n", stderr)
  exit(1)
}

let destURL = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, kUTTypePNG, 1, nil) else {
  fputs("Failed to create image destination\n", stderr)
  exit(1)
}
CGImageDestinationAddImage(dest, outImage, nil)
if !CGImageDestinationFinalize(dest) {
  fputs("Failed to write output image\n", stderr)
  exit(1)
}
print("Recolored → \(outputPath) with #\(hex)")

