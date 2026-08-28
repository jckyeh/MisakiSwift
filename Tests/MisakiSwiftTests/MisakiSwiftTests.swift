import Foundation
import Testing
@testable import MisakiSwift

let texts: [(originalText: String, britishPhonetization: String, americanPhoneitization: String)] = [
  ("[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models.",
   "misˈɑki ɪz ɐ ʤˈiːtəpˈiː ˈɛnʤɪn dɪzˈInd fɔː kˈOkəɹO mˈɒdᵊlz.",
   "misˈɑki ɪz ɐ ʤˈitəpˈi ˈɛnʤən dəzˈInd fɔɹ kˈOkəɹO mˈɑdᵊlz."),
  ("“To James Mortimer, M.R.C.S., from his friends of the C.C.H.,” was engraved upon it, with the date “1884.”",
   "“tə ʤˈAmz mˈɔːtɪmə, ˌɛmˌɑːsˌiːˈɛs, fɹɒm hɪz fɹˈɛndz ɒv ðə sˌiːsˌiːˈAʧ,” wɒz ɪnɡɹˈAvd əpˈɒn ɪt, wɪð ðə dˈAt “ˌAtˈiːn ˈAti fˈɔː.”",
   "“tə ʤˈAmz mˈɔɹTəməɹ, ˌɛmˌɑɹsˌiˈɛs, fɹʌm hɪz fɹˈɛndz ʌv ðə sˌisˌiˈAʧ,” wʌz ɪnɡɹˈAvd əpˈɑn ɪt, wɪð ðə dˈAt “ˌAtˈin ˈATi fˈɔɹ.”")
]

@Test func testStrings_BritishPhonetization() async throws {
  let englishG2P = EnglishG2P(british: true)
  
  for pair in texts {
    #expect(englishG2P.phonemize(text: pair.0).0 == pair.1)
  }
}

@Test func testStrings_AmericanPhonetization() async throws {
  let englishG2P = EnglishG2P(british: false)

  for pair in texts {
    #expect(englishG2P.phonemize(text: pair.0).0 == pair.2)
  }
}

@Test func testEnglishNum2Word_TwentyThroughTwentyNine() {
  let converter = EnglishNum2Word()
  let expected = [
    "twenty", "twenty-one", "twenty-two", "twenty-three",
    "twenty-four", "twenty-five", "twenty-six",
    "twenty-seven", "twenty-eight", "twenty-nine"
  ]

  for (offset, words) in expected.enumerated() {
    #expect(converter.convert(Decimal(20 + offset)) == words)
  }
}

@Test func testEnglishG2P_QuotedTwentyOneIsNotReducedToOne() {
  let englishG2P = EnglishG2P(british: false)
  let (numeric, _) = englishG2P.phonemize(text: "“21“")
  let (spelledOut, _) = englishG2P.phonemize(text: "“twenty one“")
  let (one, _) = englishG2P.phonemize(text: "“one“")

  #expect(numeric == spelledOut)
  #expect(numeric != one)
}

@Test func testEnglishNum2Word_RecursiveTwentyForms() {
  let converter = EnglishNum2Word()

  #expect(converter.convert(Decimal(121)) == "one hundred and twenty-one")
  #expect(converter.convert(Decimal(1_021)) == "one thousand, twenty-one")
  #expect(converter.convert(Decimal(2_021), to: .year) == "twenty twenty-one")
  #expect(converter.convert(Decimal(string: "21.5")!) == "twenty-one point five")
  #expect(converter.convert(Decimal(21), to: .ordinal) == "twenty-First")
}

@Test(arguments: [false, true])
func testUppercaseChapterOpeningPersonalNameUsesWordPronunciation(british: Bool) {
  let englishG2P = EnglishG2P(british: british)
  let reported = "DONALD SPED DOWN highway 17, a flashing red light on his dash."
  let baseline = "Donald sped down highway 17, a flashing red light on his dash."
  let (reportedPhonemes, reportedTokens) = englishG2P.phonemize(text: reported)
  let (baselinePhonemes, _) = englishG2P.phonemize(text: baseline)

  #expect(reportedPhonemes == baselinePhonemes)
  let donald = reportedTokens.first { $0.text == "DONALD" }
  #expect(donald != nil)
  #expect(donald?.phonemes != nil)
  if let range = donald?.tokenRange {
    #expect(String(reported[range]) == "DONALD")
  }
}

@Test(arguments: [false, true])
func testExactUppercaseITIsSpelledWithoutChangingItsToken(british: Bool) {
  let englishG2P = EnglishG2P(british: british)
  let reported = "The head of IT stood alone."
  let (reportedPhonemes, reportedTokens) = englishG2P.phonemize(text: reported)
  let (spelledPhonemes, _) = englishG2P.phonemize(text: "The head of I T stood alone.")
  let (lowercasePhonemes, _) = englishG2P.phonemize(text: "The head of it stood alone.")
  let (capitalizedPhonemes, _) = englishG2P.phonemize(text: "The head of It stood alone.")

  #expect(reportedPhonemes.filter { !$0.isWhitespace }
    == spelledPhonemes.filter { !$0.isWhitespace })
  #expect(reportedPhonemes != lowercasePhonemes)
  #expect(reportedPhonemes != capitalizedPhonemes)
  let initialism = reportedTokens.first { $0.text == "IT" }
  #expect(initialism != nil)
  if let range = initialism?.tokenRange {
    #expect(String(reported[range]) == "IT")
  }
}

@Test func testPronunciationOnlyCasingPolicyIsNarrow() {
  #expect(EnglishG2P.pronunciationSpelling(for: "DONALD", tag: .personalName) == "Donald")
  #expect(EnglishG2P.pronunciationSpelling(for: "SPED", tag: .verb) == "SPED")
  #expect(EnglishG2P.pronunciationSpelling(for: "DOWN", tag: .particle) == "DOWN")
  #expect(EnglishG2P.pronunciationSpelling(for: "HAL", tag: .personalName) == "HAL")
  #expect(EnglishG2P.pronunciationSpelling(for: "FBI", tag: .organizationName) == "FBI")
  #expect(EnglishG2P.pronunciationSpelling(for: "JFK", tag: .placeName) == "JFK")
  #expect(EnglishG2P.pronunciationSpelling(for: "USSR", tag: .organizationName) == "USSR")
  #expect(EnglishG2P.pronunciationSpelling(for: "NASA", tag: .organizationName) == "NASA")
  #expect(EnglishG2P.pronunciationSpelling(for: "DÓNALD", tag: .personalName) == "DÓNALD")

  #expect(Lexicon.forcedInitialisms == ["IT"])
  for ordinaryForm in ["it", "It", "US", "NO", "AM", "IN", "TO", "GO"] {
    #expect(!Lexicon.forcedInitialisms.contains(ordinaryForm))
  }
}

// Retokenize Currency Index Fix Tests
@Test func testRetokenize_CurrencyWithFollowingTokens() async throws {
  let englishG2P = EnglishG2P(british: true)
  let (result, _) = englishG2P.phonemize(text: "$50 is the price for this item")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɒlə"))  // "dollar" phoneme should be present
}

// Currency appearing mid-sentence with multiple tokens before and after
@Test func testRetokenize_CurrencyInMiddleOfSentence() async throws {
  let englishG2P = EnglishG2P(british: false)
  let (result, _) = englishG2P.phonemize(text: "The total cost was $100 and we paid it yesterday")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɑləɹz"))  // American "dollar" phoneme
}

// Multiple currency symbols trigger the currency code path multiple times
@Test func testRetokenize_MultipleCurrenciesInText() async throws {
  let englishG2P = EnglishG2P(british: true)
  let (result, _) = englishG2P.phonemize(text: "I exchanged $200 for €150 at the bank today")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɒlə"))    // "dollar" phoneme
  #expect(result.contains("jˈʊəɹQz"))  // "euro" phoneme
}
