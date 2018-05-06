import Foundation

//MARK: - Util functions.

/// Calculates money from a transaction statement.
///
/// - Parameter str: Transaction statement string
/// - Returns: money
func moneyFrom(_ str: String) -> NSDecimalNumber {
    //http://regexlib.com/Search.aspx?k=currency
    let moneyPattern = "\\$([0-9]{1,3},([0-9]{3},)*[0-9]{3}|[0-9]+)(.[0-9][0-9])?"
    let matches = regexMatches(for:moneyPattern,in:str)
    guard matches.count > 0 else {
        print("❌ Invalid transaction, no money: \(str)")
        exit(1)
    }
    let moneyString = matches[0].replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
    return NSDecimalNumber(string: moneyString)
}


/// Fetches name from a transaction statement
///
/// - Parameter str: Transaction statement string
/// - Returns: name
func nameFrom(_ str: String) -> String {
    let namePattern = "(to|by) [a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*"
    let matches = regexMatches(for:namePattern,in:str)
    guard matches.count > 0 else {
        print("❌ Invalid transaction, no name: \(str)")
        exit(1)
    }
    let nameString = matches[0].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").dropLast().dropFirst().joined(separator: " ")
    return nameString
}

/// Fetches date from a transaction statement
///
/// - Parameter str: Transaction statement
/// - Returns: Date
func dateFrom(_ str: String) -> Date {
    let datePattern = "(((0?[1-9]|1[012])/(0?[1-9]|1\\d|2[0-8])|(0?[13456789]|1[012])/(29|30)|(0?[13578]|1[02])/31)/(19|[2-9]\\d)\\d{2}|0?2/29/((19|[2-9]\\d)(0[48]|[2468][048]|[13579][26])|(([2468][048]|[3579][26])00)))"
    let matches = regexMatches(for:datePattern,in:str)
    guard matches.count > 0 else {
        print("❌ Invalid transaction, no date: \(str)")
        exit(1)
    }
    let foramtter = DateFormatter()
    foramtter.dateFormat = "MM/dd/yyyy"
    guard let date =  foramtter.date(from: matches[0]) else {
        print("❌ Invalid transaction, can't get date from: \(str)")
        exit(1)
    }
    return date
}


/// Finds matches of a regex for a string
///
/// - Parameters:
///   - regex: regex to match against
///   - text: Text to find matches in
/// - Returns: Regex matches in a string.
func regexMatches(for regex: String, in text: String) -> [String] {
    
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("❌ Invalid regex: \(error.localizedDescription)")
        return []
    }
}

//MARK - GROUP BY array
extension Array {
    func grouped<T>(by criteria:(Element) -> T) -> [T:[Element]] {
        var groups = [T: [Element]]()
        for element in self {
            let key = criteria(element)
            if groups.keys.contains(key) == false {
                groups[key] = [Element]()
            }
            groups[key]?.append(element)
        }
        return groups
    }
}
//MARK: Main
guard CommandLine.arguments.count == 2 else {
    print("❌ Invalid arguments, Please provide transfer history's file path!!")
    exit(1)
}
let filePath = CommandLine.arguments[1]
let fileManager = FileManager.default

guard fileManager.fileExists(atPath: filePath) else {
    print("❌ File doesn't exists at \(filePath)")
    exit(1)
}

let data = try String(contentsOfFile: filePath, encoding: .utf8)
let lines = data.components(separatedBy: .newlines).filter(){$0 != ""}

let transfers = lines.map { line -> Transfer in
    let money = moneyFrom(line)
    let name = nameFrom(line)
    let date = dateFrom(line)
    return Transfer(name: name, date: date, amount: money)
}

let groupedTransactions = transfers.grouped { (transfer) -> String in
    return transfer.name
}

groupedTransactions.forEach { (name, transfers) in
    let total = transfers.reduce(0.0, { sum, transfer in
        sum + (transfer.amount as Decimal)
    })
    print("\(name) : \(total)")
}
