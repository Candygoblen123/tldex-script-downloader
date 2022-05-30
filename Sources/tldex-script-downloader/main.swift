import Foundation

let video: String = CommandLine.arguments.indices.contains(1) ? CommandLine.arguments[1] : ""
let outPath: String = CommandLine.arguments.indices.contains(2) ? CommandLine.arguments[2] : FileManager.default.currentDirectoryPath.appending("/TLDex.srt")

if video == "" {
    print("Usage: tldex-script-downloader <video-id> <output-path>")
    exit(EXIT_FAILURE)
}


let sema = DispatchSemaphore(value: 0)
let urlVid = URL(string: "https://holodex.net/api/v2/videos/\(video)")
let requestVid = URLRequest(url: urlVid!)
var vidMeta: VidMeta?

let taskVid = URLSession.shared.dataTask(with: requestVid) { data, _, error in
    if let data = data {
        vidMeta = try! JSONDecoder().decode(VidMeta.self, from: data)
    }
    if let error = error {
        print(error)
        exit(EXIT_FAILURE)
    }
    sema.signal()
}

taskVid.resume()
sema.wait()

let sema2 = DispatchSemaphore(value: 0)
let urlTL = URL(string: "https://holodex.net/api/v2/videos/\(video)/chats?lang=en&verified=0&moderator=0&vtuber=0&tl=1&limit=100000")
let requestTL = URLRequest(url: urlTL!)
var outString = ""
let taskTL = URLSession.shared.dataTask(with: requestTL) { data, status, error in
    if let data = data {
        if String(data: data, encoding: .utf8)! == "[]" {
            print("Error: couldn't find video on TLDex, exiting...")
            exit(EXIT_FAILURE)
        }
        // print(String(data: data, encoding: .utf8)!)
        let script: [TLDex]? = try? JSONDecoder().decode([TLDex].self, from: data)
        if let vidMeta = vidMeta {
            if let script = script {
                let df = ISO8601DateFormatter()
                df.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

                let actualStart = (vidMeta.start_actual != nil) ? df.date(from: vidMeta.start_actual!) : df.date(from: vidMeta.available_at!)
                
                var i = 1
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss,SSS"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                for line in script {
                    let time = (Double(line.timestamp)! / 1000) - actualStart!.timeIntervalSince1970
                    let timestamp = Date(timeInterval: time, since: .distantPast)
                    var nextTimestamp = " --> 99:59:59,000"
                    
                    if i >= script.startIndex && i < script.endIndex {
                        nextTimestamp = " --> \(formatter.string(from: Date(timeInterval: ((Double(script[i].timestamp)! / 1000) - actualStart!.timeIntervalSince1970), since: .distantPast)))"
                    }
                    
                    outString.append("""
\(i)
\(formatter.string(from: timestamp))\(nextTimestamp)
\(line.message)


""")
                    i += 1
                }
            }
        }
    }
    if let error = error {
        print(error)
        exit(EXIT_FAILURE)
    }
    sema2.signal()
}


taskTL.resume()
sema2.wait()

//print(outString)
do {
    try outString.write(toFile: outPath, atomically: true, encoding: .utf8)
} catch {
    print(error)
    exit(EXIT_FAILURE)
}
