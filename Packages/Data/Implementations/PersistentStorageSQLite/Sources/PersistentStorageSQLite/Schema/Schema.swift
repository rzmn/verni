import Foundation
internal import SQLite

typealias Expression = SQLite.Expression

@StorageActor private class TableProvider {
    private static var tables = [String: Table]()

    static subscript(table name: String) -> Table {
        guard let table = tables[name] else {
            let table = Table(name)
            tables[name] = table
            return table
        }
        return table
    }
}

@StorageActor protocol SQLTableKeys {
    static var tableNameKey: String { get }
}

@StorageActor enum SQLTable<Keys: SQLTableKeys> {
    typealias Keys = Keys

    static var table: Table {
        TableProvider[table: Keys.tableNameKey]
    }
}

@StorageActor enum Schema {}
