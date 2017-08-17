//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SessionRecord: NSObject, NSSecureCoding {
    
    private let archivedStatesMaxLength = 40
    
    public var sessionState: SessionState
    private(set) public var previousStates: [SessionState]
    private(set) public var isFresh: Bool
    
    
    public override init() {
        self.isFresh = true
        self.sessionState = SessionState()
        self.previousStates = []
    }
    
    public init(sessionState: SessionState) {
        self.isFresh = false
        self.sessionState = sessionState
        self.previousStates = []
    }
    
    public func hasSessionState(version: Int, baseKey: Data) -> Bool {
        return ((previousStates + [sessionState]).filter { $0.version == version && $0.aliceBaseKey == baseKey }.count > 0)
    }
    
    public func archiveCurrentState() {
        self.promote(SessionState())
    }
    
    public func promote(_ state: SessionState) {
        self.previousStates.insert(self.sessionState, at: 0)
        self.sessionState = state
        
        self.previousStates.removeLast(max(0, self.previousStates.count - self.archivedStatesMaxLength))
    }
    
    public func replace(_ oldSession: SessionState, with newSession: SessionState) {
        if self.sessionState == oldSession {
            self.sessionState = newSession
        }
        
        if let index = previousStates.index(of: oldSession) {
            previousStates[index] = newSession
        }
    }
    
    //MARK: NSSecureCoding
    
    private static let kSessionRecordCurrentSessionStateKey = "currentSessionStateKey"
    private static let kSessionRecordPreviousSessionSatesKey = "previousSessionStateKeys"
    
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.previousStates, forKey: SessionRecord.kSessionRecordPreviousSessionSatesKey)
        aCoder.encode(self.sessionState, forKey: SessionRecord.kSessionRecordCurrentSessionStateKey)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let previousStates = aDecoder.decodeObject(forKey: SessionRecord.kSessionRecordPreviousSessionSatesKey) as? [SessionState],
            let sessionState = aDecoder.decodeObject(forKey: SessionRecord.kSessionRecordCurrentSessionStateKey) as? SessionState else {
            return nil
        }
        
        self.isFresh = false
        self.previousStates = previousStates
        self.sessionState = sessionState
    }
}
