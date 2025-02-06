import Foundation
import SQLite3
import AppKit

enum DatabaseError: Error {
    case connectionFailed
    case prepareFailed
    case executeFailed
    case queryFailed
    case connectionError
    case executionError(String)
}

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("macollama.sqlite")
        print(fileURL)
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            createTable()
        } else {
            print("Database connection failed")
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS questions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          groupid TEXT NOT NULL,
          instruction TEXT,
          question TEXT,
          answer TEXT,
          image TEXT,
          created TEXT,
          engine TEXT
        );
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
        
        insertInitialDataIfNeeded()
    }
    
    private func insertInitialDataIfNeeded() {
        do {
            let uuid = UUID().uuidString
            let results = try fetchTitles()
            guard results.isEmpty else { return }
            
            let initialData = [
                ("l_q1", "l_a1"),
                ("l_q2", "l_a2"),
                ("l_q3", "l_a3")
            ]
            
            for (question, answer) in initialData {
                try insert(
                    groupId: uuid,
                    instruction: "",
                    question: question.localized,
                    answer: answer.localized,
                    image: nil,
                    engine: "LLM Hippo"
                )
            }
        } catch {
            print("Failed to insert initial data: \(error)")
        }
    }
        
    func insert(groupId: String, instruction: String?, question: String, answer: String, image: NSImage?, engine: String) throws {
        let insertSQL = """
            INSERT INTO questions (groupid, instruction, question, answer, image, created, engine)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
        
        var statement: OpaquePointer?
        
        let dateFormatter = ISO8601DateFormatter()
        let currentTime = dateFormatter.string(from: Date())
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        var imageBase64: String? = nil
        if let image = image,
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
            imageBase64 = jpegData.base64EncodedString()
        }
        
        sqlite3_bind_text(statement, 1, (groupId as NSString).utf8String, -1, nil)
        
        if let instruction = instruction {
            sqlite3_bind_text(statement, 2, (instruction as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        
        sqlite3_bind_text(statement, 3, (question as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (answer as NSString).utf8String, -1, nil)
        
        if let imageBase64 = imageBase64 {
            sqlite3_bind_text(statement, 5, (imageBase64 as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        sqlite3_bind_text(statement, 6, (currentTime as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 7, (engine as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            sqlite3_finalize(statement)
            throw DatabaseError.executeFailed
        }
        
        sqlite3_finalize(statement)
    }
    
    func fetchTitles() throws -> [(id: Int, groupId: String, instruction: String?, question: String, answer: String, image: String?, created: String, engine: String)] {
        let query = "SELECT * FROM questions GROUP BY groupid ORDER BY id DESC;"
        var statement: OpaquePointer?
        var results: [(id: Int, groupId: String, instruction: String?, question: String, answer: String, image: String?, created: String, engine: String)] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let groupId = String(cString: sqlite3_column_text(statement, 1))
            let instruction = sqlite3_column_text(statement, 2).map { String(cString: $0) }
            let question = String(cString: sqlite3_column_text(statement, 3))
            let answer = String(cString: sqlite3_column_text(statement, 4))
            let image = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let created = String(cString: sqlite3_column_text(statement, 6))
            let engine = String(cString: sqlite3_column_text(statement, 7))
            
            results.append((id, groupId, instruction, question, answer, image, created, engine))
        }
        
        sqlite3_finalize(statement)
        return results
    }

    
    func fetchAllQuestions() throws -> [(id: Int, groupId: String, instruction: String?, question: String, answer: String, image: String?, created: String, engine: String)] {
        let query = "SELECT * FROM questions ORDER BY created DESC;"
        var statement: OpaquePointer?
        var results: [(id: Int, groupId: String, instruction: String?, question: String, answer: String, image: String?, created: String, engine: String)] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let groupId = String(cString: sqlite3_column_text(statement, 1))
            let instruction = sqlite3_column_text(statement, 2).map { String(cString: $0) }
            let question = String(cString: sqlite3_column_text(statement, 3))
            let answer = String(cString: sqlite3_column_text(statement, 4))
            let image = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let created = String(cString: sqlite3_column_text(statement, 6))
            let engine = String(cString: sqlite3_column_text(statement, 7))
            
            results.append((id, groupId, instruction, question, answer, image, created, engine))
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    func update(id: Int, answer: String) throws {
        let updateQuery = "UPDATE questions SET answer = ? WHERE id = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        sqlite3_bind_text(statement, 1, (answer as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            sqlite3_finalize(statement)
            throw DatabaseError.executeFailed
        }
        
        sqlite3_finalize(statement)
    }
    
    func delete(id: Int) throws {
        let originalId = id % 2 == 0 ? id/2 : (id-1)/2
        
        let deleteQuery = "DELETE FROM questions WHERE id = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        sqlite3_bind_int(statement, 1, Int32(originalId))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            sqlite3_finalize(statement)
            throw DatabaseError.executeFailed
        }
        
        sqlite3_finalize(statement)
    }

    

    func fetchQuestionsByGroupId(_ groupId: String) throws -> [(id: Int, question: String, answer: String, created: String, image: String?, engine: String)] {
        let query = """
            SELECT id, question, answer, created, image, engine 
            FROM questions
            WHERE groupid = ?
            ORDER BY id ASC;
            """
        
        var statement: OpaquePointer?
        var results: [(id: Int, question: String, answer: String, created: String, image: String?, engine: String)] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        sqlite3_bind_text(statement, 1, (groupId as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let question = String(cString: sqlite3_column_text(statement, 1))
            let answer = String(cString: sqlite3_column_text(statement, 2))
            let created = String(cString: sqlite3_column_text(statement, 3))
            let image = sqlite3_column_text(statement, 4).map { String(cString: $0) }
            let engine = String(cString: sqlite3_column_text(statement, 5))

            results.append((id, question, answer, created, image, engine))
        }
        
        sqlite3_finalize(statement)
        return results
    }

    func deleteGroupChats(groupId: String) throws {
        let deleteQuery = "DELETE FROM questions WHERE groupid = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        sqlite3_bind_text(statement, 1, (groupId as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            sqlite3_finalize(statement)
            throw DatabaseError.executeFailed
        }
        
        sqlite3_finalize(statement)
    }

    func searchMessages(keyword: String) throws -> [(id: Int, groupId: String, question: String, answer: String, created: String, engine: String, image: String?)] {
        let pattern = "%\(keyword)%"
        
        let query = """
            SELECT id, groupid, question, answer, created, engine, image
            FROM questions
            WHERE question LIKE ? OR answer LIKE ?
            ORDER BY created DESC;
        """
        
        var statement: OpaquePointer?
        var results: [(id: Int, groupId: String, question: String, answer: String, created: String, engine: String, image: String?)] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        sqlite3_bind_text(statement, 1, (pattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (pattern as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let groupId = String(cString: sqlite3_column_text(statement, 1))
            let question = String(cString: sqlite3_column_text(statement, 2))
            let answer = String(cString: sqlite3_column_text(statement, 3))
            let created = String(cString: sqlite3_column_text(statement, 4))
            let engine = String(cString: sqlite3_column_text(statement, 5))
            let image = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            
            results.append((id, groupId, question, answer, created, engine, image))
        }
        
        sqlite3_finalize(statement)
        return results
    }

    func deleteAllData() throws {
        let deleteSQL = "DELETE FROM questions;"
        var statement: OpaquePointer?
        
        guard let db = db else {
            throw DatabaseError.connectionError
        }
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            sqlite3_finalize(statement)
            throw DatabaseError.executeFailed
        }
        
        sqlite3_finalize(statement)
    }
} 
