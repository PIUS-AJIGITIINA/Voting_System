import HashMap "mo:base/HashMap";
import Text"mo:base/Text";
actor VotingSystem {
  private type Candidate = Text;
  private type VoterId = Principal;

  // System state
  private var candidates : [Candidate] = [];
  private var votes : [(Candidate, Nat)] = [];
  private var voters : [VoterId] = [];
  private var admins : [Principal] = [];
  private var initialized : Bool = false;

  // Initialize with the deployer as the first admin
  public shared (msg) func init() : async () {
    if (not initialized) {
      admins := [msg.caller];
      initialized := true
    }
  };

  // Add a new admin (only callable by existing admins)
  public shared (msg) func addAdmin(newAdmin : Principal) : async Bool {
    assert isAdmin(msg.caller);
    if (isAdmin(newAdmin)) return false;

    admins := Array.append(admins, [newAdmin]);
    true
  };

  // Add a new candidate (admin only)
  public shared (msg) func addCandidate(name : Candidate) : async Bool {
    assert isAdmin(msg.caller);
    assert name.size() > 0;

    if (Array.find<Candidate>(candidates, func(c) {c == name}) != null) {
      return false
    };

    candidates := Array.append(candidates, [name]);
    votes := Array.append(votes, [(name, 0)]);
    true
  };

  // Cast a vote (one attempt per voter)
  public shared (msg) func vote(candidate : Candidate) : async Bool {
    // Check if already voted
    if (hasVoted(msg.caller)) {
      return false
    };

    // Check if candidate exists
    switch (Array.find<Candidate>(candidates, func(c) {c == candidate})) {
      case null {return false};
      case (?_) {
        // Record the voter
        voters := Array.append(voters, [msg.caller]);

        // Update vote count
        votes := Array.map<(Candidate, Nat)>(
          votes,
          func((c, count)) {
            if (c == candidate) (c, count + 1) else (c, count)
          }
        );
        return true
      }
    }
  };

  // Get list of candidates
  public query func getCandidates() : async [Candidate] {
    candidates
  };

  // Get current vote counts
  public query func getVotes() : async [(Candidate, Nat)] {
    votes
  };

  // Check if voter has already voted
  public query func hasVoted(voter : Principal) : async Bool {
    Array.find<VoterId>(voters, func(v) {v == voter}) != null
  };

  // Check if caller is admin
  public query func isCallerAdmin() : async Bool {
    isAdmin(msg.caller)
  };

  // Helper function to check admin status
  private func isAdmin(user : Principal) : Bool {
    Array.find<Principal>(admins, func(a) {a == user}) != null
  };

  // Private version of hasVoted for internal use
  private func hasVoted(voter : Principal) : Bool {
    Array.find<VoterId>(voters, func(v) {v == voter}) != null
  }
}