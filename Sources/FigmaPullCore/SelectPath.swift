import Foundation

struct SelectPath {
    var components: [Component]

    enum Component {
        case node
        case separator
    }

    struct NodeComponent {
        enum Name {
            case allChildren
            case descendantOrSelf
            case name(String)
        }
    }
    
    enum SeparatorComponent {
        case slash
    }


}

