import Foundation

enum StudentRoute: Hashable {
    case detail(Int)
    case diary(Int)
    case piece(studentId: Int, pieceId: Int)
}
