#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: icon_render.swift <size> <output.png>\n".utf8))
    exit(2)
}

let size = CGFloat(Int(CommandLine.arguments[1]) ?? 1024)
let outPath = CommandLine.arguments[2]

let canvasSize = NSSize(width: size, height: size)
let image = NSImage(size: canvasSize)
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }
ctx.interpolationQuality = .high

let inset = size * 0.085
let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = rect.width * 0.2237

let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
ctx.saveGState()
squircle.addClip()

let bg = NSGradient(colors: [
    NSColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1.0),
    NSColor(red: 0.06, green: 0.20, blue: 0.18, alpha: 1.0),
    NSColor(red: 0.09, green: 0.12, blue: 0.22, alpha: 1.0),
])!
bg.draw(in: rect, angle: 125)

let glow = NSGradient(
    starting: NSColor(red: 0.25, green: 0.86, blue: 0.63, alpha: 0.55),
    ending: NSColor(red: 0.25, green: 0.86, blue: 0.63, alpha: 0.0)
)!
let glowRect = CGRect(
    x: rect.minX - rect.width * 0.25,
    y: rect.maxY - rect.height * 0.55,
    width: rect.width * 0.85,
    height: rect.height * 0.85
)
glow.draw(in: glowRect, relativeCenterPosition: .zero)

let highlight = NSGradient(
    starting: NSColor(red: 1.00, green: 0.78, blue: 0.34, alpha: 0.35),
    ending: NSColor(red: 1.00, green: 0.46, blue: 0.27, alpha: 0.0)
)!
let highlightRect = CGRect(
    x: rect.maxX - rect.width * 0.6,
    y: rect.minY - rect.height * 0.2,
    width: rect.width * 0.8,
    height: rect.height * 0.8
)
highlight.draw(in: highlightRect, relativeCenterPosition: .zero)

let gridPad = rect.width * 0.16
let gridRect = rect.insetBy(dx: gridPad, dy: gridPad)
let gridCount = 7
let cellSpacing = gridRect.width * 0.045
let cellSize =
    (gridRect.width - cellSpacing * CGFloat(gridCount - 1)) / CGFloat(gridCount)
let cellRadius = cellSize * 0.22

let livedRows = 4
let currentRow = 4
let currentCol = 3

let livedGradient = NSGradient(colors: [
    NSColor(red: 0.30, green: 0.92, blue: 0.68, alpha: 1.0),
    NSColor(red: 0.10, green: 0.62, blue: 0.52, alpha: 1.0),
])!

let currentGradient = NSGradient(colors: [
    NSColor(red: 1.00, green: 0.80, blue: 0.36, alpha: 1.0),
    NSColor(red: 1.00, green: 0.46, blue: 0.27, alpha: 1.0),
])!

for row in 0..<gridCount {
    for col in 0..<gridCount {
        let x = gridRect.minX + CGFloat(col) * (cellSize + cellSpacing)
        let y =
            gridRect.maxY - cellSize - CGFloat(row) * (cellSize + cellSpacing)
        let cellRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
        let cellPath = NSBezierPath(
            roundedRect: cellRect, xRadius: cellRadius, yRadius: cellRadius)

        let isLived =
            row < livedRows || (row == currentRow && col < currentCol)
        let isCurrent = row == currentRow && col == currentCol

        if isLived {
            ctx.saveGState()
            cellPath.addClip()
            livedGradient.draw(in: cellRect, angle: -45)
            ctx.restoreGState()
        } else if isCurrent {
            ctx.saveGState()
            ctx.setShadow(
                offset: .zero, blur: cellSize * 0.55,
                color: NSColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 0.9).cgColor)
            NSColor.white.withAlphaComponent(0.0).setFill()
            cellPath.fill()
            ctx.restoreGState()

            ctx.saveGState()
            cellPath.addClip()
            currentGradient.draw(in: cellRect, angle: -45)
            ctx.restoreGState()

            NSColor.white.withAlphaComponent(0.85).setStroke()
            cellPath.lineWidth = max(1, cellSize * 0.06)
            cellPath.stroke()
        } else {
            NSColor.white.withAlphaComponent(0.10).setFill()
            cellPath.fill()
            NSColor.white.withAlphaComponent(0.18).setStroke()
            cellPath.lineWidth = max(0.5, cellSize * 0.03)
            cellPath.stroke()
        }
    }
}

ctx.restoreGState()

NSColor.white.withAlphaComponent(0.10).setStroke()
squircle.lineWidth = max(1, size * 0.004)
squircle.stroke()

let topSheenPath = NSBezierPath()
topSheenPath.move(to: CGPoint(x: rect.minX, y: rect.midY))
topSheenPath.curve(
    to: CGPoint(x: rect.maxX, y: rect.midY),
    controlPoint1: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.maxY),
    controlPoint2: CGPoint(x: rect.minX + rect.width * 0.6, y: rect.maxY)
)
topSheenPath.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
topSheenPath.line(to: CGPoint(x: rect.minX, y: rect.maxY))
topSheenPath.close()
ctx.saveGState()
squircle.addClip()
topSheenPath.addClip()
let sheen = NSGradient(
    starting: NSColor.white.withAlphaComponent(0.10),
    ending: NSColor.white.withAlphaComponent(0.0)
)!
sheen.draw(in: rect, angle: 270)
ctx.restoreGState()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outPath))
