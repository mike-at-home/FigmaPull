import Foundation
import FigmaPullCore

// MARK: - Default.BlendModePassThrough

extension Default where T == FigmaV1.BlendMode {
    public enum BlendModePassThrough: DefaultableSource {
        public static var `default`: T { .passThrough }
    }
}

// MARK: - Default.BlendModeNormal

extension Default where T == FigmaV1.BlendMode {
    public enum BlendModeNormal: DefaultableSource {
        public static var `default`: T { .normal }
    }
}

// MARK: - Default.StrokeCapNone

extension Default where T == FigmaV1.StrokeCap {
    public enum StrokeCapNone: DefaultableSource {
        public static var `default`: T { .none }
    }
}

// MARK: - Default.StrokeJoinMiter

extension Default where T == FigmaV1.StrokeJoin {
    public enum StrokeJoinMiter: DefaultableSource {
        public static var `default`: T { .miter }
    }
}
