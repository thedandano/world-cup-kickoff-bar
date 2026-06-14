import Testing
import WorldCupBarCore

@Test func vsMarkStyleHasFourCases() {
    #expect(VSMarkStyle.allCases.count == 4)
}

@Test func vsMarkStyleRoundTripsThroughRawValue() {
    for style in VSMarkStyle.allCases {
        #expect(VSMarkStyle(rawValue: style.rawValue) == style)
    }
}

@Test func vsMarkStyleDisplayNamesAreNonEmpty() {
    for style in VSMarkStyle.allCases {
        #expect(!style.displayName.isEmpty)
    }
}

@Test func vsMarkStyleDefaultRawValuesAreStable() {
    #expect(VSMarkStyle.italic.rawValue == "italic")
    #expect(VSMarkStyle.ring.rawValue == "ring")
    #expect(VSMarkStyle.slash.rawValue == "slash")
    #expect(VSMarkStyle.clash.rawValue == "clash")
}

@Test func teamLabelUsesCodeInAbbreviationsMode() {
    let formatter = MatchFormatter()
    #expect(formatter.teamLabel(for: .unitedStates, displayMode: .abbreviations) == "USA")
}

@Test func teamLabelFallsBackToCodeWhenNoRenderableFlag() {
    let formatter = MatchFormatter()
    let country = Country.unitedStates
    let expected = country.hasRenderableFlag ? country.flagEmoji : country.code
    #expect(formatter.teamLabel(for: country, displayMode: .flags) == expected)
}

@Test func vsMarkStyleTextSeparatorsAreNonEmpty() {
    for style in VSMarkStyle.allCases {
        #expect(!style.textSeparator.isEmpty)
    }
}

@Test func vsMarkStyleSlashAndClashHaveDistinctTextSeparators() {
    #expect(VSMarkStyle.slash.textSeparator == "v/s")
    #expect(VSMarkStyle.clash.textSeparator == "V/S")
    #expect(VSMarkStyle.italic.textSeparator == "vs")
    #expect(VSMarkStyle.ring.textSeparator == "vs")
}
