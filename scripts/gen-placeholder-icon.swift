#!/usr/bin/env swift
//
// gen-placeholder-icon.swift — render a 1024×1024 placeholder app icon
// (lavender rounded square + ⚽) so the asset catalog has a real icon until
// you drop in your own art. Usage: swift gen-placeholder-icon.swift <out.png>
//
import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let side: CGFloat = 1024

let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: side, height: side)
NSColor(calibratedRed: 0.576, green: 0.439, blue: 0.820, alpha: 1).setFill()  // WCBColor.accent
NSBezierPath(roundedRect: rect, xRadius: side * 0.22, yRadius: side * 0.22).fill()

let ball = "⚽️" as NSString
let para = NSMutableParagraphStyle()
para.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: side * 0.58),
    .paragraphStyle: para,
]
let textSize = ball.size(withAttributes: attrs)
ball.draw(
    in: NSRect(x: 0, y: (side - textSize.height) / 2, width: side, height: textSize.height),
    withAttributes: attrs
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render icon\n".utf8))
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
