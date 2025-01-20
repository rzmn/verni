import SyncEngine
import Entities

struct State {
    var images: [Image.Identifier: LastWriteWinsCRDT<Image>]
}
