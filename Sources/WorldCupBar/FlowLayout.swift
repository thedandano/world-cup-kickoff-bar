import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? 320
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let height = rows.reduce(CGFloat.zero) { partialResult, row in
            partialResult + row.height
        } + CGFloat(max(rows.count - 1, 0)) * spacing

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var origin = bounds.origin

        for row in rows {
            origin.x = bounds.minX

            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: origin.x, y: origin.y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(element.size)
                )
                origin.x += element.size.width + spacing
            }

            origin.y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [FlowRow] {
        var rows: [FlowRow] = []
        var currentRow = FlowRow()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = currentRow.width == 0 ? size.width : currentRow.width + spacing + size.width

            if proposedWidth > maxWidth, !currentRow.elements.isEmpty {
                rows.append(currentRow)
                currentRow = FlowRow()
            }

            currentRow.append(index: index, size: size, spacing: spacing)
        }

        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct FlowRow {
    var elements: [FlowElement] = []
    var width: CGFloat = 0
    var height: CGFloat = 0

    mutating func append(index: Int, size: CGSize, spacing: CGFloat) {
        if elements.isEmpty {
            width = size.width
        } else {
            width += spacing + size.width
        }

        height = max(height, size.height)
        elements.append(FlowElement(index: index, size: size))
    }
}

private struct FlowElement {
    let index: Int
    let size: CGSize
}
