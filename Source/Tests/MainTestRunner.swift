import Foundation
import CoreGraphics
import QuartzCore

@main
struct MainTestRunner {
    static func main() {
        print("\n========================================================")
        print("   LidMotion Automated Test Suite (R1, R2, R3)")
        print("   E2E Testing Track — 4 Verification Tiers")
        print("========================================================\n")

        var allRecords: [TestCaseRecord] = []
        let tStart = CACurrentMediaTime()

        // ----------------------------------------------------
        // TIER 1: Feature Coverage (F1 - F9)
        // ----------------------------------------------------
        print("[TIER 1] Running Feature Coverage Tests (F1-F9)...")
        let tier1Suite = Tier1_FeatureCoverageTests()
        let t1Records = tier1Suite.runAll()
        allRecords.append(contentsOf: t1Records)
        printSummary(for: t1Records, tierName: "Tier 1: Feature Coverage")

        // ----------------------------------------------------
        // TIER 2: Boundary & Corner Cases
        // ----------------------------------------------------
        print("\n[TIER 2] Running Boundary & Corner Case Tests...")
        let tier2Suite = Tier2_BoundaryCornerTests()
        let t2Records = tier2Suite.runAll()
        allRecords.append(contentsOf: t2Records)
        printSummary(for: t2Records, tierName: "Tier 2: Boundary & Corner Cases")

        // ----------------------------------------------------
        // TIER 3: Cross-Feature Combinations
        // ----------------------------------------------------
        print("\n[TIER 3] Running Cross-Feature Pairwise Interaction Tests...")
        let tier3Suite = Tier3_CrossFeatureTests()
        let t3Records = tier3Suite.runAll()
        allRecords.append(contentsOf: t3Records)
        printSummary(for: t3Records, tierName: "Tier 3: Cross-Feature Combinations")

        // ----------------------------------------------------
        // TIER 4: Real-World Acceptance Scenarios
        // ----------------------------------------------------
        print("\n[TIER 4] Running Real-World Acceptance Scenarios...")
        let tier4Suite = Tier4_AcceptanceScenarioTests()
        let t4Records = tier4Suite.runAll()
        allRecords.append(contentsOf: t4Records)
        printSummary(for: t4Records, tierName: "Tier 4: Acceptance Scenarios")

        // ----------------------------------------------------
        // OVERALL SUMMARY
        // ----------------------------------------------------
        let totalElapsed = (CACurrentMediaTime() - tStart) * 1000.0
        let totalCount = allRecords.count
        let passCount = allRecords.filter { if case .pass = $0.result { return true } else { return false } }.count
        let failCount = totalCount - passCount

        print("\n========================================================")
        print("                    FINAL RESULTS                       ")
        print("========================================================")
        print(String(format: "Total Tests Executed: %d", totalCount))
        print(String(format: "Passed:               %d", passCount))
        print(String(format: "Failed:               %d", failCount))
        print(String(format: "Execution Time:       %.2f ms", totalElapsed))

        if failCount > 0 {
            print("\n❌ FAILED TESTS:")
            for record in allRecords {
                if case .fail(let msg) = record.result {
                    print("  [Tier \(record.tier)] [\(record.feature)] \(record.name): \(msg)")
                }
            }
            print("\nExit Code: 1 (FAILED)")
            exit(1)
        } else {
            print("\n✅ ALL TESTS PASSED SUCCESSFULLY! (100% Pass Rate)")
            print("Exit Code: 0 (SUCCESS)\n")
            exit(0)
        }
    }

    private static func printSummary(for records: [TestCaseRecord], tierName: String) {
        let total = records.count
        let passed = records.filter { if case .pass = $0.result { return true } else { return false } }.count
        let failed = total - passed
        let symbol = failed == 0 ? "✅" : "❌"
        print(String(format: "  %@ %@: %d/%d passed (%d failed)", symbol, tierName, passed, total, failed))
        for r in records {
            let statusStr: String
            switch r.result {
            case .pass:
                statusStr = "PASS"
            case .fail(let err):
                statusStr = "FAIL (\(err))"
            }
            print(String(format: "    - [%@] %-45@ (%.2f ms)", statusStr, r.name, r.durationMs))
        }
    }
}
